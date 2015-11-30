Spree::Core::Engine.routes.draw do
  get '/gopay/notify', to: 'gopay#notify'
  get '/gopay/continue', to: 'gopay#continue'
end
