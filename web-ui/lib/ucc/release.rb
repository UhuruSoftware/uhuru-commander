module Uhuru::BoshCommander
  # releases class
  class Release
    def initialize()
    end

    # upload release
    def upload(release_file)
       release_command.upload(release_file)
    end

    # return all releases
    def list_releases
      releases = director.list_releases.sort do |rel1, rel2|
        rel1["name"] <=> rel2["name"]
      end
      releases
    end

    # delete a release
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
