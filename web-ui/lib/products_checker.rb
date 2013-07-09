module Uhuru::BoshCommander
  class ProductsChecker

    def self.start_checking()
      refresh_rate = $config[:versioning][:refresh_rate] || 60
      Thread.new do
        1.upto(Float::INFINITY) do
          check_for_updates
          sleep(refresh_rate)
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

