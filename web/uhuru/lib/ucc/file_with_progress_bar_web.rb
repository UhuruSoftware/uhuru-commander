module Bosh
  module Cli
    class FileWithProgressBarWeb < ::File

      def stop_progress_bar
        say "Stopped progress..."
      end

      def size
        File.size(self.path)
      end

      def read(*args)
        if (@read_so_far == nil)
          mssg = <<script
          <div style="position:relative; width:102px; height:18px; background-color:#A0A0A0;border:1px solid #7E7E7E">
              <div id="progressbar#{@pb_id}_value" style="position:absolute; top:1px; left:1px; float:left;width:0px;height:16px; background-color:#414171; border:0px"></div>
              <div id="progressbar#{@pb_id}_label" style="font-family:Verdana; font-size: 12px; text-align:center; vertical-align:middle; position:absolute; top:1px; left:1px; float:left;width:100px;height:16px; background-color:transparent; border:0px; color:#ffffff">0%</div>
          </div>
script
        say(mssg, "")
        end
        @read_so_far ||= 0.0
        @last_percentage ||= 0.0

        result = super(*args)

        if (result == nil || result.size == 0)
          mssg = <<script
          <script type="text/javascript">
            value = 100;
            document.getElementById("progressbar#{@pb_id}_label").innerText = value + "%";
            document.getElementById("progressbar#{@pb_id}_value").style["width"] = value + "px";
          </script>
script
          say(mssg, "")
          say "done."
        else
          @read_so_far += result.size

          percentage_done = (@read_so_far / size) * 100.0

          if (percentage_done - @last_percentage) > 1
            mssg = <<script
          <script type="text/javascript">
            value = #{percentage_done.to_i};
            document.getElementById("progressbar#{@pb_id}_label").innerText = value + "%";
            document.getElementById("progressbar#{@pb_id}_value").style["width"] = value + "px";
          </script>
script
            say(mssg, "")
            @last_percentage = percentage_done
          end
        end

        result
      end
    end

    class FileWithProgressBar
      undef_method :open

      def self.open(file, mode)
        @pb_id = UUIDTools::UUID.random_create.to_s
        FileWithProgressBarWeb.open(file, mode)
      end

    end
  end
end


