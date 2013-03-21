module Bosh::Cli::Command
  class Task
    undef_method :list_recent

    def list_recent(count = 30, filter = 2)
      tasks = director.list_recent_tasks(count, filter)
      tasks
    end

    private
    def get_last_task_id(verbose = 1)
      last = director.list_recent_tasks(1, verbose)
      if last.empty?
        err("No tasks found")
      end

      last[0]["id"]
    end

    def director
      Thread.current.current_session[:command].instance_variable_get("@director")
    end
  end
end