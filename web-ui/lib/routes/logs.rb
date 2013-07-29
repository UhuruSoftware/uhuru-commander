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
        var :logs, logs.reverse[0..199].reverse
        var :logs_total, logs.size
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
      last_log = session['last_log']

      log_file = $config[:logging][:file]
      json = File.read log_file
      logs = []

      Yajl::Parser.parse(json) { |obj|
        logs << obj
      }

      if last_log < logs.index(logs.last)
        send_log = nil #logs.last

        is_last = 0
        logs.reverse.each do |log|
          if logs.index(log) >= last_log
            if log['log_level'] == 'error'

              #count the logs that have error type
              is_last += 1

              #modify message and counter if the log is the type of error
              log['message'] = log['message'][0..30].gsub(/\s\w+$/, '...')
              log['counter'] = logs.index(logs.last) - last_log

              #check if this is the last logged error
              if is_last == 1
                send_log = log
              end
            end
          end
        end

      end

      session['last_log'] = logs.index(logs.last)

      send_log.to_json
    end

    get '/download_log_file' do
      log_file = $config[:logging][:file]
      send_file log_file, :filename => "logs", :type => :log
    end

  end
end