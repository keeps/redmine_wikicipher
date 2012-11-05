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

	def controller_wiki_edit_before_save(context = { })
		begin
			temp=''
			originalText = context[:content].text
			matches = originalText.scan(/\{\{cipher\}\}.*?\{\{cipher\}\}/m)
			matches.each do |m|
				tagContent = m.gsub('{{cipher}}','')
				codedTag = ''
				if tagContent != ''
					codedTag = m
					if Redmine::Configuration['database_cipher_key'].to_s.strip != ''
						key = Digest::SHA256.hexdigest(Redmine::Configuration['database_cipher_key'].to_s.strip)
						e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
						e.encrypt key
						s = e.update tagContent
						s << e.final
						s = s.unpack('H*')[0].upcase
						encrypted = s
						codedTag = '{{coded_start}}'+encrypted.strip+'{{coded_stop}}'
					end
				end
				originalText = originalText.gsub(m, codedTag)
			end

	      		context[:content].text=originalText
		rescue

		end
	end
        def controller_wiki_decode_content_export(context = { })
		begin
			originalText = context[:content].text
			params = context[:params]

			if params[:decode]=='1'
				key = Digest::SHA256.hexdigest(Redmine::Configuration['database_cipher_key'].to_s.strip)
				matches = originalText.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)	
				matches.each do |m|
					tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
					e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
					e.decrypt key
					s = tagContent.to_a.pack("H*").unpack("C*").pack("c*")
					s = e.update s
					decoded = s << e.final
					decoded = ''+decoded+''
					originalText = originalText.gsub(m.strip, decoded.strip)
				end			
	
			
				context[:content].text=originalText.strip
			end
		rescue

		end
		
		
         end

	def controller_wiki_decode_content(context = { })
		begin
			originalText = context[:content].text
			params = context[:params]

			if params[:decode]=='1'
				key = Digest::SHA256.hexdigest(Redmine::Configuration['database_cipher_key'].to_s.strip)
				matches = originalText.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)	
				matches.each do |m|
					tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
					e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
					e.decrypt key
					s = tagContent.to_a.pack("H*").unpack("C*").pack("c*")
					s = e.update s
					decoded = s << e.final
					decoded = '{{decoded_start}}'+decoded+'{{decoded_stop}}'
					originalText = originalText.gsub(m.strip, decoded.strip)
				end			
	
			
				context[:content].text=originalText.strip
			end
		rescue

		end
		
		
         end
	def controller_wiki_decode_content_with_tags(context = { })
		begin
			originalText = context[:content].text
			params = context[:params]

			if params[:decode]=='1'
				if Redmine::Configuration['database_cipher_key'].to_s.strip != ''
					key = Digest::SHA256.hexdigest(Redmine::Configuration['database_cipher_key'].to_s.strip)
					matches = originalText.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)	
					matches.each do |m|
						tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
						e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
						e.decrypt key
						s = tagContent.to_a.pack("H*").unpack("C*").pack("c*")
						s = e.update s
						decoded = s << e.final
						decoded = '{{cipher}}'+decoded+'{{cipher}}'
						originalText = originalText.gsub(m.strip, decoded.strip)
					end
				end			
	
			
				context[:content].text=originalText.strip
			end
		rescue

		end
		
		
         end
  end
end
