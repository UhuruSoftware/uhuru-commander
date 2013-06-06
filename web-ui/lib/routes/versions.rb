module Uhuru::BoshCommander
  class Clouds < RouteBase
    get '/new_versions' do
      session[:new_versions] = false
      redirect '/versions'
    end

    get '/versions' do
      tables = []


      hash1 = { :title              => 'First',
                :body           => {
                    :versions           => [ '3.0.0', '3.5.0', '4.0', '4.2', '4.3', '4.5' ],
                    :descriptions       => [ 'a simple and small descriptions 1', 'dddddddddddddddddddddddddddd ddddddddddddddddddddddd ddddddddddddddddddddddddddd dddddddd ddddddddddddddd ddddddddddddddddd' ],
                    :dependencies       => [ 'ruby 1.9.2, sinatra, rails framework', 'none', 'nodeJs<br /> meteor framework' ],
                    :actions            => [
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'false', :delete => 'true'},
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'true', :delete => 'false'},
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'false', :delete => 'true'},
                    ]
                }
      }

      hash2 = { :title              => 'Second table....',
                :body           => {
                    :versions           => [ '3.0.0', '3.5.0', '4.0', '4.2', '4.3', '4.5' ],
                    :descriptions       => [ 'a simple and small descriptions 1', 'tacdasdsadasdadasdsdasdasdpac' ],
                    :dependencies       => [ 'ruby 1.9.2, sinatra, rails framework', 'none', 'nodeJs<br /> meteor framework' ],
                    :actions            => [
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'false', :delete => 'true'},
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'true', :delete => 'false'},
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'false', :delete => 'true'},
                    ]
                }
      }

      hash3 = { :title              => 'And the last table',
                :body           => {
                    :versions           => [ '3.0.0', '3.5.0', '4.0', '4.2', '4.3', '4.5' ],
                    :descriptions       => [ 'a simple and small descriptions 1', '' ],
                    :dependencies       => [ 'ruby 1.9.2, sinatra, rails framework', 'none', 'nodeJs<br /> meteor framework' ],
                    :actions            => [
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'false', :delete => 'true'},
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'true', :delete => 'false'},
                        {:install => 'true', :download => 'true', :delete => 'true'},
                        {:install => 'false', :download => 'false', :delete => 'true'},
                    ]
                }
      }

      tables.push(hash1, hash2, hash3)

      render_erb do
        template :versions
        layout :layout
        var :tables, tables
        help 'versions'
      end
    end
  end
end


#tables.each do |table|
#  elements = table[:body][:versions].count
#  counter = 0
#  keys = table[:body].keys
#
#
#  while counter <= elements - 1 do
#    keys.each do |key|
#      if key.to_s == 'versions'
#        puts table[:body][key.to_sym][counter]
#      end
#
#      if key.to_s == 'actions'
#        if table[:body][key.to_sym][counter] != nil
#          puts table[:body][key.to_sym][counter][:install]
#        end
#      end
#    end
#    counter += 1
#  end
#end
