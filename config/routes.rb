Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  namespace :v1 do
    devise_for :users,
               path: 'users',
               path_names: {
                 sign_in: 'sign-in',
                 sign_out: 'sign-out',
                 registration: 'sign-up'
               },
               controllers: {
                 sessions: 'v1/users/sessions',
                 registrations: 'v1/users/registrations'
               },
               defaults: { format: :json }
    resources :users do
      collection do
        put '', to: 'users#update'
        put '/authentication/:uuid', to: 'users#authentication'
      end
    end

    get '/test', to: 'test#index'
  end
end
