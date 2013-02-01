
module Uhuru
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
        Thread.current.request_id = id
        Thread.current.streamer = status_streamer(session)

        code.call
      }.join

      id
    end

    def self.execute_background(session, id = nil, &code)
      unless id
        id = UUIDTools::UUID.random_create
      end

      BoshThread.new {
        Thread.current.request_id = id
        Thread.current.streamer = status_streamer(session)

        code.call
      }

      id
    end
  end

  class BoshThread < Thread
    attr_accessor :request_id
    attr_accessor :streamer
  end
end

#
#class Sayer
#  def say(something)
#    request_id = Thread.current.request_id
#    Thread.current.streamer.write_stream(request_id, something)
#  end
#end

#
#session = Hash.new()
#
#newid = Uhuru::CommanderBoshRunner.execute(session) do
#  sleep 1
#  Sayer.new().say("1")
#end
#
#Uhuru::CommanderBoshRunner.execute_background(session, newid) do
#  Sayer.new().say("2")
#  sleep 1
#  Sayer.new().say("4")
#end
#
#Uhuru::CommanderBoshRunner.execute(session, newid) do
#  Sayer.new().say("3")
#end
#
#sleep 1
#
#Uhuru::CommanderBoshRunner.status_streamer(session).create_screen(newid, "test")
#puts Uhuru::CommanderBoshRunner.status_streamer(session).read_screen("test")
#Uhuru::CommanderBoshRunner.status_streamer(session).close_screen("test")