require 'rubygems'
require 'sinatra'
require 'yaml'
require 'exceptions'
require 'validations'
require 'bosh_methods'
require 'form_generator'
require 'cgi'


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
#require "ucc/file_with_progress_bar_web"
#require "ucc/stage_progressbar"
require "ucc/commander_bosh_runner"
require "ucc/infrastructure"
require "ucc/monit"
require "ucc/deployment"
require "ucc/step_deployment"
require "ucc/event_log_renderer_web"
require "ucc/user"
require "ucc/vms"
require "ucc/task"
#require "ucc/task_log_renderer_web"

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
      if $config[:bosh_commander][:skip_check_monit] == false
        monit = Uhuru::Ucc::Monit.new
        unless monit.service_group_state == "running"
          redirect '/offline'
        end
      end

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
      unless request.path_info == '/offline' || request.path_info == '/monit_status' || request.path_info == '/ssh_config'
        unless session['user_name']
          redirect '/login'
        end
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
      ex = "Sorry, page not found."
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
        !File.exists?(File.expand_path('../../config/infrastructure.yml', __FILE__))
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

    get '/offline' do
      erb :monit_offline, {:layout => :monit_offline}
    end

    get '/monit_status' do
      monit = Uhuru::Ucc::Monit.new
      state = monit.service_group_state
      state
    end

    get '/infrastructure' do
      form_generator = FormGenerator.new(is_infrastructure: true)
      tables = { :cpi => "CPI" }
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

      tables = { :cpi => "CPI" }                                          # a hash for each table in this page

      if params.has_key?("btn_update")
        params.delete("btn_update")

        infrastructure_yml = File.expand_path("../../config/infrastructure.yml", __FILE__)
        form_generator = FormGenerator.new(is_infrastructure: true)

        table_errors = form_generator.get_errors(params, "infrastructure", tables)

        if table_errors.select{|key, value| value==true }.size == 0
          form_generator.save_local_deployment("infrastructure", params)

          request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
            begin
              infrastructure = Uhuru::Ucc::Infrastructure.new
              infrastructure.setup(infrastructure_yml)
            rescue Exception => e
              err e.message.to_s
              logger.err("#{e.to_s}: #{e.backtrace}")
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
      elsif params.has_key?("btn_test")
        params.delete("btn_test")
        form_generator = FormGenerator.new(is_infrastructure: true)
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



    get '/clouds/configure/:cloud_name' do
      check_first_run!

      cloud_name = params[:cloud_name]
      form_data = {}
      deployment_status = {}
      form_generator = nil
      table_errors = {}
      Uhuru::CommanderBoshRunner.execute(session) do
        begin
          form_generator = FormGenerator.new(deployment_name: cloud_name)
          deployment_status = form_generator.deployment_obj.status
        rescue Exception => ex
          logger.err("#{ex.to_s}: #{ex.backtrace}")
        end
      end

      erb :cloud_configuration, {:locals =>
                                     {
                                         :form_generator => form_generator,
                                         :form => "cloud",
                                         :js_tabs => cloud_js_tabs,
                                         :default_tab => :networks,
                                         :error => nil,
                                         :form_data => {},
                                         :cloud_name => cloud_name,
                                         :help => form_generator.help,
                                         :summary => deployment_status
                                     },
                                 :layout => :layout}
    end

    get '/clouds/configure/:cloud_name/vms' do
      vms_list = {}

      cloud_name = params[:cloud_name]
      form_generator = FormGenerator.new(deployment_name: cloud_name)

      Uhuru::CommanderBoshRunner.execute(session) do
        begin

          if form_generator.deployment_obj.get_status()["state"] == "Deployed"
            vms = Uhuru::Ucc::Vms.new()
            vms_list = vms.list(cloud_name)
          end
        rescue Exception => ex
          logger.err("#{ex.to_s}: #{ex.backtrace}")
        end
      end

      vms_list.to_json
    end


    post '/clouds/configure/:cloud_name' do
      check_first_run!

      cloud_name = params[:cloud_name]
      table_errors = nil
      form_generator = nil
      vms_list = {}
      deployment_status = {}
      if params.has_key?("btn_save")
        params.delete("btn_save")
        Uhuru::CommanderBoshRunner.execute(session) do
          begin
            form_generator = FormGenerator.new(deployment_name: cloud_name)
            table_errors = form_generator.get_errors(params, "cloud", cloud_js_tabs)
            if table_errors.select{|key, value| value==true }.size == 0
              form_generator.save_local_deployment("cloud", params)
            end
            #vms = Uhuru::Ucc::Vms.new()
            #vms_list = vms.list(cloud_name)
            deployment_status = form_generator.deployment_obj.status
          rescue Exception => ex
            logger.err("#{ex.to_s}: #{ex.backtrace}")
          end
        end
        #redirect "/clouds/configure/#{cloud_name}"
        erb :cloud_configuration, {:locals =>
                                       {
                                           :form_generator => form_generator,
                                           :form => "cloud",
                                           :js_tabs => cloud_js_tabs,
                                           :default_tab => :networks,
                                           :error => nil,
                                           :form_data => params,
                                           :cloud_name => cloud_name,
                                           :vms => vms_list,
                                           :summary => deployment_status
                                       },
                                   :layout => :layout}

      elsif params.has_key?("btn_save_and_deploy")
        params.delete("btn_save_and_deploy")

        request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
          begin
            form_generator = FormGenerator.new(deployment_name: cloud_name)
            table_errors = form_generator.get_errors(params, "cloud", cloud_js_tabs)
            if table_errors.select{|key, value| value==true }.size == 0
              form_generator.save_local_deployment("cloud", params)
              if form_generator.deployment_obj.get_status["state"] == "Deployed"
                #form_generator.deployment_obj.update
                form_generator.deployment_obj.deploy
              else
                form_generator.deployment_obj.deploy
              end
            end
          rescue Exception => e
            err e.message.to_s
            logger.err("#{e.to_s}: #{e.backtrace}")
          end
        end
        redirect "logs/#{request_id}"

        begin
          Uhuru::CommanderBoshRunner.execute(session) do
            vms = Uhuru::Ucc::Vms.new()
            vms_list = vms.list(cloud_name)
          end
        rescue Exception => ex
          logger.err(ex.to_s)
        end

        erb :cloud_configuration, {:locals =>
                                       {
                                           :form_generator => form_generator,
                                           :form => "cloud",
                                           :js_tabs => cloud_js_tabs,
                                           :default_tab => :networks,
                                           :error => nil,
                                           :form_data => params,
                                           :cloud_name => cloud_name,
                                           :vms => vms_list,
                                           :summary => deployment_status
                                       },
                                   :layout => :layout}

      elsif params.has_key?("btn_tear_down")
        params.delete("btn_tear_down")
        request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
          begin
            deployment = Uhuru::Ucc::Deployment.new(cloud_name)
            deployment.tear_down
          rescue Exception => e
            err e.message.to_s
            logger.err("#{e.to_s}: #{e.backtrace}")
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
            logger.err("#{e.to_s}: #{e.backtrace}")
          end
        end
        redirect "logs/#{request_id}"

      elsif params.has_key?("btn_export")
        params.delete("btn_export")

        send_file File.expand_path("../../cf_deployments/#{cloud_name}/#{cloud_name}.yml", __FILE__), :filename => "#{cloud_name}.yml", :type => 'Application/octet-stream'

      elsif params.has_key?("file_input")
        tempfile = params['file_input'][:tempfile]

        manifest = File.open(tempfile.path) { |file| YAML.load(file)}
        File.open(File.expand_path("../../cf_deployments/#{cloud_name}/#{cloud_name}.yml", __FILE__), 'w') do |out|
          YAML.dump(manifest, out)
        end

        redirect "/clouds/configure/#{cloud_name}"

      end

    end

    get '/clouds' do
      check_first_run!
      clouds = {}
      Uhuru::CommanderBoshRunner.execute(session) do
        clouds = FormGenerator.get_clouds
      end

      clouds_help = <<CLOUDS
