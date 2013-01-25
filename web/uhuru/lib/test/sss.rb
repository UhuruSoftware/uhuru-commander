class FileWithProgressBar < ::File
  def progress_bar
  end

  def stop_progress_bar
    $stdout.write "am gatat"
  end

  def size
    File.size(self.path)
  end

  def read(*args)
    result = super(*args)

    if result && result.size > 0
      $stdout.write "am marit la #{result.size}"
    else
      $stdout.write "gatai"
    end

    result
  end
end


class ALuMitza < ::File
  def progress_bar
  end

  def stop_progress_bar
    $stdout.write "am slobozit"
  end

  def size
    File.size(self.path)
  end

  def read(*args)
    result = super(*args)

    if result && result.size > 0
      $stdout.write "am pisat la #{result.size}"
    else
      $stdout.write "slobzai"
    end

    result
  end
end

class FileWithProgressBar
  undef_method :open

  def self.open(file, mode)
    ALuMitza.open(file, mode)
  end

end


f = FileWithProgressBar.open("/tmp/some_file", "r")

f.read()

f.stop_progress_bar