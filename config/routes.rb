Rails.application.routes.draw do
  post "/webhook" => "webhook#process_event"
  get "/webhook" => "webhook#verify_token"
  get "/test" => "webhook#test_verse"
end
