require 'net/ssh/gateway'

gateway = Net::SSH::Gateway.new('127.0.0.1', 'user')

gateway.ssh("127.0.0.1", "user") do |ssh|
  puts ssh.exec!("hostname")
end

gateway.open("127.0.0.1", 80) do |port|
  Net::HTTP.get_print("127.0.0.1", "/path", port)
end

gateway.shutdown!

