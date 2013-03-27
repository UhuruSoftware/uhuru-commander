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
      message = ""
      begin
        if params.has_key?("btn_create_user")
          if params["create_user_name"] != '' && params["create_user_password"] != ''
            User.create(params["create_user_name"], params["create_user_password"])
          else
            message = "Invalid username/password"
          end
        elsif params.keys.grep(/btn_change_password_(\w+)/).size > 0
          if params["new_password"] != ''
            username = params.keys.grep(/btn_change_password_(\w+)/).first.scan(/btn_change_password_(\w+)/).first.first
            user = User.new(username)
            user.update(params["new_password"])
            message = "Password changed successfully"
          else
            message = "Invalid username/password"
          end
        elsif params.keys.grep(/btn_delete_user_(\w+)/).size > 0
          username = params.keys.grep(/btn_delete_user_(\w+)/).first.scan(/btn_delete_user_(\w+)/).first.first
          if username.eql?(session['user_name'])
            message = "You cannot delete your own user!"
          else
            user = User.new(username)
            user.delete
            message = "User deleted successfully"
          end
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