module Uhuru::BoshCommander

  class User
    def initialize(username, system_call = false)
    end

    def delete
    end

    def update(password)
    end

    def self.users
      []
    end

    def self.create(username, password)
      self.new(username, true)
    end

    private

    def self.get_db
      nil
    end
  end

end