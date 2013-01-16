PerseusShield::Application.routes.draw do
  match '/r' => 'application#resize'
end
