require 'rubygems'
require 'sinatra'
require 'yaml'
require 'exceptions'
require 'validations'
require 'bosh_methods'
require 'form_generator'



#require "yaml"
require "config"
require "date"
require "json"
#require "sinatra"
require "uri"
require "erb"
require "sinatra/vcap"
require "net/http"
require "cli"
require "weakref"
require "uuidtools"
require "monit_api"
require "fileutils"
require "sequel"

require "ucc/core_ext"
require "ucc/file_with_progress_bar_web"
require "ucc/stage_progressbar"
require "ucc/commander_bosh_runner"
require "ucc/infrastructure"
require "ucc/monit"
require "ucc/deployment"
require "ucc/step_deployment"
require "ucc/event_log_renderer_web"
require "ucc/user"

autoload :HTTPClient, "httpclient"

module Uhuru::BoshCommander

  class LoginScreen < Sinatra::Base

    register Sinatra::VCAP
    use Rack::Session::Pool
    use Rack::Logger
    set :root, File.expand_path("../../", __FILE__)
    set :views, File.expand_path("../../views", __FILE__)
    set :public_folder, File.expand_path("../../public", __FILE__)
    #enable :sessions

    get '/login' do
      erb :login, {
          :locals => {
              :error_message => ""
          },
          :layout => :login}
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
        command.login(params[:username], params[:password])
      end

      return command, config, cache
    end

    post '/login' do
      message = ""
      #Uhuru::CommanderBoshRunner.execute(session) do
        session['user_name'] = params[:username]
        command, config, cache = login

        if (command.logged_in?)
          message = "logged in as `#{params[:username]}'"

          stemcell_cmd = Bosh::Cli::Command::Stemcell.new
          stemcell_cmd.instance_variable_set("@config", command.instance_variable_get("@config"))

          session['command_stemcell'] = stemcell_cmd
          redirect '/'
        else
          message = "cannot log in as `#{params[:username]}'"
          erb :login,
              {
                  :locals =>
                      {
                          :error_message => message
                      },
                  :layout => :login
              }
        end
      #end
    end
  end

  class BoshCommander < Sinatra::Base

    set :root, File.expand_path("../../", __FILE__)
    set :views, File.expand_path("../../views", __FILE__)
    set :public_folder, File.expand_path("../../public", __FILE__)
    set :raise_errors, Proc.new { false }
    set :show_exceptions, false
    register Sinatra::VCAP
    use Rack::Logger
    use LoginScreen

    before do
      unless session['user_name']
        redirect '/login'
      end
    end

    def cloud_js_tabs
      {
          :networks => "Network",
          :resource_pools => "Resource Pools",
          :components => "Components",
          :product_keys => "Product Keys",
          :properties => "Properties",
          :user_limits => "User Limits"
      }
    end

    def initialize()
      super()
    end

    error 404 do
      ex = "The page was not found, please try again later!"
      erb :error404, {:locals => {:ex => ex}, :layout => :layout_error}
    end

    error do
      exception = "#{request.env['sinatra.error'].to_s}"
      error = Exceptions.errors(exception)
      erb :error404, {:locals => {:ex => error}, :layout => :layout_error}
    end

    def logger
      request.logger
    end

    helpers do
      def first_run?
        !File.exists?($config[:infrastructure_yml])
      end

      def check_first_run!
        redirect '/infrastructure' if first_run?
      end

      def forms_yml
        File.expand_path('../../config/forms.yml', __FILE__)
      end
    end

    get '/' do
      redirect '/infrastructure'
    end

    get '/infrastructure' do
      form_generator = nil
      director_yml = File.join($config[:bosh][:base_dir], 'jobs','micro_vsphere','director','config','director.yml.erb')
      if first_run?
        form_generator = FormGenerator.new(director_yml, forms_yml, director_yml)
      else
        infrastructure_yml = $config[:infrastructure_yml]
        form_generator = FormGenerator.new(infrastructure_yml, forms_yml, director_yml)
      end

      tables = { :cpi => "CPI" }

      form_data = {}

      erb :infrastructure, {:locals =>
                                {
                                    :form_generator => form_generator,
                                    :form => "infrastructure",
                                    :table => tables,
                                    :form_data => {}
                                },
                            :layout => :layout}
    end

    post '/infrastructure' do

      director_yml = File.join($config[:bosh][:base_dir], 'jobs','micro_vsphere','director','config','director.yml.erb')
      infrastructure_yml = $config[:infrastructure_yml]
      tables = { :cpi => "CPI" }                                          # a hash for each table in this page

      puts params.inspect

      if params.has_key?("btn_save")
        params.delete("btn_save")

        if first_run?
          FileUtils.copy_file(director_yml, infrastructure_yml)
        end
        form_generator = FormGenerator.new(infrastructure_yml, forms_yml, director_yml)

        table_errors = form_generator.get_errors(params, "infrastructure", tables)

        if table_errors.select{|key, value| value==true }.size == 0
          form_generator.save_local_deployment("infrastructure", params)
        end

        erb :infrastructure, {:locals =>
                                  {
                                      :form_generator => form_generator,
                                      :form => "infrastructure",
                                      :table => tables,
                                      :form_data => params
                                  },
                              :layout => :layout}

      elsif params.has_key?("btn_test")
        params.delete("btn_test")
        form_generator.generate_form("infrastructure", tables[:cpi], params)

      elsif params.has_key?("btn_update")
        params.delete("btn_update")
        if first_run?
          FileUtils.copy_file(director_yml, infrastructure_yml)
        end
        form_generator = FormGenerator.new(infrastructure_yml, forms_yml)

        table_errors = form_generator.get_errors(params, "infrastructure", tables)

        if table_errors.select{|key, value| value==true }.size == 0
          form_generator.save_local_deployment("infrastructure", params)

          request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
            begin
              infrastructure = Uhuru::Ucc::Infrastructure.new
              infrastructure.setup(infrastructure_yml)
            rescue Exception => e
              err e.message.to_s
              $stdout.puts(e)
              $stdout.puts(e.backtrace)
            end

          end
          redirect "logs/#{request_id}"

        else
          erb :infrastructure, {:locals =>
                                    {
                                        :form_generator => form_generator,
                                        :form => "infrastructure",
                                        :table => tables,
                                        :form_data => params
                                    },
                                :layout => :layout}
        end



      end

    end

    get '/clouds/configure/:cloud_name' do
      check_first_run!

      cloud_name = params[:cloud_name]
      cloud_config = File.join($config[:cf_deployments_dir],"local","#{cloud_name}.yml")
      cloud_config_live = File.join($config[:cf_deployments_dir],cloud_name,"#{cloud_name}.yml")

      form_generator = FormGenerator.new(cloud_config, forms_yml, cloud_config_live)

      form_data = {}
      table_errors = form_generator.get_errors(form_data, "cloud", cloud_js_tabs)

      erb :cloud_configuration, {:locals =>
                                     {
                                         :form_generator => form_generator,
                                         :form => "cloud",
                                         :js_tabs => cloud_js_tabs,
                                         :default_tab => :networks,
                                         :error => nil,
                                         :table_errors => table_errors,
                                         :form_data => {},
                                         :cloud_name => cloud_name
                                     },
                                 :layout => :layout}
    end

    post '/clouds/configure/:cloud_name' do
      check_first_run!

      cloud_name = params[:cloud_name]
      cloud_config = File.join($config[:cf_deployments_dir],"local","#{cloud_name}.yml")
      cloud_config_live = File.join($config[:cf_deployments_dir],cloud_name,"#{cloud_name}.yml")

      if params.has_key?("btn_save")
        params.delete("btn_save")

        form_generator = FormGenerator.new(cloud_config, forms_yml)
        table_errors = form_generator.get_errors(params, "cloud", cloud_js_tabs)

        if table_errors.select{|key, value| value==true }.size == 0
          form_generator.save_local_deployment("cloud", params)
        end

        form_generator = FormGenerator.new(cloud_config, forms_yml, cloud_config_live)
        erb :cloud_configuration, {:locals =>
                                      {
                                          :form_generator => form_generator,
                                          :form => "cloud",
                                          :js_tabs => cloud_js_tabs,
                                          :default_tab => :networks,
                                          :error => nil,
                                          :table_errors => table_errors,
                                          :form_data => params,
                                          :cloud_name => cloud_name
                                      },
                                  :layout => :layout}

      elsif params.has_key?("btn_save_and_deploy")
        params.delete("btn_save_and_deploy")

        form_generator = FormGenerator.new(cloud_config, forms_yml)
        table_errors = form_generator.get_errors(params, "cloud", cloud_js_tabs)

        if table_errors.select{|key, value| value==true }.size == 0
          form_generator.save_local_deployment("cloud", params)

          request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
            begin
              yaml = load_yaml_file(cloud_config)
              deployment = Uhuru::Ucc::Deployment.new(cloud_name)
              deployment.save(yaml)
              deployment.deploy
            rescue Exception => e
              err e.message.to_s
              $stdout.puts(e)
              $stdout.puts(e.backtrace)
            end
          end
          redirect "logs/#{request_id}"
        else
          form_generator = FormGenerator.new(cloud_config, forms_yml, cloud_config_live)
          erb :cloud_configuration, {:locals =>
                                         {
                                             :form_generator => form_generator,
                                             :form => "cloud",
                                             :js_tabs => cloud_js_tabs,
                                             :default_tab => :networks,
                                             :error => nil,
                                             :table_errors => table_errors,
                                             :form_data => params,
                                             :cloud_name => cloud_name
                                         },
                                     :layout => :layout}
        end

      elsif params.has_key?("btn_tear_down")
        params.delete("btn_tear_down")
        request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
          begin
            deployment = Uhuru::Ucc::Deployment.new(cloud_name)
            deployment.tear_down
          rescue Exception => e
            err e.message.to_s
            $stdout.puts(e)
            $stdout.puts(e.backtrace)
          end
        end
        redirect "logs/#{request_id}"

      elsif params.has_key?("btn_delete")
        params.delete("btn_delete")
        request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
          begin
            deployment = Uhuru::Ucc::Deployment.new(cloud_name)
            deployment.delete
          rescue Exception => e
            err e.message.to_s
            $stdout.puts(e)
            $stdout.puts(e.backtrace)
          end
        end
        redirect "logs/#{request_id}"

      elsif params.has_key?("btn_export")
        params.delete("btn_export")

        content_type 'application/octet-stream'
        File.read(cloud_config)

      elsif params.has_key?("btn_import")
        params.delete("btn_import")
      end

    end

    get '/clouds' do
      check_first_run!
      erb :clouds, {:locals =>
                        {
                            :clouds => FormGenerator.get_clouds
                        },
                    :layout => :layout}
    end

    get '/tasks' do
      check_first_run!
      erb :tasks, {:layout => :layout}
    end

    post '/clouds' do
      check_first_run!
      if params["create_cloud_name"] != ''
        FileUtils.copy_file(File.expand_path("../../config/blank.yml", __FILE__), File.join($config[:cf_deployments_dir], "local", "#{params["create_cloud_name"]}.yml") )
      end

      erb :clouds, {:locals =>
                        {
                            :clouds => FormGenerator.get_clouds
                        },
                    :layout => :layout}
    end

    get '/logout' do
      Uhuru::CommanderBoshRunner.execute(session) do
        session['user_name'] = nil
        session['command'].logout
      end
      redirect '/'
    end

    get '/logs/:stream_id' do
      screen_id = UUIDTools::UUID.random_create.to_s
      Uhuru::CommanderBoshRunner.status_streamer(session).create_screen(params[:stream_id], screen_id)

      erb :logs,
          {
              :locals =>
                  {
                      :screen_id => screen_id
                  },
              :layout => :layout
          }
    end

    get '/screen/:screen_id' do
      Uhuru::CommanderBoshRunner.status_streamer(session).read_screen(params[:screen_id])
    end


  end

end
