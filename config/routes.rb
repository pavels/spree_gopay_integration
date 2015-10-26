Spree::Core::Engine.routes.draw do
  get '/gopay/notify', to: 'gopay#notify'
  get '/gopay/return', to: 'gopay#return'
end
