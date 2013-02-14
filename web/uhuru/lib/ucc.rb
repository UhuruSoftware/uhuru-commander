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
require "monit_api"
require 'fileutils'
require "ucc/core_ext"
require "ucc/file_with_progress_bar_web"
require "ucc/stage_progressbar"
require "ucc/commander_bosh_runner"
require "ucc/infrastructure"
require "ucc/monit"
require "ucc/deployment"
require "ucc/step_deployment"
require "ucc/event_log_renderer_web"

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
        session['command_uuid'] = UUIDTools::UUID.random_create
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
      Uhuru::CommanderBoshRunner.execute(session) do
        Bosh::Cli::Config.cache = Bosh::Cli::Cache.new(cache)

        command.set_target($config[:bosh][:target])
        command.login(params[:username], params[:pass])
      end

      return command, config, cache
    end



    post '/login' do
      message = ""
      Uhuru::CommanderBoshRunner.execute(session) do
        session['user_name'] = params[:username]
        command, config, cache = login

        if (command.logged_in?)
          message = "logged in as `#{params[:username]}'"

          stemcell_cmd = Bosh::Cli::Command::Stemcell.new
          stemcell_cmd.instance_variable_set("@config", command.instance_variable_get("@config"))

          session['command_stemcell'] = stemcell_cmd
        else
          message = "cannot log in as `#{params[:username]}'"
        end

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

    get '/logs/:stream_id' do
      screen_id = UUIDTools::UUID.random_create.to_s
      Uhuru::CommanderBoshRunner.status_streamer(session).create_screen(params[:stream_id], screen_id)

      erb :logs,
          {
              :locals =>
                  {
                      :screen_id => screen_id
                  }
          }
    end

    get '/screen/:screen_id' do
      Uhuru::CommanderBoshRunner.status_streamer(session).read_screen(params[:screen_id])

    end


    post '/uploadstemcell' do
      request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
        command_stemcell =  session['command_stemcell']
        say "Uploading Linux stemcell"
        command_stemcell.upload('../resources/bosh-stemcell-vsphere-0.6.4.tgz')
        say "Uploading Linux PHP stemcell"
        command_stemcell.upload('../resources/bosh-stemcell-php-vsphere-0.6.4.3.tgz')

      end
      redirect "logs/#{request_id}"
    end

    post '/setup_infrastructure' do
      request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
        begin
          infrastructure = Infrastructure.new
          infrastructure.setup('/home/mitza/testing/assets/director_config/director.yml.erb')
        rescue Exception => e
          err e.message.to_s
          $stdout.puts(e)
          $stdout.puts(e.backtrace)
        end

      end
      redirect "logs/#{request_id}"
    end

    post '/deploy' do
      request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
        begin
          yaml = load_yaml_file('/home/mitza/bosh/deployments/cloudfoundry.yml')
          deployment = Uhuru::Ucc::Deployment.new("cloud-foundry")
          deployment.save(yaml)
          deployment.deploy
        rescue Exception => e
          err e.message.to_s
          $stdout.puts(e)
          $stdout.puts(e.backtrace)
        end
      end
      redirect "logs/#{request_id}"
    end

    post '/deletedep'do
      request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
        begin
          deployment = Uhuru::Ucc::Deployment.new("cloud-foundry")
          deployment.delete
        rescue Exception => e
          err e.message.to_s
          $stdout.puts(e)
          $stdout.puts(e.backtrace)
        end
      end

      redirect "logs/#{request_id}"
    end

  end
end