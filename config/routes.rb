Rails.application.routes.draw do
  root to: "home#show"

  get 'profile', to: 'home#profile'
end
