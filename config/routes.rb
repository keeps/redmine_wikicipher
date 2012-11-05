if Gem::Version.new("3.0") > Gem::Version.new(Rails.version) then
  ActionController::Routing::Routes.draw do |map|
    map.connect 'projects/:id/wiki/decode', :controller => 'redmine_wikicipher', :action => 'decode'
  end
else
  RedmineApp::Application.routes.draw do
    match 'projects/:id/wiki/decode', :to => 'redmine_wikicipher', :action => 'decode'
  end
end
