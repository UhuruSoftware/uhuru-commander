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

    def initialize(config)
      super()
    end

    error 404 do
      ex = "The page was not foud, please try again later!"
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
      form_generator = FormGenerator.new('../config/cloudfoundry.yml', '../config/forms.yml', {})
      tables = { :networking => "Networking", :cpi => "CPI" }

      if defined? params
        table_errors = { :networking => params[:error_networking], :cpi => params[:error_cpi] }
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
                                    :form_data => {}
                                },
                            :layout => :layout}
    end

    post '/doInfrastructure' do
      form_generator = FormGenerator.new('../config/cloudfoundry.yml', '../config/forms.yml', {})
      tables = { :networking => "Networking", :cpi => "CPI" }                                          # a hash for each table in this page

      error_networking = ""
      error_cpi = ""

      if params[:method_name] == "save"
        params.delete("method_name")
        params.delete("btn_parameter")

        #form_generator.generate_form("infrastructure", tables[:networking], params)
        form_generator.generate_form("infrastructure", tables[:networking], params).each do |networking_field|
          if(networking_field[:error].to_s != "true")
            error_networking = 'error'
          end
        end

        #form_generator.generate_form("infrastructure", tables[:cpi], params)
        form_generator.generate_form("infrastructure", tables[:cpi], params).each  do |cpi_field|
          if(cpi_field[:error].to_s != "true")
            error_cpi = 'error'
          end
        end
      end

      if params[:method_name] == "test"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("infrastructure", tables[:networking], params)
        form_generator.generate_form("infrastructure", tables[:cpi], params)
      end

      if params[:method_name] == "update"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("infrastructure", tables[:networking], params)
        form_generator.generate_form("infrastructure", tables[:cpi], params)
      end

      if error_networking != 'error' && error_cpi != 'error'
        redirect '/infrastructure'
      else
        redirect "/infrastructure?error_networking=#{error_networking}&error_cpi=#{error_cpi}"
      end
    end






    get '/clouds/configure' do
      form_generator = FormGenerator.new('../config/cloudfoundry.yml', '../config/forms.yml', {})

      if defined? params
        table_errors = {
            :networks => params[:error_networks],
            :compilation => params[:error_compilation],
            :resource_pools => params[:error_resource_pools],
            :update => params[:error_update],
            :deas => params[:error_deas],
            :services => params[:error_services],
            :properties => params[:error_properties],
            :service_plans => params[:error_service_plans],
            :advanced => params[:error_advanced]
        }
      end

      erb :cloudConfiguration, {:locals =>
                                {
                                    :form_generator => form_generator,
                                    :form => "cloud",
                                    :networks => "Networks",
                                    :compilation => "Compilation",
                                    :resource_pools => "Resource Pools",
                                    :update => "Update",
                                    :deas => "DEAs",
                                    :services => "Services",
                                    :properties => "Properties",
                                    :service_plans => "Service Plans",
                                    :advanced => "Advanced",
                                    :error => nil,
                                    :table_errors => table_errors,
                                    :form_data => {}
                                },
                            :layout => :layout}
    end

    post '/doCloudManage' do
      form_generator = FormGenerator.new('../config/cloudfoundry.yml', '../config/forms.yml', {})

      error_networks = ""
      error_compilation = ""
      error_resource_pools = ""
      error_update = ""
      error_deas = ""
      error_services = ""
      error_properties = ""
      error_service_plans = ""
      error_advanced = ""

      if params[:method_name] == "save"
        params.delete("method_name")
        params.delete("btn_parameter")

        #form_generator.generate_form("cloud", "Networks", params)
        form_generator.generate_form("cloud", "Networks", params).each do |networks_field|
          if(networks_field[:error].to_s != "true")
            error_networks = 'error'
          end
        end

        #form_generator.generate_form("cloud", "Compilation", params)
        form_generator.generate_form("cloud", "Compilation", params).each do |compilation_field|
          if(compilation_field[:error].to_s != "true")
            error_compilation = 'error'
          end
        end

        #form_generator.generate_form("cloud", "Resource Pools", params)
        form_generator.generate_form("cloud", "Resource Pools", params).each do |resource_pools_field|
          if(resource_pools_field[:error].to_s != "true")
            error_resource_pools = 'error'
          end
        end

        #form_generator.generate_form("cloud", "Update", params)
        form_generator.generate_form("cloud", "Update", params).each do |update_field|
          if(update_field[:error].to_s != "true")
            error_update = 'error'
          end
        end

        #form_generator.generate_form("cloud", "DEAs", params)
        form_generator.generate_form("cloud", "DEAs", params).each do |deas_field|
          if(deas_field[:error].to_s != "true")
            error_deas = 'error'
          end
        end

        #form_generator.generate_form("cloud", "Services", params)
        form_generator.generate_form("cloud", "Services", params).each do |services_field|
          if(services_field[:error].to_s != "true")
            error_services = 'error'
          end
        end

        #form_generator.generate_form("cloud", "Properties", params)
        form_generator.generate_form("cloud", "Properties", params).each do |properties_field|
          if(properties_field[:error].to_s != "true")
            error_properties = 'error'
          end
        end

        #form_generator.generate_form("cloud", "Service Plans", params)
        form_generator.generate_form("cloud", "Service Plans", params).each do |service_plans_field|
          if(service_plans_field[:error].to_s != "true")
            error_service_plans = 'error'
          end
        end

        #form_generator.generate_form("cloud", "Advanced", params)
        form_generator.generate_form("cloud", "Advanced", params).each do |advanced_field|
          if(advanced_field[:error].to_s != "true")
            error_advanced = 'error'
          end
        end
      end

      if params[:method_name] == "save_and_deploy"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)
      end

      if params[:method_name] == "tear_down"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)
      end

      if params[:method_name] == "delete"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)
      end

      if params[:method_name] == "export"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)
      end

      if params[:method_name] == "import"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)
      end



      if error_networks != 'error' && error_compilation != 'error' && error_resource_pools != 'error' && error_update != 'error' && error_deas != 'error' && error_services != 'error' && error_properties != 'error' && error_service_plans != 'error' && error_advanced != 'error'
        redirect '/clouds/configure'
      else
        redirect "/clouds/configure?error_networks=#{error_networks}&error_compilation=#{error_compilation}&error_resource_pools=#{error_resource_pools}&error_update=#{error_update}&error_deas=#{error_deas}&error_services=#{error_services}&error_properties=#{error_properties}&error_service_plans=#{error_service_plans}&error_advanced=#{error_advanced}"
      end
    end


    get '/advanced' do
      erb :advanced, {:layout => :layout}
    end


    get '/clouds' do
      erb :clouds, {:layout => :layout}
    end


    get '/tasks' do
      erb :tasks, {:layout => :layout}
    end

  end

end
