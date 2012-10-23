require 'sinatra'

require 'rubygems'
require 'json'
require 'net/http'

require 'twilio-ruby'

def current_weather(zip_code, raw = false)
  base_url = "http://api.wunderground.com/api/" + ENV['WU_KEY'] + "/conditions/q/"
  url = base_url + zip_code + ".json"

  resp = Net::HTTP.get_response(URI.parse(url))
  data = resp.body

  # we convert the returned JSON data to native Ruby
  # data structure - a hash
  result = JSON.parse(data)

  weather = Hash.new

  # if the hash has 'Error' as a key, we raise an error
  if result.has_key? 'Error'
     raise "web service error"
  end


  if(result.has_key? 'current_observation')
    weather['feels_like'] = result['current_observation']['feelslike_f'] + " degrees"
    weather['city'] = result['current_observation']['display_location']['city'] 
    weather['state'] = result['current_observation']['display_location']['state_name']
    weather['weather'] = result['current_observation']['weather']
    weather['weather'] = result['current_observation']['weather']
    weather['time'] = result['current_observation']['observation_time']
  end

  if(raw)
    return result
  else
    return weather
  end
end

def insert_response(data)
  response = Twilio::TwiML::Response.new do |r|
    r.Say data, :voice => 'woman'
  end

  return response.text
end

def insert_response_with_redirect(data, redirect_uri)
  response = Twilio::TwiML::Response.new do |r|
    r.Say data, :voice => 'woman'
    #r.Redirect 'http://twimlets.com/menu?Message=Choose%20your%20option%2C%201%20for%20time%2C%202%20for%20temp&amp;Options%5B1%5D=http%3A%2F%2Fancient-springs-2061.herokuapp.com%2Ftime&amp;Options%5B2%5D=http%3A%2F%2Fancient-springs-2061.herokuapp.com%2Ftemp'
    r.Redirect redirect_uri
  end

  return response.text
end

get '/' do
  insert_response("The current time is " + Time.new.inspect)
end

get '/time' do
  insert_response("The current time is " + Time.new.inspect)
end

get '/temp' do
  weather = current_weather("55102")

  response = Twilio::TwiML::Response.new do |r|
    r.Say "In " + weather['city'] + " it is " + weather['weather'] + " and it feels like "  + weather['feels_like'] + ", this was " + weather['time'], :voice => 'woman'
  end

  return response.text
end

post '/inbound_call' do
  if(params['Digits'] && params['Digits'].size == 5)
    weather = current_weather(params['Digits'])
  elsif(params['FromZip'] && params['FromZip'].size == 5)
    weather = current_weather(params['FromZip'])
  end

  response = Twilio::TwiML::Response.new do |r|
    if(weather && weather['city'])
      r.Say "In " + weather['city'] + ", " + weather['state'] + " it is " + weather['weather'] + " and feels like "  + weather['feels_like'] + ", this observation was " + weather['time'], :voice => 'woman'
    else
      r.Say "Invalid Zip Code, try the Internets, Noob", :voice => 'woman'
    end

    r.Gather :numDigits => '5', :method => 'post' do |g|
      g.Say 'For weather in another zip code enter it now', :voice => 'woman'
    end

  end

  return response.text
end

post '/inbound_sms' do

puts "Params: " + params.inspect + "\n"

  if(params['Body'] && params['Body'].size == 5)
    weather = current_weather(request.body.read)
  elsif(params['FromZip'] && params['FromZip'].size == 5)
    weather = current_weather(params['FromZip'])
  end

  response = Twilio::TwiML::Response.new do |r|
    if(weather && weather['city'])
      r.Sms "In " + weather['city'] + ", " + weather['state'] + " it is " + weather['weather'] + " and feels like "  + weather['feels_like'] + ", this observation was " + weather['time']
    else
      r.Sms "Text a valid zip code for current weather conditions"
    end
  end

  response.text 
end

get '/weather_raw' do
  return current_weather('55102', true)
end

post '/request_raw' do
  puts request
  return request
end
