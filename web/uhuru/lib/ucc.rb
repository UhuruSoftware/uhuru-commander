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

module Bosh
  module Cli
    class FileWithProgressBarWeb < ::File

      def stop_progress_bar
        say "Stopped progress..."
      end

      def size
        File.size(self.path)
      end

      def read(*args)
        if (@read_so_far == nil)
          say <<script
          "<div style="position:relative; width:102px; height:18px; background-color:#A0A0A0;border:1px solid #7E7E7E">
              <div id="progressbarGUID_value" style="position:absolute; top:1px; left:1px; float:left;width:0px;height:16px; background-color:#414171; border:0px"></div>
              <div id="progressbarGUID_label" style="font-family:Verdana; font-size: 12px; text-align:center; vertical-align:middle; position:absolute; top:1px; left:1px; float:left;width:100px;height:16px; background-color:transparent; border:0px; color:#ffffff">0%</div>
          </div>
          "
script

        end
        @read_so_far ||= 0.0
        @last_percentage ||= 0.0

        result = super(*args)



        if (result == nil || result.size == 0)
          say <<script
          <script type="text/javascript">
            value = 100;
            document.getElementById("progressbar" + "GUID" + "_label").innerText = value + "%";
            document.getElementById("progressbar" + "GUID" + "_value").style["width"] = value + "px";
          </script>
script
          say "done."
        else
          @read_so_far += result.size

          percentage_done = (@read_so_far / size) * 100.0

          if (percentage_done - @last_percentage) > 1
            say <<script
          <script type="text/javascript">
            value = #{percentage_done.to_i};
            document.getElementById("progressbar" + "GUID" + "_label").innerText = value + "%";
            document.getElementById("progressbar" + "GUID" + "_value").style["width"] = value + "px";
          </script>


script
            @last_percentage = percentage_done
          end
        end

        result
      end
    end

    class FileWithProgressBar
      undef_method :open

      def self.open(file, mode)
        FileWithProgressBarWeb.open(file, mode)
      end

    end
  end
end



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

#    post('/login') do
#      if params[:username] == 'admin' && params[:pass] == 'admin'
#        session['user_name'] = params[:username]
#      else
#        redirect '/login'
#      end
#    end


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

      #command_stemcell.add_option(:config, config)
      #command_stemcell.add_option(:cache_dir, cache)
      #command_stemcell.add_option(:non_interactive, true)

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