Here you have a list of all clouds.
Click on the name of any one of them for configuration, monitoring and deployment options.
The status of a cloud can have one of the following values:<br>
<i>'Not Saved'</i> - the cloud has not been configured yet<br>
<i>'Saved'</i> - the cloud has been configured<br>
<i>'Deploying'</i> - the cloud is being deployed right now<br>
<i>'Deployed'</i> - the cloud has been deployed and can be used<br>
<i>'Error'</i> - there was an error while deploying the cloud<br>
CLOUDS

      erb :clouds, {:locals =>
                        {
                            :clouds => clouds,
                            :help =>
                                [
                                    ["Clouds",  clouds_help],
                                    ["Creating a new cloud", "Just type in a cloud name in the 'Cloud Name' text field and click the 'Create Cloud' button - a new configuration will be created."]
                                ]
                        },
                    :layout => :layout}
    end

    get '/tasks/:count' do
      check_first_run!
      tasks_html = nil
      count = params["count"].to_i if params["count"]
      Uhuru::CommanderBoshRunner.execute(session) do
        tasks = Bosh::Cli::Command::Task.new()
        tasks_html = tasks.list_recent(count)
      end
      erb :tasks, {:locals =>
                       {
                           :tasks => tasks_html,
                           :count => count
                       },
                   :layout => :layout}
    end

    get '/task/:id' do
      task_id = params["id"]
      request_id = Uhuru::CommanderBoshRunner.execute_background(session) do
        begin
          task = Bosh::Cli::Command::Task.new()
          task.options[:event] = "true"
          #task.options[:debug] = "true"
          task.track(task_id)
        rescue Exception => ex
          puts "#{ex.to_s}: #{ex.backtrace}"
        end
      end
      redirect "logs/#{request_id}"
    end

    post '/clouds' do
      check_first_run!
      clouds = {}
      if params["create_cloud_name"] != ''
        Uhuru::CommanderBoshRunner.execute(session) do
          deployment = Uhuru::Ucc::Deployment.new(params["create_cloud_name"])
          blank_manifest = File.open(File.expand_path("../../config/blank_cf.yml", __FILE__)) { |file| YAML.load(file)}
          deployment.save(blank_manifest)
          clouds = FormGenerator.get_clouds
        end
      end
      erb :clouds, {:locals =>
                        {
                            :clouds => clouds
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

    get '/users' do
      check_first_run!
      users = Uhuru::Ucc::User.users
      erb :users,
          {
              :locals =>
                  {
                      :users => users,
                      :message => ""
                  },
              :layout => :layout
          }
    end

    post '/users' do
      check_first_run!
      message = "Success"
      begin
        if params.has_key?("btn_create_user")
          if params["create_user_name"] != '' && params["create_user_password"] != '' && Validations.validate_field(params["create_user_password"], "password") == ""
            Uhuru::Ucc::User.create(params["create_user_name"], params["create_user_password"])
          else
            message = "Invalid username/password"
          end
        elsif params.keys.grep(/btn_change_password_(\w+)/).size > 0
          if params["new_password"] != '' && Validations.validate_field(params["new_password"], "password") == ""
            username = params.keys.grep(/btn_change_password_(\w+)/).first.scan(/btn_change_password_(\w+)/).first
            user = Uhuru::Ucc::User.new(username)
            user.update(params["new_password"])
            message = "Password changed successfully"
          else
            message = "Invalid username/password"
          end
        elsif params.keys.grep(/btn_delete_user_(\w+)/).size > 0
          username = params.keys.grep(/btn_delete_user_(\w+)/).first.scan(/btn_delete_user_(\w+)/).first
          user = Uhuru::Ucc::User.new(username)
          user.delete
          message = "User deleted successfully"
        end
      rescue Exception => ex
        message = ex.to_s
      end
      users = Uhuru::Ucc::User.users
      erb :users,
          {
              :locals =>
                  {
                      :users => users,
                      :message => message

                  },
              :layout => :layout
          }
    end

    post '/deployment_status' do
      deployment_status = nil
      Uhuru::CommanderBoshRunner.execute(session) do
        deployment = Uhuru::Ucc::Deployment.new("ccng-dev")
        deployment_status = deployment.status
      end
      deployment_status
    end

    get '/ssh_connect/:deployment/:job/:index' do

      ssh_data = {}
      ssh_data[:deployment] = Uhuru::Ucc::Deployment.new(params[:deployment]).deployment_manifest_path
      ssh_data[:job] = params[:job]
      ssh_data[:index] = params[:index]
      ssh_data[:token] = session.id

      tty_js_param = CGI::escape(Base64.encode64(ssh_data.to_json))
      redirect "/ssh/?connectionData=#{tty_js_param}"
    end

    get '/ssh_config' do

      result = 403

      if request.ip == '127.0.0.1'
        store = session.instance_variable_get("@store")
        unless store == nil
          _, target_session = store.get_session(env, params[:token])

          unless target_session['command'] == nil
            config_file = target_session['command'].instance_variable_get("@config").instance_variable_get("@filename")
            result = config_file
          end
        end
      end

      result
    end
  end
end

