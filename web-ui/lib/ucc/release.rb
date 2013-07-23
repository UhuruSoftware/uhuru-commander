module Uhuru::BoshCommander
  class Release
    def initialize()

    end

    def upload(release_file)
       release_command.upload(release_file)
    end

    def list_releases
      releases = director.list_releases.sort do |r1, r2|
        r1["name"] <=> r2["name"]
      end
      releases
    end

    def delete(name, version)
      release_command.delete(name,version)
    end

    private

    def release_command
      command = Thread.current.current_session[:command]
      release_cmd = Bosh::Cli::Command::Release.new
      release_cmd.instance_variable_set("@options", command.instance_variable_get("@options"))
      release_cmd.add_option(:force, true)
      release_cmd.add_option(:rebase, true)
      release_cmd
    end

    def director
      Thread.current.current_session[:command].instance_variable_get("@director")
    end

  end
end
