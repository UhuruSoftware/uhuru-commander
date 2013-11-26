module Bosh::Cli
  # event log reader class
  class EventLogRenderer
    undef_method :render

    def render
      @lock.synchronize do
        @buffer.seek(@pos)
        output = @buffer.read

        request_id = Thread.current.request_id
        Thread.current.streamer.write_stream(request_id, output)

        @pos = @buffer.tell
        output
      end
    end
  end
end
