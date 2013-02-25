require 'rubygems'
require 'sinatra'
require 'yaml'
require 'exceptions'
require 'validations'
require 'bosh_methods'
require 'form_generator'

module Uhuru::BoshCommander

  class BoshCommander < Sinatra::Base

    set :root, File.expand_path("../../", __FILE__)
    set :views, File.expand_path("../../views", __FILE__)
    set :public_folder, File.expand_path("../../public", __FILE__)
    set :raise_errors, Proc.new { false }
    set :show_exceptions, false

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

    def first_run
      !File.exists?('../config/infrastructure.yml')
    end

    def initialize(config)
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


    get '/' do
      redirect '/infrastructure'
    end

    get '/infrastructure' do
      form_generator = nil
      if first_run
        form_generator = FormGenerator.new('../config/infrastructure_live.yml', '../config/forms.yml', '../config/infrastructure_live.yml')
      else
        form_generator = FormGenerator.new('../config/infrastructure.yml', '../config/forms.yml', '../config/infrastructure_live.yml')
      end

      tables = { :cpi => "CPI" }

      if defined? params
        table_errors = { :cpi => params[:error_cpi] }
      else
        table_errors = nil
      end

      erb :infrastructure, {:locals =>
                                {
                                    :form_generator => form_generator,
                                    :form => "infrastructure",
                                    :table => tables,
                                    :error => nil,
                                    :table_errors => table_errors,
                                    :form_data => {},
                                    :first_run => first_run
                                },
                            :layout => :layout}
    end

    post '/doInfrastructure' do
      form_generator = FormGenerator.new('../config/infrastructure.yml', '../config/forms.yml', '../config/infrastructure_live.yml')
      tables = { :cpi => "CPI" }                                          # a hash for each table in this page

      error_networking = ""
      error_cpi = ""

      if defined? params
        puts params.inspect
        table_errors = { :cpi => params[:error_cpi] }
      else
        table_errors = nil
      end

      if params[:method_name] == "save"
        params.delete("method_name")
        params.delete("btn_parameter")

        if table_errors.select{|key, value| value==true }.size == 0
           form_generator.save_local_deployment("infrastructure", params)
        end

        form_generator.generate_form("infrastructure", tables[:cpi], params).each  do |cpi_field|
          if(cpi_field[:error].to_s != "true")
            error_cpi = 'error'
          end
        end

      elsif params[:method_name] == "test"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("infrastructure", tables[:cpi], params)

      elsif params[:method_name] == "update"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("infrastructure", tables[:cpi], params)
      end

      if error_networking != 'error' && error_cpi != 'error'
        redirect '/infrastructure'
      else
        redirect "/infrastructure?error_networking=#{error_networking}&error_cpi=#{error_cpi}"
      end
    end



    get '/clouds/configure/*' do
      if first_run
        redirect '/infrastructure'
      end

      cloud_name = request.path_info.split("configure/")[1]
      form_generator = FormGenerator.new("../config/clouds/#{cloud_name}", "../config/forms.yml", "../config/clouds/live/#{cloud_name}")

      form_data = {}
      puts DateTime.now
      table_errors = form_generator.get_table_errors(form_data)
      puts DateTime.now

      erb :cloud_configuration, {:locals =>
                                  {
                                      :form_generator => form_generator,
                                      :form => "cloud",
                                      :js_tabs => cloud_js_tabs,
                                      :default_tab => :networks,
                                      :error => nil,
                                      :table_errors => table_errors,
                                      :form_data => {},
                                      :cloud_name => cloud_name,
                                      :first_run => first_run
                                  },
                              :layout => :layout}
    end

    post '/clouds/configure/*' do
      if first_run
        redirect '/infrastructure'
      end

      cloud_name = request.path_info.split("configure/")[1]

      if params[:method_name] == "save"
        params.delete("method_name")
        params.delete("btn_parameter")

        form_generator = FormGenerator.new("../config/clouds/#{cloud_name}", "../config/forms.yml")
        table_errors = form_generator.get_table_errors(params)

        if table_errors.select{|key, value| value==true }.size == 0
           form_generator.save_local_deployment("cloud", params)
        end

        form_generator = FormGenerator.new("../config/clouds/#{cloud_name}", "../config/forms.yml", "../config/clouds/live/#{cloud_name}")
        erb :cloudConfiguration, {:locals =>
                                  {
                                      :form_generator => form_generator,
                                      :form => "cloud",
                                      :js_tabs => cloud_js_tabs,
                                      :default_tab => :networks,
                                      :error => nil,
                                      :table_errors => table_errors,
                                      :form_data => params,
                                      :cloud_name => cloud_name,
                                      :first_run => first_run
                                  },
                              :layout => :layout}

      elsif params[:method_name] == "save_and_deploy"
        params.delete("method_name")
        params.delete("btn_parameter")

        form_generator = FormGenerator.new("../config/clouds/#{cloud_name}", "../config/forms.yml")
        table_errors = form_generator.get_table_errors(params)

        if table_errors.select{|key, value| value==true }.size == 0
           form_generator.save_local_deployment("cloud", params)
        end

        FileUtils.copy_file("../config/clouds/#{cloud_name}", "../config/clouds/live/#{cloud_name}")
        form_generator = FormGenerator.new("../config/clouds/#{cloud_name}", "../config/forms.yml", "../config/clouds/live/#{cloud_name}")
        erb :cloudConfiguration, {:locals =>
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

      elsif params[:method_name] == "tear_down"
        params.delete("method_name")
        params.delete("btn_parameter")

      elsif params[:method_name] == "delete"
        params.delete("method_name")
        params.delete("btn_parameter")
        File.delete("../config/clouds/#{cloud_name}")
        if File.exist?("../config/clouds/live/#{cloud_name}")
          File.delete("../config/clouds/live/#{cloud_name}")
        end

        redirect "/clouds"

      elsif params[:method_name] == "export"
        params.delete("method_name")
        params.delete("btn_parameter")

        content_type 'application/octet-stream'
        File.read("../config/clouds/#{cloud_name}")

      elsif params[:method_name] == "import"
        params.delete("method_name")
        params.delete("btn_parameter")
      end

    end


    get '/advanced' do
      erb :advanced, {
          :locals => {
              :first_run => first_run
          },
          :layout => :layout}
    end


    get '/clouds' do
      if first_run
        redirect '/infrastructure'
      end
      erb :clouds, {:locals =>
                                  {
                                      :clouds => FormGenerator.get_clouds,
                                      :first_run => first_run
                                  },
                              :layout => :layout}
    end


    get '/tasks' do
      if first_run
        redirect '/infrastructure'
      end
      erb :tasks, {
          :locals => {
              :first_run => first_run
          },
          :layout => :layout}
    end

    post '/clouds' do
      if params["create_cloud_name"] != ''
        FileUtils.copy_file("../config/blank.yml", "../config/clouds/#{params["create_cloud_name"]}")
      end

      erb :clouds, {:locals =>
                                  {
                                      :clouds => FormGenerator.get_clouds
                                  },
                              :layout => :layout}
    end
  end

end
