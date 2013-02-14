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
        if (@pb_id.to_s == "")
          @pb_id =  UUIDTools::UUID.random_create.to_s
        end
        if (@read_so_far == nil)
          template = ERB.new(File.read("../views/display/file_progressbar.erb"))
          mssg = template.result(binding)

        say(mssg, "")
        end
        @read_so_far ||= 0.0
        @last_percentage ||= 0.0

        result = super(*args)

        if (result == nil || result.size == 0)
          percentage_done = 100
          template = ERB.new(File.read("../views/display/file_progressbar_script.erb"))
          mssg = template.result(binding)
          say(mssg, "")
          @pb_id = ""
          say "done."
        else
          @read_so_far += result.size

          percentage_done = (@read_so_far / size) * 100.0

          if (percentage_done - @last_percentage) > 1
            template = ERB.new(File.read("../views/display/file_progressbar_script.erb"))
            mssg = template.result(binding)
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
        FileWithProgressBarWeb.open(file, mode)
      end

    end
  end
end


