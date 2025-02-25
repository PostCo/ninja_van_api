NinjaVanAPI::Engine.routes.draw do
  post '/webhooks', to: 'webhook#create'
end
