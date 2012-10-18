require 'sinatra'

require 'rubygems'
require 'json'
require 'net/http'

require 'twilio-ruby'

def current_weather(zip_code, raw)
  base_url = "http://api.wunderground.com/api/" + ENV['WU_KEY'] + "/conditions/q/"
  url = base_url + zip_code + ".json"

  resp = Net::HTTP.get_response(URI.parse(url))
  data = resp.body

  # we convert the returned JSON data to native Ruby
  # data structure - a hash
  result = JSON.parse(data)

  # if the hash has 'Error' as a key, we raise an error
  if result.has_key? 'Error'
     raise "web service error"
  end
 
  weather = Hash.new

  weather['feels_like'] = result['current_observation']['feelslike_string']
  weather['city'] = result['current_observation']['display_location']['city'] 
  weather['state'] = result['current_observation']['display_location']['state_name']

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
  weather = current_weather("94110")

  response = Twilio::TwiML::Response.new do |r|
    r.Say "current temp in " + weather['city'] + " feels like "  + weather['feels_like'], :voice => 'woman'
  end

  return response.text
end

post '/inbound_call' do
  if(params['Digits'])
    weather = current_weather(params['Digits'])
  else
    weather = current_weather(params['FromZip'])
  end

  response = Twilio::TwiML::Response.new do |r|
    r.Say "current temp in " + weather['city'] + " " + weather['state'] + " feels like "  + weather['feels_like'], :voice => 'woman'

    r.Gather :numDigits => '5', :method => 'post' do |g|
      g.Say 'For weather in another zip code enter it now', :voice => 'woman'
    end

  end

  return response.text
end

get '/weather_raw' do
  return current_weather('94110')
end
