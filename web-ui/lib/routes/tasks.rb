module Uhuru::BoshCommander
  # a class used for the tasks page in the cloud commander
  class Tasks < RouteBase

    #get method for the tasks page
    get '/tasks/:count/:include_all' do
      tasks_list = nil
      count = params["count"] ? params["count"].to_i : 30
      include_all = params["include_all"] ? params["include_all"] == 'true' : true
      CommanderBoshRunner.execute(session) do
        tasks = Bosh::Cli::Command::Task.new()
        tasks_list = tasks.list_recent(count, include_all ? 2 : 1)
      end

      render_erb do
        template :tasks
        layout :layout
        var :tasks, tasks_list
        var :count, count
        var :include_all, include_all
        help 'tasks'
      end
    end

    # get method for a specific task with the task id
    get '/task/:id' do
      task_id = params["id"]
      request_id = CommanderBoshRunner.execute_background(session) do
        task = Bosh::Cli::Command::Task.new()
        task.options[:event] = "true"
        task.track(task_id)
      end

      action_on_done = "Click <a href='javascript:history.back()'>here</a> to go back."
      redirect Logs.log_url(request_id, action_on_done)
    end

    # get method for the loop system
    get '/loop' do
      request_id = CommanderBoshRunner.execute_background(session) do
        start = Time.now
        while (Time.now - start) < 300
          color = Random.rand(4)

          if color == 0
            say "#{300 - (Time.now - start)} seconds remaining..."
          elsif color == 1
            say "#{300 - (Time.now - start)} seconds remaining...".red
          elsif color == 2
            say "#{300 - (Time.now - start)} seconds remaining...".green
          elsif color == 3
            say "#{300 - (Time.now - start)} seconds remaining...".yellow
          end

          sleep 2
        end
      end

      action_on_done = "Click <a href='/'>here</a> to go home."
      redirect Logs.log_url(request_id, action_on_done)
    end
  end
end