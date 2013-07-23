module Uhuru::BoshCommander
  class VM < RouteBase

    get '/vm/:method/:product/:deployment/:job/:index' do
      deployment = params[:deployment]
      product = params[:product]
      job = params[:job]
      index = params[:index]
      vm_method = params[:method]

      request_id = CommanderBoshRunner.execute_background(session) do
        begin
          deployment_obj = Deployment.new(deployment, product)
          case vm_method
            when 'start'
              deployment_obj.start_vm(job, index)
            when 'stop'
              deployment_obj.stop_vm(job, index)
            when 'restart'
              deployment_obj.restart_vm(job,index)
            when 'recreate'
              deployment_obj.recreate_vm(job, index)
          end

        rescue Exception => e
          err e
        end
      end

      action_on_done = "Job #{vm_method} '#{job}' '#{index}' finished. Click <a href='/products/:product_name/#{deployment}'>here</a> to return to current cloud."
      redirect Logs.log_url(request_id, action_on_done)
    end


  end
end