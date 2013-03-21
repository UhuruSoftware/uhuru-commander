
require 'fileutils'
require "uuidtools"
require 'tmpdir'

module Uhuru
  class StatusStreamer
    MAX_BYTES_TO_READ = 1024 * 100

    @streams_dir = nil
    @screens = nil
    @id = nil

    def initialize()
      @id = UUIDTools::UUID.random_create
      @streams_dir = File.join(Dir.tmpdir, @id)

      Dir.mkdir(@streams_dir)

      @screens = {}
      ObjectSpace.define_finalizer(self, proc { cleanup! })
    end

    def write_stream(stream_name, data)
      file_name = File.join(@streams_dir, stream_name.to_s + ".data")
      File.open(file_name, "a") do |file|
        file.write("#{data}<!-- WRITE_BLOCK_END -->")
      end
    end

    def set_stream_done(stream_name)
      file_name = File.join(@streams_dir, stream_name.to_s + ".done")
      FileUtils.touch file_name
    end

    def create_screen(stream_name, screen_name)
      if @screens[screen_name]
        raise "Screen already exists"
      end

      @screens[screen_name] = [stream_name, 0]
    end

    def stream_done?(stream_name)
      File.exists? File.join(@streams_dir, stream_name.to_s + ".done")
    end

    def screen_exists?(screen_name)
      @screens.include? screen_name
    end

    def screen_done?(screen_name)
      unless @screens[screen_name]
        raise "Screen #{screen_name} does not exist"
      end

      stream_name, _ = @screens[screen_name]

      stream_done? stream_name
    end

    def read_screen(screen_name)
      unless @screens[screen_name]
        raise "Screen #{screen_name} does not exist"
      end

      stream_name, read_bytes = @screens[screen_name]

      file_name = File.join(@streams_dir, stream_name.to_s + ".data")

      unless File.exist?(file_name)
       return ""
      end

      chunk = IO::read(file_name, MAX_BYTES_TO_READ, read_bytes)

      if chunk
        chunk = chunk.match(/.*(<!-- WRITE_BLOCK_END -->)/m).to_s
        @screens[screen_name][1] = read_bytes + chunk.length
        chunk.gsub! /<!-- WRITE_BLOCK_END -->/, ''
      end

      chunk
    end

    def close_screen(screen_name)
      @screens[screen_name] = nil
    end

    private

    def cleanup!()
      FileUtils.rm_rf(@streams_dir)
    end
  end
end