module Bosh::Cli

class StageProgressBar
  undef_method :refresh
  undef_method :bar

  def refresh
    if (!@isprogress)
      @isprogress = true
      @progress_guid = UUIDTools::UUID.random_create

      mssg = <<script
          <div id="#{@progress_guid}_title"></div>
          <div style="position:relative; width:102px; height:18px; background-color:#A0A0A0;border:1px solid #7E7E7E">
              <div id="#{@progress_guid}_pb" style="position:absolute; top:1px; left:1px; float:left;width:0px;height:16px; background-color:#414171; border:0px"></div>
              <div id="#{@progress_guid}_p_label" style="font-family:Verdana; font-size: 12px; text-align:center; vertical-align:middle; position:absolute; top:1px; left:1px; float:left;width:100px;height:16px; background-color:transparent; border:0px; color:#ffffff">0%</div>
          </div>
          <div id="#{@progress_guid}_steps"></div>
          <div id="#{@progress_guid}_label"></div>
script
      say(mssg, "")
    end
    @filler = "x"
    clear_line
    label = ""
    label = " #{@label}" if @label
    current_percent = (@current.to_f / @total.to_f) * 100.00
    @output.print " #{@label}" if @label
    mssg = <<script
          <script type="text/javascript">
            value = #{current_percent.to_i};
            title =  "#{@title}"
            finished_steps = #{@finished_steps}
            total_steps = #{@total}
            label = "#{label}"
            document.getElementById("#{@progress_guid}_title").innerHtml = title;
            document.getElementById("#{@progress_guid}_p_label").innerHtml = value + "%";
            document.getElementById("#{@progress_guid}_pb").style["width"] = value + "px";
            document.getElementById("#{@progress_guid}_steps").innerHtml = "finished " + finished_steps + " of " + total_steps;
            document.getElementById("#{@progress_guid}_label").innerHtml = label;
          </script>
script
    say(mssg, "")
  end

  def bar

  end

end

end
