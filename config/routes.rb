Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  namespace :v1, defaults: { format: :json } do
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
               }
    resources :users do
      collection do
        put '/authentication/:uuid', to: 'users#authentication'
      end
    end
    resources :storages do
      resources :storage_boards, path: 'boards' do
        collection do
          post '/drafts', to: 'storage_boards#drafts'
          post '/drafts/non-members', to: 'storage_boards#drafts_non_members'
          put '/:id/view-count', to: 'storage_boards#view_count'
          post '/:id/images', to: 'storage_boards#images'
          post '/:id/images/non-members', to: 'storage_boards#images_non_members'
        end
      end
    end
  end
end
