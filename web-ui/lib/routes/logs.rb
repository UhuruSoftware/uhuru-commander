module Uhuru::BoshCommander
  # a class used for the logging system
  class Logs < RouteBase

    def self.log_url(request_id, action_on_done)
      "logs/#{request_id}?done=#{ CGI.escape Base64.encode64 action_on_done }"
    end

    # get method for a specific log
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

    # get method for logs_test page
    get '/logs_test' do
      request_id = CommanderBoshRunner.execute_background(session) do
        begin

          50.times do |val|
            10.times do |word|
              say "0123456789".red
              say "0123456789\r".green
              say "0123456789".yellow
              say "|ooooooooooooooooo      |"
              say "Proposition: #{word}"
            end

            say "Paragraph ##{val.to_s}"
            sleep 1
          end

        rescue Exception => ex
          err ex
        end
      end

      action_on_done = "Apasa-l <a href='/logs_test'>din nou</a>."
      redirect Logs.log_url request_id, action_on_done
    end

    # get method for a specific screen id
    get '/screen/:screen_id' do
      status_streamer = CommanderBoshRunner.status_streamer(session)
      screen_id = params[:screen_id]

      if status_streamer.screen_exists? screen_id
        if status_streamer.screen_done? screen_id
          headers 'X-Commander-Log-Instructions' => 'stop'
        else
          headers 'X-Commander-Log-Instructions' => 'continue'
        end

        output = CommanderBoshRunner.status_streamer(session).read_screen(screen_id)

        if output
          output = output.gsub(/\n/i, '</div><div>&nbsp;')

          output = output.gsub(/\x20/i, "&nbsp;")
          output = output.gsub(/\*\*\*color_out_end\*\*\*/i, "</span>")
          output = output.gsub(/\*\*\*color_out_start_green\*\*\*/i, "<span class='isa_success'>")
          output = output.gsub(/\*\*\*color_out_start_red\*\*\*/i, "<span class='isa_error'>")
          output = output.gsub(/\*\*\*color_out_start_yellow\*\*\*/i, "<span class='isa_warning'>")


          pb_value = output.scan(/\|(o*)(&nbsp;)*\|/i)
          if (pb_value[0]) && (pb_value[0][0])
            pb_value = pb_value[0][0].length

            output = output.gsub(/\|(o*)(&nbsp;)*\|/i, "<span class='progress_out'><span class='progress_in p#{ pb_value }'></span></span>")
          end

          output = output.gsub(/\r/i, "<span class='remove_me'></span></div><div>")
        end

        output
      else
        headers 'X-Commander-Log-Instructions' => 'missing'
      end
    end

    # get method for the internal logs page
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

    # get method for the vm log
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
        rescue Exception => ex
          err ex
        end
      end

      action_on_done = "Log tarball has been generated. Click <a href='/vmlog_res/#{resource_id}'>here</a> to download it."
      redirect Logs.log_url(request_id, action_on_done)
    end

    # get method for vm log resource
    get '/vmlog_res/:res_file_id' do
      resource_file_id = params[:res_file_id]
      resource_file = File.join(Dir.tmpdir, 'ucc_log_resources', resource_file_id)
      redirect "/vmlog-dl/#{File.read(resource_file)}"
    end

    # get method for the new logs
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

    # get method for the download log file (returns and sends the log file for downloading)
    get '/download_log_file' do
      log_file = $config[:logging][:file]
      send_file log_file, :filename => "logs", :type => :log
    end
  end
end
