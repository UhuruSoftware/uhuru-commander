require 'fileutils'
require "uuidtools"

class StatusStreamer
  MAX_BYTES_TO_READ = 1024 * 10

  @@data_dir

  @streams_dir = nil
  @screens = nil
  @id = nil

  def self.configure(data_dir)
    @@data_dir = data_dir

    Dir.glob("#{@@data_dir}/*/").each do |d|
      FileUtils.rm_rf(d)
    end
  end

  def initialize()
    unless @@data_dir
      raise "Status streamer not configured. Call 'StatusStreamer.config' to configure."
    end

    @id = UUIDTools::UUID.random_create
    @streams_dir = File.join(@@data_dir, @id)

    Dir.mkdir(@streams_dir)

    @screens = {}
    ObjectSpace.define_finalizer(self, proc { cleanup! })
  end

  def create_stream(stream_name)
    file_name = File.join(@streams_dir, stream_name)

    if File.exists? file_name
      raise "Stream already exists"
    end

    FileUtils.touch file_name
  end

  def write_stream(stream_name, data)
    file_name = File.join(@streams_dir, stream_name)
    File.open(file_name, "a") do |file|
      file.write(data)
    end
  end

  def create_screen(screen_name, stream_name)
    if @screens[screen_name]
      raise "Screen already exists"
    end

    file_name = File.join(@streams_dir, stream_name)

    unless File.exists?(file_name)
      raise "Stream '#{ stream_name }' does not exist"
    end

    @screens[screen_name] = [stream_name, 0]
  end

  def read_screen(screen_name)
    unless @screens[screen_name]
      raise "Screen does not exist"
    end

    stream_name, read_bytes = @screens[screen_name]

    file_name = File.join(@streams_dir, stream_name)

    chunk = IO::read(file_name, MAX_BYTES_TO_READ, read_bytes)

    if chunk
      @screens[screen_name][1] = read_bytes + chunk.length
    end

    sleep(1)

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
