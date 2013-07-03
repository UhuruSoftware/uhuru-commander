class PluginManager
  def add_plugin_version_source(directory)
    definition_files = Dir[File.join(File.expand_path(directory), "bits", "plugin.rb")]
    definition_files.reject! {|f| plugins.any? {|pl| pl.definition_file == File.expand_path(f) } }

    add_definition_files(definition_files)
  end

  class PluginDefinition
    def load

      s = Time.now
      required_files.each {|file| $".delete(file) }
      load_file = File.expand_path(File.join(File.dirname(definition_file), file))
      $:.unshift(File.dirname(load_file))
      new_files = log_requires do
        Kernel.load "#{load_file}.rb"
      end
      required_files.unshift(*new_files)
      if object.respond_to?(:loaded)
        object.loaded
      end
      @load_time = Time.now - s
    end
  end
end