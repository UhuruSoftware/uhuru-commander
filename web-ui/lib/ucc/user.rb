require 'bcrypt'

module Uhuru::Ucc

  class User

    def initialize(username, system_call = false)
      @username = username
      @db = User.get_db

      if (!system_call)
        if (username == "hm_user")
          raise "The user #{username} is a system and cannot be altered"
        end
      end

      if (!@db[:users].filter(:username => username).first())
         raise "User #{username} does not exist, please create it first"
      end
    end

    def delete
      @db[:users].filter(:username=>@username).delete
    end

    def update(password)
      @db[:users].filter(:username=>@username).update(:password => BCrypt::Password.create(password))
    end

    def self.users
      usrs = []
      db = get_db
      usrs =  db[:users].select(:username).map(:username)
      usrs
    end

    def self.create(username, password)
      db = get_db
      if (db[:users].filter(:username => username).first())
        raise "User already exists"
      end
      db[:users].insert(:username => username, :password => BCrypt::Password.create(password))

      user = self.new(username, true)
      user
    end

    private

    def self.get_db
      director_config_file = File.join($config[:bosh][:base_dir], 'jobs','director','config','director.yml.erb')
      director_yaml = YAML.load_file(director_config_file)
      db_config = director_yaml["db"]
      connection_options = {
          :max_connections => db_config["max_connections"],
          :pool_timeout => db_config["pool_timeout"]
      }
      db = Sequel.connect(db_config["database"], connection_options)

      db
    end

  end

end