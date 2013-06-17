require 'rubygems'
require 'sinatra'
require 'yaml'
require 'cgi'
require 'rbvmomi'

require "config"
require "date"
require "json"
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

require "ip_helper"
require "ip_admin"

require "ucc/core_ext"
require "ucc/commander_bosh_runner"
require "ucc/infrastructure"
require "ucc/monit"
require "ucc/deployment"
require "ucc/step_deployment"
require "ucc/user"
require "ucc/vms"
require "ucc/task"
require "ucc/event_log_renderer_web"
require "ucc/release"
require "ucc/stemcell"
require "ucc/deployment_status"
require "ucc/deployment_state"

require "routes/route_base"
require "routes/login_screen"
require "routes/clouds"
require "routes/infrastructure"
require "routes/logs"
require "routes/route_base"
require "routes/ssh"
require "routes/tasks"
require "routes/users"
require "routes/versions"
require "routes/monitoring"
require "routes/vm"
require "routes/update"


require "configuration_forms/field"
require "configuration_forms/screen"
require "configuration_forms/generic_form"
require "configuration_forms/infrastructure_form"
require "configuration_forms/cloud_form"
require "configuration_forms/monitoring_form"

require "versioning/product"
require "versioning/version"

autoload :HTTPClient, "httpclient"

module Uhuru::BoshCommander
  class BoshCommander < RouteBase
    use LoginScreen
    use Clouds
    use Infrastructure
    use Logs
    use Ssh
    use Tasks
    use Users
    use Versions
    use Monitoring
    use VM
    use Update

    get '/' do

      #r = Random.new
      session[:new_versions] = true

      #if r.rand(0...1000) % 2 == 0
      #  session[:new_versions] = true
      #else
      #  session[:new_versions] = false
      #end

      redirect '/infrastructure'
    end

    get '/offline' do
      render_erb do
        template :monit_offline
      end
    end
  end
end


