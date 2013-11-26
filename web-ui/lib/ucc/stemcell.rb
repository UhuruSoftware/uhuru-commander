module Uhuru::BoshCommander
  # the stemcells class definition
  class Stemcell

    # upload stemcell
    def upload(tarball_path)
      stemcell_command.upload(tarball_path)
    end

    # delete stemcell
    def delete(name, version)
      stemcell_command.delete(name, version)
    end

    # list all stemcells
    def list_stemcells
      director.list_stemcells
    end

    private

    def stemcell_command
      command = Thread.current.current_session[:command]
      stemcell_cmd = Bosh::Cli::Command::Stemcell.new
      stemcell_cmd.instance_variable_set("@options", command.instance_variable_get("@options"))
      stemcell_cmd.add_option(:force, true)
      stemcell_cmd
    end

    def director
      Thread.current.current_session[:command].instance_variable_get("@director")
    end


  end
end
