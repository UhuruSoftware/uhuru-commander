require 'yaml'
require 'config'
require 'date'
require 'json'
require 'sinatra'
require 'uri'
require 'erb'
require "sinatra/vcap"
require "ucc/director"


module Uhuru::Ucc
  class Ucc < Sinatra::Base
    set :root, File.expand_path("../../", __FILE__)
    set :views, File.expand_path("../../views", __FILE__)
    set :public_folder, File.expand_path("../../public", __FILE__)
    register Sinatra::VCAP
    use Rack::Logger


    def logger
      request.logger
    end

    def initialize()
      super()
    end

    get '/' do
      erb :index, {:locals => {:page_title => "Home"}, :layout => :layout}
    end

    get '/login' do
      erb :login, {:locals => {:page_title => "Login", :message_large => "ssss"}}
    end

    post '/login' do
      message = params[:username]
      director = Uhuru::Ucc::Director.new($config[:bosh][:target], params[:username], params[:pass]);



      erb :login,
          {
              :locals =>
                  {
                      :page_title => "login",
                      :message_large => message
                  }
          }
    end
    end


    def message_page(title, message)

  end
end