module Uhuru::BoshCommander
  class Tasks < RouteBase
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
  end
end