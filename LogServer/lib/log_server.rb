require 'sinatra/base'
require 'pathname'

class LogServer < Sinatra::Base
  get '/log' do
    "Hello, world"
  end
  
  post '/log' do
    if params[:udid]
      log_dir = Pathname.new(File.expand_path('log', File.dirname(__FILE__)))
      filename = "#{Time.now.strftime("%F-%H%M%S")}-#{params[:udid]}.log"
      
      File.open(log_dir + filename, 'w') do |f|
        f.puts params[:body]
      end
    end
  end
end
