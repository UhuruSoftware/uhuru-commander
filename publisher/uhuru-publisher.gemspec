
Gem::Specification.new do |s|
  s.name         = "uhuru-publisher"
  s.version      = "0.0.1"
  s.platform     = Gem::Platform::RUBY
  s.summary      = "Uhuru Software internal version publisher"
  s.description  = "Uhuru Software internal version publisher"
  s.author       = "Uhuru Software, Inc."
  s.homepage      = 'http://www.uhurusoftware.com'
  s.license       = 'Internal use only'
  s.email         = "arad@uhurusoftware.com"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  s.files        = `git ls-files -- bin/* lib/* config/* web_interface/*`.split("\n")
  s.require_path = "lib"
  s.bindir       = "bin"
  s.executables  = %w(uhuru-publisher)


  s.add_dependency "escort"
  s.add_dependency "terminal-table"
  s.add_dependency "rb-readline"
  s.add_dependency "sinatra"
  s.add_dependency "json"
end