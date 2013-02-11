module Bosh::Cli

  class EventLogRenderer
    undef_method :render

    def render
      @lock.synchronize do

        if (!@isprogress)
          @isprogress = true
          @msg_guid = UUIDTools::UUID.random_create.to_s
#          mssg = <<script
#          <div id="#{@msg_guid}_text"></div>
#script
#          say(mssg, "")
        end

        @buffer.seek(@pos)
        output = @buffer.read

#        mssg = <<script
#          <script type="text/javascript">
#            text = "#{output}"
#            document.getElementById("#{@msg_guid}_text").innerText = text;
#          </script>
#script

        say(output)
        @pos = @buffer.tell
        output
      end
    end

  end
end
