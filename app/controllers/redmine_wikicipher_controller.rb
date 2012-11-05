class RedmineWikicipherController < ApplicationController

  def decode
	redirect_to :controller => 'wiki', :action => 'show', :decode => '1',:project_id => @project
	end

end
