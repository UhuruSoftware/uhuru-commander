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

      form_data = {}
      table_errors = form_generator.get_table_errors(form_data)

    erb :cloudConfiguration, {:locals =>
                                  {
                                      :form_generator => form_generator,
                                      :form => "cloud",
                                      :js_tabs => {
                                        :networks => "Networks",
                                        :compilation => "Compilation",
                                        :resource_pools => "Resource Pools",
                                        :update => "Update",
                                        :deas => "DEAs",
                                        :services => "Services",
                                        :properties => "Properties",
                                        :service_plans => "Service Plans"
                                       },
                                      :default_tab => :networks,
                                      :error => nil,
                                      :table_errors => table_errors,
                                      :form_data => {}
                                  },
                              :layout => :layout}
    end

    post '/clouds/configure' do
      form_generator = FormGenerator.new('../config/cloudfoundry.yml', '../config/forms.yml', {})

      if params[:method_name] == "save"
        params.delete("method_name")
        params.delete("btn_parameter")

        table_errors = form_generator.get_table_errors(params)

        if (table_errors.select{|key| key=true }).size == 0
           form_generator.save_local_deployment(params)
        end

        erb :cloudConfiguration, {:locals =>
                                  {
                                      :form_generator => form_generator,
                                      :form => "cloud",
                                      :js_tabs => {
                                        :networks => "Networks",
                                        :compilation => "Compilation",
                                        :resource_pools => "Resource Pools",
                                        :update => "Update",
                                        :deas => "DEAs",
                                        :services => "Services",
                                        :properties => "Properties",
                                        :service_plans => "Service Plans"
                                       },
                                      :default_tab => :networks,
                                      :error => nil,
                                      :table_errors => table_errors,
                                      :form_data => params
                                  },
                              :layout => :layout}

      elsif params[:method_name] == "save_and_deploy"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)

      elsif params[:method_name] == "tear_down"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)

      elsif params[:method_name] == "delete"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)

      elsif params[:method_name] == "export"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)

      elsif params[:method_name] == "import"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)
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
