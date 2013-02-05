require "rubygems"
require "sinatra"
require "sinatra/base"

class Exceptions

  def self.errors(error_name)
    case error_name
      when "invalid ip"
        error = "The <span class='error_highlight'>IP</span> you have entered is invalid. It may be taken allredy or it is not in a proper format!"
        error
      when "invalid netmask"
        error = "The <span class='error_highlight'>Netmask</span> you have entered is invalid. It is not in a proper format!"
        error
      when "invalid gateway"
        error = "The <span class='error_highlight'>Gateway</span> you have entered is invalid. It is not in a proper format!"
        error
      when "invalid dns"
        error = "The <span class='error_highlight'>DNS</span> you have entered is invalid. It is not in a proper format!"
        error
      when "invalid vcenter name"
        error = "The <span class='error_highlight'>vCenter Name</span> you have entered is invalid (it may be allredy taken or it contains unknown characters). Please select another name."
        error
    else
      error = "Unknown server error!"
      error
    end
  end

end