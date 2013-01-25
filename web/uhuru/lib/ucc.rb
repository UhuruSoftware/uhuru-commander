require 'yaml'
require 'config'
require 'date'
require 'json'
require 'sinatra'
require 'uri'
require 'erb'
require "sinatra/vcap"
require 'net/http'
require "cli"

require "ucc/core_ext"
require "ucc/file_with_progress_bar_web"

autoload :HTTPClient, "httpclient"


module Uhuru::Ucc

  class LoginScreen < Sinatra::Base
    enable :sessions
    set :root, File.expand_path("../../", __FILE__)
    set :views, File.expand_path("../../views", __FILE__)
    set :public_folder, File.expand_path("../../public", __FILE__)

    get '/login' do
      erb :login, {:locals => {:page_title => "Login", :message_large => ""}}
    end


    def login

      command =  Bosh::Cli::Command::Misc.new

      #we do not care about local user
      tmpdir = Dir.mktmpdir
      puts tmpdir
      @config = File.join(tmpdir, "bosh_config")
      @cache = File.join(tmpdir, "bosh_cache")
      command.add_option(:config, @config)
      command.add_option(:cache_dir, @cache)
      command.add_option(:non_interactive, true)

      Bosh::Cli::Config.cache = Bosh::Cli::Cache.new(@cache)


      command.set_target($config[:bosh][:target])
      command.login(params[:username], params[:pass])


      command
    end



    post '/login' do

      command = login

      if (command.logged_in?)
        message = "logged in as `#{params[:username]}'"
        session['command'] = command
        session['user_name'] = params[:username]
        session['command_stemcell'] = Bosh::Cli::Command::Stemcell.new

      else
        message = "cannot log in as `#{params[:username]}'"
      end


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


  class Ucc < Sinatra::Base

    set :root, File.expand_path("../../", __FILE__)
    set :views, File.expand_path("../../views", __FILE__)
    set :public_folder, File.expand_path("../../public", __FILE__)
    register Sinatra::VCAP
    use Rack::Logger
    use LoginScreen

    enable :sessions

    before do
      unless session['user_name']
        halt "Access denied, please <a href='/login'>login</a>."
      end
    end


    def logger
      request.logger
    end

    def initialize()
      super()
    end

    get('/') { "Hello #{session['user_name']}." }
    #get '/' do
    #  erb :login, {:locals => {:page_title => "Home"}, :layout => :layout}
    #end



    get '/test' do
      "good"
    end

    get '/lo' do
      puts "lout"
      session['user_name'] = nil
      session['command'].logout
      "logging out"
    end

    get '/status' do
      command = session['command']
      command.status
    end

    get '/evented' do
      stream(:keep_open) do |out|
        EventMachine::PeriodicTimer.new(1) {
          contents = File.read('/tmp/some_file')
          out << "#{contents}\n"
        }
      end
    end

    post '/uploadstemcell' do
      Thread.new do
        command_stemcell =  session['command_stemcell']
        command_stemcell.upload('/home/mitza/stemcells/bosh-stemcell-vsphere-0.6.4.tgz')
      end
      "uploading stemcell"
    end

  end


    def message_page(title, message)

  end
end