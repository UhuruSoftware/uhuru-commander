module Uhuru::BoshCommander
  class ProductsChecker

    def self.start_checking()
      refresh_rate = $config[:versioning][:refresh_rate].to_i
      Thread.new do
        1.upto(Float::INFINITY) do
          check_for_updates

          if refresh_rate != nil
            sleep(refresh_rate)
          else
            sleep(60)
          end
        end
      end
    end

    def self.check_for_updates
      begin
        return Uhuru::BoshCommander::Versioning::Product.download_manifests
      rescue Exception => e
        $logger.error "#{e.message} - #{e.backtrace}"
        start_checking
      end
    end

  end
end

