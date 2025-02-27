NinjaVanAPI::Engine.routes.draw do
  controller :webhooks do
    post "/" => :create
  end
end
