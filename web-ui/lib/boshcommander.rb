require "rubygems"
require "sinatra"
require "yaml"
require "exceptions"
require "validations"
require "bosh_methods"
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
        form_generator = FormGenerator.new('G:/code/private-bosh-web-commander/config/cloudfoundry.yml', 'G:/code/private-bosh-web-commander/config/forms2.yml', {})
        tables = { :networking => "Networking", :cpi => "CPI" }

        erb :infrastructure, {:locals =>
                                  {
                                      :form_generator => form_generator,
                                      :form => "infrastructure",
                                      :table => tables,
                                      :error => nil,
                                      :form_data => {}
                                  },
                              :layout => :layout}
    end

    post '/doInfrastructure' do
      form_generator = FormGenerator.new('G:/code/private-bosh-web-commander/config/cloudfoundry.yml', 'G:/code/private-bosh-web-commander/config/forms2.yml', {})
      tables = { :networking => "Networking", :cpi => "CPI" }

      if params[:method_name] == "save"
        params.delete("method_name")
        params.delete("btn_parameter")
        form_generator.generate_form("infrastructure", tables[:networking], params)
        form_generator.generate_form("infrastructure", tables[:cpi], params)
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

      redirect '/infrastructure'
    end

    get '/clouds/configure' do

      form_generator = FormGenerator.new('G:/code/private-bosh-web-commander/config/cloudfoundry.yml', 'G:/code/private-bosh-web-commander/config/forms2.yml', {})

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
      form_generator = FormGenerator.new('G:/code/private-bosh-web-commander/config/cloudfoundry.yml', 'G:/code/private-bosh-web-commander/config/forms2.yml', {})

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




    get "/formtest" do

      form_generator = FormGenerator.new('G:/code/private-bosh-web-commander/config/cloudfoundry.yml', 'G:/code/private-bosh-web-commander/config/forms2.yml', {})

      erb :form, {:locals =>
                      {
                          :form_generator => form_generator,
                          :form => 'infrastructure',
                          :screen_name => 'Networking',
                          :form_data => {}
                      },
                  :layout => :layout}
    end
  end

end
