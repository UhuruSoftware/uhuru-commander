module Bosh::Cli::Command
  class Task
    undef :list_recent

    def list_recent(count = 30, filter = 2)
      tasks = director.list_recent_tasks(count, filter)
      template = ERB.new(File.read("../views/display/tasks_table.erb"))
      result = template.result(binding)
      result
    end

    #def track(task_id=nil, debug = false, use_filter = 2)
    #  if task_id.nil? || %w(last latest).include?(task_id)
    #    task_id = get_last_task_id(get_verbose_level(use_filter))
    #  end
    #
    #
    #end

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