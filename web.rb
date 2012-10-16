require 'sinatra'

require 'rubygems'
require 'json'
require 'net/http'

def current_temp()

   base_url = "http://api.wunderground.com/api/" + ENV['WU_KEY'] + "/conditions/q/"
   url = base_url + "CA/San_Francisco.json"

   resp = Net::HTTP.get_response(URI.parse(url))
   data = resp.body

   # we convert the returned JSON data to native Ruby
   # data structure - a hash
   result = JSON.parse(data)

   # if the hash has 'Error' as a key, we raise an error
   if result.has_key? 'Error'
      raise "web service error"
   end

   feels_like = result['current_observation']['feelslike_string']

   return feels_like

end

def redirect_to_menu()
  "<Redirect>http://twimlets.com/menu?Message=Choose%20your%20option%2C%201%20for%20time%2C%202%20for%20temp&Options%5B1%5D=http%3A%2F%2Fdry-shore-9675.herokuapp.com%2Ftime&Options%5B2%5D=http%3A%2F%2Fdry-shore-9675.herokuapp.com%2Ftemp&</Redirect>"
end

def insert_response(data)
  "<Response><Say>Hello Twilio Caller, " + data + "</Say>" + redirect_to_menu() + "</Response>"
end

get '/' do
  insert_response(Time.new.inspect)
end

get '/time' do
  insert_response("the current time is " + Time.new.inspect)
end

get '/temp' do
  insert_response("the current temperature is " + current_temp())
end
