require 'bcrypt'

module Uhuru::BoshCommander
  class User
    def initialize(username, system_call = false)
      @username = username
      @db = User.get_db

      unless system_call
        if username == "hm_user"
          raise "The user #{username} required by the system and cannot be altered"
        end
      end

      unless @db[:users].filter(:username => username).first()
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
      db = get_db
      db[:users].select(:username).map(:username)
    end

    def self.create(username, password)
      db = get_db
      if db[:users].filter(:username => username).first()
        raise "User already exists"
      end
      db[:users].insert(:username => username, :password => BCrypt::Password.create(password))

      self.new(username, true)
    end

    private

    def self.get_db
      begin
        director_config_file = File.join($config[:bosh][:base_dir], 'jobs','director','config','director.yml.erb')
        director_yaml = YAML.load_file(director_config_file)
        db_config = director_yaml["db"]
        connection_options = db_config.delete('connection_options') {{}}
        db_config.delete_if { |_, v| v.to_s.empty? }
        db_config = db_config.merge(connection_options)

        Sequel.connect(db_config)
      rescue Exception => e
        $logger.error("#{e.to_s}: #{e.backtrace}")
      end
    end
  end
end