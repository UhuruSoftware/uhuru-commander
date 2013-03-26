module Uhuru::BoshCommander
  class Users < RouteBase
    get '/users' do
      users = User.users

      render_erb do
        template :users
        layout :layout
        var :users, users
        var :message, ""
        help 'users'
      end
    end

    post '/users' do
      message = "Success"
      begin
        if params.has_key?("btn_create_user")
          if params["create_user_name"] != '' && params["create_user_password"] != '' && Validations.validate_field(params["create_user_password"], "password") == ""
            User.create(params["create_user_name"], params["create_user_password"])
          else
            message = "Invalid username/password"
          end
        elsif params.keys.grep(/btn_change_password_(\w+)/).size > 0
          if params["new_password"] != '' && Validations.validate_field(params["new_password"], "password") == ""
            username = params.keys.grep(/btn_change_password_(\w+)/).first.scan(/btn_change_password_(\w+)/).first
            user = User.new(username)
            user.update(params["new_password"])
            message = "Password changed successfully"
          else
            message = "Invalid username/password"
          end
        elsif params.keys.grep(/btn_delete_user_(\w+)/).size > 0
          username = params.keys.grep(/btn_delete_user_(\w+)/).first.scan(/btn_delete_user_(\w+)/).first
          user = User.new(username)
          user.delete
          message = "User deleted successfully"
        end
      rescue Exception => ex
        message = ex.to_s
      end
      users = User.users

      render_erb do
        template :users
        layout :layout
        var :users, users
        var :message, message
        help 'users'
      end
    end
  end
end