module Uhuru::BoshCommander

  class ErbRenderHelper

    def layout(set_layout)
      @layout = set_layout
    end

    def template(set_template)
      @template = set_template
    end

    def var(name, value)
      @locals[name] = value
    end

    def help(help_data)
      unless @locals[:help]
        @locals[:help] = []
      end

      if help_data.is_a? String
        @locals[:help] = @locals[:help] + $config[:help][help_data]
      else
        @locals[:help] = @locals[:help] + help_data
      end
    end

    def render(&code)
      @layout = nil
      @template = nil
      @locals = { }

      self.instance_eval &code

      unless @layout
        @layout = @template
      end


      [@template, @layout, @locals]
    end
  end

  class RouteBase < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, File.expand_path("../../../views", __FILE__)
    set :public_folder, File.expand_path("../../../public", __FILE__)
    set :raise_errors, Proc.new { false }
    set :show_exceptions, false
    register Sinatra::VCAP
    use Rack::Logger

    def logger
      request.logger
    end

    def render_erb(&code)
      template, layout, locals = ErbRenderHelper.new.render &code

      erb template,
          :layout => layout,
          :locals => locals
    end

    before do
      unless request.path_info == '/login' ||
          request.path_info == '/offline' ||
          request.path_info == '/monit_status' ||
          request.path_info == '/ssh_config' ||
          request.path_info == '/logout'
        unless session['user_name']
          redirect "/login?path=#{CGI.escape request.path_info}"
        end

        unless request.path_info.start_with? '/logs' || request.path_info.start_with?('/screen')
          check_updating_infrastructure!
        end

        unless request.path_info == '/infrastructure'
          check_first_run!
        end
      end
    end

    not_found do
      ex = "404 - Sorry, page not found."

      render_erb do
        template :error
        var :ex, ex
      end
    end

    error do
      $logger.error "#{request.env['sinatra.error'].message} - #{request.env['sinatra.error'].backtrace}"

      ex = "Sorry, a server error has occurred. Please contact your system administrator.<br /><br />#{request.env['sinatra.error'].message}"

      render_erb do
        template :error
        var :ex, ex
      end
    end

    helpers Sinatra::ContentFor
    helpers do
      def first_run?
        !File.exists?(File.expand_path('../../../config/infrastructure.yml', __FILE__))
      end

      def updating_infrastructure?
        $infrastructure_update_request != nil
      end

      def check_updating_infrastructure!
        action_on_done = "Click <a href='/'>here</a> to reload the commander interface."
        redirect Logs.log_url($infrastructure_update_request, action_on_done) if updating_infrastructure?
      end

      def check_first_run!
        redirect '/infrastructure' if first_run?
      end

      def forms_yml
        File.expand_path('../../../config/forms.yml', __FILE__)
      end
    end
  end
end