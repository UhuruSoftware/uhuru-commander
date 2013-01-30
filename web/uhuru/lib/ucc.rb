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
require "weakref"
require "uuidtools"
require "ucc/core_ext"
require "ucc/file_with_progress_bar_web"
require "ucc/stage_progressbar"

autoload :HTTPClient, "httpclient"


module Uhuru::Ucc

  #class Ucc < Sinatra::Base
  class LoginScreen < Sinatra::Base

    register Sinatra::VCAP
    use Rack::Session::Pool
    use Rack::Logger
    set :root, File.expand_path("../../", __FILE__)
    set :views, File.expand_path("../../views", __FILE__)
    set :public_folder, File.expand_path("../../public", __FILE__)
    #enable :sessions

    get '/login' do
      erb :login, {:locals => {:page_title => "Login", :message_large => ""}}
    end


    def login

      if session['streamer'] == nil
        session['streamer'] = StatusStreamer.new
        session['command_uuid'] = UUIDTools::UUID.random_create
        session['streamer'].create_stream(session['command_uuid'])
      end

      command =  Bosh::Cli::Command::Misc.new

      session['command'] = command

      #we do not care about local user
      tmpdir = Dir.mktmpdir
      puts tmpdir
      config = File.join(tmpdir, "bosh_config")
      cache = File.join(tmpdir, "bosh_cache")

      command.add_option(:config, config)
      command.add_option(:cache_dir, cache)
      command.add_option(:non_interactive, true)
      command.add_option(:command_uuid, session['command_uuid'])
      command.add_option(:streamer,  session['streamer'])

      Bosh::Cli::Config.cache = Bosh::Cli::Cache.new(@cache)
      command.set_target($config[:bosh][:target])
      command.login(params[:username], params[:pass])

      return command, config, cache
    end



    post '/login' do

      session['user_name'] = params[:username]
      command, config, cache = login

      if (command.logged_in?)
        message = "logged in as `#{params[:username]}'"

        stemcell_cmd = Bosh::Cli::Command::Stemcell.new
        stemcell_cmd.add_option(:config, config)
        stemcell_cmd.add_option(:cache_dir, cache)
        stemcell_cmd.add_option(:non_interactive, true)
        stemcell_cmd.add_option(:command_uuid, session['command_uuid'])
        stemcell_cmd.add_option(:streamer,  session['streamer'])

        session['command_stemcell'] = stemcell_cmd
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

    #enable :sessions

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
      uuid = UUIDTools::UUID.random_create
      session['streamer'].create_screen("#{uuid}",session['command_uuid'])
      stream(:keep_open) do |out|
        while true
          contents = session['streamer'].read_screen("#{uuid}")
          out << "#{contents}\n"
        end
      end
    end

    post '/uploadstemcell' do
      Mytrend.new do
        begin
        Thread.current.command_id = session['command_uuid']
        Thread.current.streamer = session['streamer']
        command_stemcell =  session['command_stemcell']
        command_stemcell.upload('/home/mitza/old_serv/mitza/stemcells/bosh-stemcell-vsphere-0.6.4.tgz')

        rescue Exception => e
         $stdout.puts "#{e.to_s}"
        end
      end
      "uploading stemcell"
    end

    get '/sloboz' do
      if (session[:slobo] == nil)
        session[:slobo] = 'asd'
      else
        session[:slobo] = session[:slobo] + 'asd'
      end
      session[:slobo]

    end

  end

  class Mytrend < Thread
    attr_accessor :command_id
    attr_accessor :streamer
  end

end