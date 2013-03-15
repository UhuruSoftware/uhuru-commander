module Bosh::Cli

class StageProgressBar
  undef_method :refresh
  undef_method :bar
  undef_method :calculate_terminal_width

  def refresh
    if (!@isprogress)

      @isprogress = true
      template = ERB.new(File.read("../views/display/stage_progressbar.erb"))
      mssg = template.result(binding)
      say(mssg, "")
    end
    @filler = "x"
    label = ""
    label = " #{@label}" if @label
    current_percent = (@finished_steps.to_f / @total.to_f) * 100.00
    bar_visible = @bar_visible
    template = ERB.new(File.read("../views/display/stage_progressbar_script.erb"))
    mssg = template.result(binding)
    say(mssg, "")
  end

  def calculate_terminal_width
    @progress_guid = UUIDTools::UUID.random_create.to_s
    if !ENV["TERM"].blank?
      width = `tput cols`
      $?.exitstatus == 0 ? [width.to_i, 100].min : 80
    else
      80
    end
  rescue
    80
  end

  def bar

  end

end

end
