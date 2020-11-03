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
                 registrations: 'v1/users/registrations',
                 passwords: 'v1/users/passwords'
               }
    resources :users do
      collection do
        put '/authentication/:uuid', to: 'users#authentication'
        patch '/:id/privacy', to: 'users#privacy'
      end
    end
    resources :storages do
      resources :storage_boards, path: 'boards' do
        collection do
          post '/drafts', to: 'storage_boards#drafts'
          post '/non-members/drafts', to: 'storage_boards#non_members_drafts'
          put '/:id/view-count', to: 'storage_boards#view_count'
          post '/:id/images', to: 'storage_boards#images'
          post '/non-members/:id/images', to: 'storage_boards#non_members_images'
          get '/:id/edit', to: 'storage_boards#edit'
          patch '/non-members/:id/edit', to: 'storage_boards#non_members_edit'
          put '/non-members/:id', to: 'storage_boards#non_members_update'
          delete '/non-members/:id', to: 'storage_boards#non_members_destroy'
          put '/:id/recommend', to: 'storage_boards#recommend'
          put '/non-members/:id/recommend', to: 'storage_boards#non_members_recommend'
        end
        resources :storage_board_comments, path: 'comments' do
          collection do
            post '/non-members', to: 'storage_board_comments#non_members_create'
            delete '/non-members/:id', to: 'storage_board_comments#non_members_destroy'
          end
          resources :storage_board_comment_replys, path: 'replies' do
            collection do
              post '/non-members', to: 'storage_board_comment_replys#non_members_create'
              delete '/non-members/:id', to: 'storage_board_comment_replys#non_members_destroy'
            end
          end
        end
      end
    end
    resources :notices
    namespace :admin do
      resources :notices do
        collection do
          post '/drafts', to: 'notices#drafts'
          post '/:id/images', to: 'notices#images'
          put '/:id/view-count', to: 'notices#view_count'
          get '/:id/edit', to: 'notices#edit'
        end
        resources :notice_comments, path: 'comments' do
          collection do
            post '/non-members', to: 'notice_comments#non_members_create'
            delete '/non-members/:id', to: 'notice_comments#non_members_destroy'
          end
          resources :notice_comment_replys, path: 'replies' do
            collection do
              post '/non-members', to: 'notice_comment_replys#non_members_create'
              delete '/non-members/:id', to: 'notice_comment_replys#non_members_destroy'
            end
          end
        end
      end
    end
    namespace :system do
      resources :cron do
        collection do
          get '/users/withdrawaled', to: 'cron#user_withdrawaled'
        end
      end
    end
  end
end
