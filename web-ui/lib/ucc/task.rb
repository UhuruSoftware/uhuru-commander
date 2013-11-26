module Bosh::Cli::Command
  # tasks class
  class Task
    undef_method :list_recent

    def initialize
      @director = director
      super
    end

    # list recent task
    def list_recent(count = 30, filter = 2)
      director.list_recent_tasks(count, filter)
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

    def target
      Thread.current.current_session[:command].target
    end

    def deployment
      Thread.current.current_session[:command].deployment
    end

    def username
      Thread.current.current_session[:command].username
    end

    def password
      Thread.current.current_session[:command].password
    end
  end
end