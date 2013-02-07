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

      #if defined? params[:table_error]
      #  if params[:table_error] != nil
      #    a = params.sub( '\'', "" )
      #    puts params
      #    #b = a.replace()
      #  end
      #end

      erb :infrastructure, {:locals =>
                                {
                                    :form_generator => form_generator,
                                    :form => "infrastructure",
                                    :table => tables,
                                    :error => nil,
                                    :table_error => nil, #params[:table_error],
                                    :form_data => {}
                                },
                            :layout => :layout}
    end

    def indifferent_params(params)
      params = indifferent_hash.merge(params)
      params.each do |key, value|
        next unless value.is_a?(Hash)
        params[key] = indifferent_params(value)
      end
    end

    post '/doInfrastructure' do
      form_generator = FormGenerator.new('../config/cloudfoundry.yml', '../config/forms.yml', {})
      tables = { :networking => "Networking", :cpi => "CPI" }                                          # a hash for each table in this page
      table_error = Hash.new
      table_error = { :networking => "", :cpi => "" }                                                  # a hask for signing an error an a particular table  -- in the current page

      if params[:method_name] == "save"
        params.delete("method_name")
        params.delete("btn_parameter")

        form_generator.generate_form("infrastructure", tables[:networking], params)

        form_generator.generate_form("infrastructure", tables[:networking], params).each do |networking_field|
          if(networking_field[:error].to_s != "true")
            table_error[:networking] = 'error'
          end
        end

        form_generator.generate_form("infrastructure", tables[:cpi], params).each  do |cpi_field|
          if(cpi_field[:error].to_s != "true")
            table_error[:cpi] = 'error'
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

      if table_error[:networking] != 'error' && table_error[:cpi] != 'error'
        redirect '/infrastructure'
      else
        redirect "/infrastructure?table_error=#{table_error}"
      end
    end

    get '/clouds/configure' do

      form_generator = FormGenerator.new('../config/cloudfoundry.yml', '../config/forms.yml', {})

      erb :cloudConfiguration, {:locals =>
                                {
                                    :form_generator => form_generator,
                                    :form => "cloud",
                                    :compilation => "Compilation",
                                    :form_data => {}
                                },
                            :layout => :layout}
    end

    post '/doCloudManage' do
      form_generator = FormGenerator.new('../config/cloudfoundry.yml', '../config/forms.yml', {})

      if params[:method_name] == "save"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("cloud", "Compilation", params)
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

      redirect '/clouds/configure'
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
