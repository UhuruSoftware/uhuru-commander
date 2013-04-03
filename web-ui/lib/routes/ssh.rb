module Uhuru::BoshCommander
  class Ssh < RouteBase
    get '/ssh_connect/:deployment/:job/:index' do

      ssh_data = {}
      ssh_data[:deployment] = Deployment.new(params[:deployment]).deployment_manifest_path
      ssh_data[:job] = params[:job]
      ssh_data[:index] = params[:index]
      ssh_data[:token] = env['rack.session.options'][:id]
      tty_js_param = CGI::escape(Base64.encode64(ssh_data.to_json))
      redirect "/ssh/?connectionData=#{tty_js_param}"
    end

    get '/ssh_config' do

      result = 403

      if request.ip == '127.0.0.1'
        unless $pool == nil
          target_session = $pool[params[:token]]

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