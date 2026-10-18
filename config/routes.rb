Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  get "trade", to: "trade#index"

  get   "wiki",            to: "wiki/articles#index",  as: :wiki
  get   "wiki/search",     to: "wiki/articles#search",  as: :wiki_search
  get   "wiki/graph",      to: "wiki/graphs#show",      as: :wiki_graph
  get   "wiki/graph.json", to: "wiki/graphs#data",      as: :wiki_graph_data, defaults: { format: :json }
  get   "wiki/new",        to: "wiki/articles#new",     as: :new_wiki_article
  post  "wiki",            to: "wiki/articles#create",  as: :wiki_articles
  get   "wiki/:slug/edit", to: "wiki/articles#edit",    as: :edit_wiki_article
  patch "wiki/:slug",      to: "wiki/articles#update"
  get   "wiki/:slug",      to: "wiki/articles#show",    as: :wiki_article

  get  "interview",                               to: "interview/problems#index", as: :interview_problems
  post "interview/problems/:problem_id/sessions", to: "interview/sessions#create", as: :interview_problem_sessions
  get  "interview/sessions/:id",                  to: "interview/sessions#show",   as: :interview_session
  post "interview/sessions/:id/messages",         to: "interview/messages#create", as: :interview_session_messages
end
