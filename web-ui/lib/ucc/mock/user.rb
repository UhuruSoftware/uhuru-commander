module Uhuru::BoshCommander
  # a class designed to mock the bosh users
  # all the methods of this class are used if the cloud commander is not connected to bosh
  # the methods return custom hardcoded data
  class User
    def initialize(username, system_call = false)
      return username, system_call
    end

    def delete
      return true
    end

    def update(password)
      return password
    end

    def self.users
      []
    end

    def self.create(username, password)
      self.new(username, true)
      return username, password
    end

    private

    def self.get_db
      nil
    end
  end
end