# encoding: utf-8
module RedmineWikicipher
  class Hooks < Redmine::Hook::ViewListener
	def view_layouts_base_html_head(context={ })
      		context[:controller].send(:render_to_string, {
        	:partial => "hooks/redmine_wikicipher/includes",
        	:locals => context
      })
   	end
	def view_wiki_contextual(context={ })
		#if params[:decode]=='1'
		if context[:toggle]==nil
			context[:toggle] = '1'
		elsif context[:toggle]=='0'
			context[:toggle] = '1'
		else
			context[:toggle] = '0'
		end
		if context[:toggle]=='1'
			link = "<a href=\"/projects/"+context[:id]+"/wiki?decode="+context[:toggle]+"\" class=\"icon icon-decrypt\"><%= t 'redmine_wikicipher.decode' %></a>"
		else
			link = "<a href=\"/projects/"+context[:id]+"/wiki?decode="+context[:toggle]+"\" class=\"icon icon-encrypt\"><%= t 'redmine_wikicipher.encode' %></a>"
		end

		hideLink=1
		text = context[:content].text
		if text.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m).size>0
			hideLink=0
		end
		if text.scan(/\{\{decoded\_start\}\}.*?\{\{decoded\_stop\}\}/m).size>0
			hideLink=0
		end
		if hideLink==1
			link=""
		end
		#toggle = context[:toggle]
		#link = toggle
      		context[:controller].send(:render_to_string, {
        	:inline => link ,
        	:locals => context
      })
   	end

	
  end
end
