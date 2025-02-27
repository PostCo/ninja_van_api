NinjaVanApi::Engine.routes.draw do
  controller :webhooks do
    post "/" => "webhooks#create"
  end
end
