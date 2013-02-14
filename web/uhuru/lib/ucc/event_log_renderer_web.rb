module Bosh::Cli

  class EventLogRenderer
    undef_method :render

    def render
      @lock.synchronize do

        if (!@isprogress)
          @isprogress = true
          @msg_guid = UUIDTools::UUID.random_create.to_s
          template = ERB.new(File.read("../views/display/event_log.erb"))
          mssg = template.result(binding)
          say(mssg, "")
        end

        @buffer.seek(@pos)
        output = @buffer.read

        jsText = output.strip.split(/[\n\r]/).join('" + "\\n" + "')

        template = ERB.new(File.read("../views/display/event_log_script.erb"))
        mssg = template.result(binding)

        say(mssg, "")
        @pos = @buffer.tell
        output
      end
    end

  end
end
