module Uhuru::BoshCommander
  class ProductsChecker

    @@products_checker_thread = nil

    def self.start_checking()
      refresh_rate = $config[:versioning][:refresh_rate] || 60

      unless @@products_checker_thread
        @@products_checker_thread = Thread.new do
          while true do
            begin
              Uhuru::BoshCommander::Versioning::Product.download_manifests
            rescue
              $logger.error "#{e.message} - #{e.backtrace}"
            end

            sleep(refresh_rate)
          end
        end
      end
    end
  end
end

