module Uhuru::BoshCommander
  class Logs < RouteBase

    def self.log_url(request_id, action_on_done)
      "logs/#{request_id}?done=#{ CGI.escape Base64.encode64 action_on_done }"
    end

    get '/logs/:stream_id' do
      screen_id = UUIDTools::UUID.random_create.to_s
      CommanderBoshRunner.status_streamer(session).create_screen(params[:stream_id], screen_id)

      action_on_done = params['done']

      render_erb do
        template :logs
        layout :layout
        var :screen_id, screen_id
        var :action, action_on_done
        help 'logs'
      end
    end

    get '/screen/:screen_id' do
      status_streamer = CommanderBoshRunner.status_streamer(session)
      screen_id = params[:screen_id]

      if status_streamer.screen_exists? screen_id
        if status_streamer.screen_done? screen_id
          headers 'X-Commander-Log-Instructions' => 'stop'
          CommanderBoshRunner.status_streamer(session).read_screen(screen_id)
        else
          headers 'X-Commander-Log-Instructions' => 'continue'
          CommanderBoshRunner.status_streamer(session).read_screen(screen_id)
        end
      else
        headers 'X-Commander-Log-Instructions' => 'missing'
      end
    end

    get '/internal_logs' do
      log_file = $config[:logging][:file]
      json = File.read log_file
      logs = []

      Yajl::Parser.parse(json) { |obj|
        logs << obj
      }

      render_erb do
        template :internal_logs
        layout :layout
        var :original_size, logs.size
        var :logs, logs.reverse[0..199]
        help 'internal_logs'
      end
    end

    get '/vmlog/:product/:deployment/:job/:index' do
      deployment = params[:deployment]
      product = params[:product]
      job = params[:job]
      index = params[:index]

      resources_id_dir=File.join(Dir.tmpdir, 'ucc_log_resources')

      unless Dir.exist? resources_id_dir
        Dir.mkdir(resources_id_dir)
      end

      resource_id = UUIDTools::UUID.random_create
      resource_id_file = File.join(resources_id_dir, resource_id)

      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          deployment = Deployment.new(deployment, product)
          deployment.get_vm_logs(job, index, resource_id_file)
        rescue Exception => e
          err e
        end
      end

      action_on_done = "Log tarball has been generated. Click <a href='/vmlog_res/#{resource_id}'>here</a> to download it."
      redirect Logs.log_url(request_id, action_on_done)
    end

    get '/vmlog_res/:res_file_id' do
      resource_file_id = params[:res_file_id]
      resource_file = File.join(Dir.tmpdir, 'ucc_log_resources', resource_file_id)
      redirect "/vmlog-dl/#{File.read(resource_file)}"
    end

    get '/new_logs' do
      last_log = session['last_log'] || 0

      log_file = $config[:logging][:file]
      json = File.read log_file
      logs = []

      Yajl::Parser.parse(json) { |obj|
        if obj['log_level'] == 'error'
          logs << obj
        end
      }

      log = {}
      if (logs.size > 0) && (last_log < logs.length - 1)
        log = logs.last
        log['message'] = log['message'][0..30].gsub(/\s\w+$/, '...')
        log['counter'] = logs.length - 1 - last_log
      end

      session['last_log'] = logs.length - 1

      log.to_json
    end

    get '/download_log_file' do
      log_file = $config[:logging][:file]

      send_file log_file, :filename => "logs", :type => :log
    end

  end
end