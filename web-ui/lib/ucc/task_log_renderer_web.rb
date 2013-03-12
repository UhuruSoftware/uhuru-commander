module Bosh::Cli
  class TaskLogRenderer

    undef_method :refresh


    def refresh
      say(@output)
      @output = ""
    end

  end
end
