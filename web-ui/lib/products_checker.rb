module Uhuru::BoshCommander
  # Class used to for product checking
  class ProductsChecker

    @@products_checker_thread = nil

    # Checks for available products on every refresh rate amount of time
    #
    def self.start_checking()
      refresh_rate = $config[:versioning][:refresh_rate] || 60

      unless @@products_checker_thread
        @@products_checker_thread = Thread.new do
          while true do
            begin
              Uhuru::BoshCommander::Versioning::Product.download_manifests
            rescue Exception => ex
              $logger.error "#{ex.message} - #{ex.backtrace}"
            end

            sleep(refresh_rate)
          end
        end
      end
    end
  end
end

