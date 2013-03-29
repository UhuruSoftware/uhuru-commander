module Uhuru::BoshCommander
  class CommanderBoshRunner

    def self.status_streamer(session)
      unless session[:status_streamer]
        session[:status_streamer] = StatusStreamer.new
      end
      session[:status_streamer]
    end

    def self.execute(session, id = nil, &code)
      unless id
        id = UUIDTools::UUID.random_create
      end

      BoshThread.new {
        begin
          Thread.current.request_id = id
          Thread.current.streamer = status_streamer(session)
          Thread.current.current_session = session
          code.call
        rescue Exception => ex
          $logger.error("#{ex.message}: #{ex.backtrace}")
          raise
        ensure
          if Thread.current.streamer == nil
            $logger.error("Detected a BOSH thread without a streamer - #{caller}")
          else
            Thread.current.streamer.set_stream_done id
          end
        end
      }.join

      id
    end

    def self.execute_background(session, id = nil, &code)
      unless id
        id = UUIDTools::UUID.random_create
      end

      streamer = status_streamer(session)
      streamer.write_stream(id, nil)

      BoshThread.new {
        begin
          Thread.current.request_id = id
          Thread.current.streamer = streamer
          Thread.current.current_session = session
          code.call
          Thread.current.streamer.set_stream_done id
        rescue Exception => ex
          $logger.error("#{ex.message}: #{ex.backtrace}")
          raise
        ensure
          if Thread.current.streamer == nil
            $logger.error("Detected a BOSH thread without a streamer - #{caller}")
          else
            Thread.current.streamer.set_stream_done id
          end
        end
      }

      id
    end
  end

  class BoshThread < Thread
    attr_accessor :request_id
    attr_accessor :streamer
    attr_accessor :current_session
  end
end