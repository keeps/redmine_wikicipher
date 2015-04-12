require 'redmine'
# encoding: utf-8
module WikiControllerPatch
    def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :update, :encryption
      alias_method_chain :show, :decryption
      alias_method_chain :edit, :decription_tagged
    end
  end
  

	def self.isKeyValid(originalText)
		$key = Digest::SHA256.hexdigest(Redmine::Configuration['database_cipher_key'].to_s.strip)
		begin
			matches = originalText.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)	
			matches.each do |m|
				tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
				decoded = decrypt(tagContent)
			end
			return '1'
		rescue
			return '0'
		end
	end	 
  module InstanceMethods
	$key = Digest::SHA256.hexdigest(Redmine::Configuration['database_cipher_key'].to_s.strip)

	def encrypt(originalText)
		
		e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
		e.encrypt $key
		s = e.update originalText
		s << e.final
		s = s.unpack('H*')[0].upcase
		encrypted = s
		return encrypted
	end

	def decrypt(encodedContent)
		e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
		e.decrypt $key
		s = encodedContent.to_a.pack("H*").unpack("C*").pack("c*")
		s = e.update s
		decoded = s << e.final
		return decoded
	end


	def encode(originalText,params,history)
		originalText = originalText.gsub(/\\/) { '\\\\' }
		#originalText = originalText.gsub("&", '\\\\&')
		flash.delete(:warning) 
		if history==1
			params[:decode]='1'
			originalText = decodeContent(originalText,params,1,0)
			originalText = originalText.gsub(/\\/) { '\\\\' }
			if Redmine::Configuration['database_cipher_key'].to_s.strip != ''
				encrypted = encrypt(originalText)
				originalText = '{{history_coded_start}}'+encrypted.strip+'{{history_coded_stop}}'
			end
	      		return originalText
		else
			
			matches = originalText.scan(/\{\{cipher\}\}.*?\{\{cipher\}\}/m)
			matches.each do |m|
				tagContent = m.gsub('{{cipher}}','')
				codedTag = ''
				if tagContent != ''
					codedTag = m
					if Redmine::Configuration['database_cipher_key'].to_s.strip != ''
						encrypted = encrypt(tagContent)
						codedTag = '{{coded_start}}'+encrypted.strip+'{{coded_stop}}'
					end
				end
				originalText = originalText.gsub(m.force_encoding("UTF-8"), codedTag.force_encoding("UTF-8"))
			end
			originalText = originalText.gsub(/\\\\/) { '\\' }
	      		return originalText
		end
	end
	def decodeContent(originalText,params,tags,export)
		flash.delete(:warning) 
		if(originalText.strip.match(/^\{\{history\_coded\_start\}\}/m) && originalText.strip.match(/\{\{history\_coded\_stop\}\}$/m))
			begin
				matches = originalText.scan(/\{\{history\_coded\_start\}\}.*?\{\{history\_coded\_stop\}\}/m)	
				matches.each do |m|
					tagContent = m.gsub('{{history_coded_start}}','').gsub('{{history_coded_stop}}','').strip
					decoded = decrypt(tagContent)
					decoded = ''+decoded+''
					originalText = originalText.gsub(m.strip.force_encoding("UTF-8"), decoded.strip.force_encoding("UTF-8"))
				end
				originalText = encode(originalText,params,0)
			rescue
				flash[:warning] = l("redmine_wikicipher.bad_decrypt")
			end
		end
		
		if params[:decode]=='1'
			begin
				matches = originalText.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)	
				matches.each do |m|
					tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
					decoded = decrypt(tagContent)
				
					if tags==1
						decoded = '{{cipher}}'+decoded+'{{cipher}}'
					elsif export==1

						decoded = ''+decoded+''
					else
            decoded = "<notextile>"+decoded+"</notextile>"
						decoded = '{{decoded_start}} '+decoded+' {{decoded_stop}}'
					end
					originalText = originalText.gsub(m.strip.force_encoding("UTF-8"), decoded.strip.force_encoding("UTF-8"))
				end	
			rescue
				flash[:warning] = l("redmine_wikicipher.bad_decrypt")
				#originalText = l("redmine_wikicipher.bad_decrypt")
			end		
		end
		return originalText
	end

    def show_with_decryption
	if @page.new_record?
      if User.current.allowed_to?(:edit_wiki_pages, @project) && editable?
        edit
        render :action => 'edit'
      else
        render_404
      end
      return
    end
    if params[:version] && !User.current.allowed_to?(:view_wiki_edits, @project)
      # Redirects user to the current version if he's not allowed to view previous versions
      redirect_to :version => nil
      return
    end

    @content = @page.content_for_version(params[:version])

    @contentTemp = WikiContent.new
     @contentTemp.author = @content.author
    @contentTemp.text = @content.text
    @contentTemp.version = @content.version
    @contentTemp.page = @content.page
    @contentTemp.id = @content.id

     @contentTemp.page_id = @content.page_id
    @contentTemp.author_id = @content.author_id
    @contentTemp.comments = @content.comments
    @contentTemp.updated_on = @content.updated_on

    @content = @contentTemp










    #@content = @page.content_for_version(params[:version])
    decodedText = decodeContent(@content.text,params,0,0);
    @content.text = decodedText
    if User.current.allowed_to?(:export_wiki_pages, @project)
      if params[:format] == 'pdf'
	params[:decode]='1'
         @content.text = decodeContent(@content.text,params,0,1);
	 
	 clone = @page.clone
	clone.content = @content
        send_data(wiki_page_to_pdf(clone, @project), :type => 'application/pdf', :filename => "#{clone.title}.pdf")
        return
      elsif params[:format] == 'html'
	params[:decode]='1'
	@content.text = decodeContent(@content.text,params,0,1);
        export = render_to_string :action => 'export', :layout => false
        send_data(export, :type => 'text/html', :filename => "#{@page.title}.html")
        return
      elsif params[:format] == 'txt'
	params[:decode]='1'
	@content.text = decodeContent(@content.text,params,0,1);
        send_data(@content.text, :type => 'text/plain', :filename => "#{@page.title}.txt")
        return
      end
    end
    #@content.text = @content.text.sub("!", "&#33;")
    @editable = editable?
    @sections_editable = @editable && User.current.allowed_to?(:edit_wiki_pages, @page.project) &&
      @content.current_version? &&
      Redmine::WikiFormatting.supports_section_edit?

    render :action => 'show'
    end
   
def edit_with_decription_tagged
	return render_403 unless editable?
    if @page.new_record?
      @page.content = WikiContent.new(:page => @page)
      if params[:parent].present?
        @page.parent = @page.wiki.find_page(params[:parent].to_s)
      end
    end
   
    @content = @page.content_for_version(params[:version])
   
    @contentTemp = WikiContent.new
    @contentTemp.author = @content.author
    @contentTemp.text = @content.text
    @contentTemp.version = @content.version
    @contentTemp.page = @content.page
    @contentTemp.id = @content.id
    @contentTemp.page_id = @content.page_id
    @contentTemp.author_id = @content.author_id
    @contentTemp.comments = @content.comments
    @contentTemp.updated_on = @content.updated_on


    @content = @contentTemp
    

    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    # To prevent StaleObjectError exception when reverting to a previous version
    @content.version = @page.content.version
    params[:decode]='1'
 

    if(@content.text.strip.match(/^\{\{history\_coded\_start\}\}/m) && @content.text.strip.match(/\{\{history\_coded\_stop\}\}$/m))
	key = Digest::SHA256.hexdigest(Redmine::Configuration['database_cipher_key'].to_s.strip)
	matches = @content.text.scan(/\{\{history\_coded\_start\}\}.*?\{\{history\_coded\_stop\}\}/m)	
	matches.each do |m|
		tagContent = m.gsub('{{history_coded_start}}','').gsub('{{history_coded_stop}}','').strip
		e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
		e.decrypt key
		s = tagContent.to_a.pack("H*").unpack("C*").pack("c*")
		s = e.update s
		decoded = s << e.final
		decoded = ''+decoded+''
		@content.text = @content.text.gsub(m.strip.force_encoding("UTF-8"), decoded.strip.force_encoding("UTF-8"))
	end
    else
	 @content.text = decodeContent(@content.text,params,1,0)
    end
    @text = @content.text
    if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
      @section = params[:section].to_i
      @text, @section_hash = Redmine::WikiFormatting.formatter.new(@text).get_section(@section)
      render_404 if @text.blank?
    end
end

def update_with_encryption
    if Redmine::VERSION::MAJOR > 1
logger.warn("redmine 2.X")









return render_403 unless editable?
    was_new_page = @page.new_record?
    @page.content = WikiContent.new(:page => @page) if @page.new_record?
    @page.safe_attributes = params[:wiki_page]
 
    @page.content.versions.each do |v|
        if(v.text.strip.match(/^\{\{history\_coded\_start\}\}/) && v.text.strip.match(/\{\{history\_coded\_stop\}\}$/))
		#v.save()
	else
                v.comments = "["+v.updated_on.to_s+"] "+v.comments
        	v.text = encode(v.text.strip,params,1)
        	v.save()
 	end
    end



    @content = @page.content
    content_params = params[:content]
    if content_params.nil? && params[:wiki_page].is_a?(Hash)
      content_params = params[:wiki_page].slice(:text, :comments, :version)
    end
    content_params ||= {}

    @content.comments = content_params[:comments]
    @text = content_params[:text]
    if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
      @section = params[:section].to_i
      @section_hash = params[:section_hash]
      @content.text = Redmine::WikiFormatting.formatter.new(@content.text).update_section(params[:section].to_i, @text, @section_hash)
    else
      @content.version = content_params[:version] if content_params[:version]
      @content.text = @text
    end
    @content.author = User.current

    @content.text = encode(@content.text,params,0)

    if @page.save_with_content( @content )
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      call_hook(:controller_wiki_edit_after_save, { :params => params, :page => @page})

      respond_to do |format|
        format.html { redirect_to :action => 'show', :project_id => @project, :id => @page.title }
        format.api {
          if was_new_page
            render :action => 'show', :status => :created, :location => url_for(:controller => 'wiki', :action => 'show', :project_id => @project, :id => @page.title)
          else
            render_api_ok
          end
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@content) }
      end
    end

























    else


    return render_403 unless editable?
    @page.content = WikiContent.new(:page => @page) if @page.new_record?
    @page.safe_attributes = params[:wiki_page]

    @page.content.versions.each do |v|
        if(v.text.strip.match(/^\{\{history\_coded\_start\}\}/) && v.text.strip.match(/\{\{history\_coded\_stop\}\}$/))
		#v.save()
	else
                v.comments = "["+v.updated_on.to_s+"] "+v.comments
        	v.text = encode(v.text.strip,params,1)
        	v.save()
 	end
    end

    @content = @page.content_for_version(params[:version])
    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    if !@page.new_record? && params[:content].present? && @content.text == params[:content][:text]
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      # don't save content if text wasn't changed
      @page.save
      redirect_to :action => 'show', :project_id => @project, :id => @page.title
      return
    end

    @content.comments = params[:content][:comments]
    @text = params[:content][:text]
    if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
      @section = params[:section].to_i
      @section_hash = params[:section_hash]
      params[:decode]='1'
       decodedText = decodeContent(@content.text,params,1,0)
       decodedText2 = decodeContent(@text,params,1,0)
      @content.text = Redmine::WikiFormatting.formatter.new(decodedText).update_section(params[:section].to_i, decodedText2, @section_hash)
    else
      @content.version = params[:content][:version]
      @content.text = @text
    end
    @content.author = User.current
    @content.text = encode(@content.text,params,0)
    @page.content = @content
    if @page.save
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      call_hook(:controller_wiki_edit_after_save, { :params => params, :page => @page})
      redirect_to :action => 'show', :project_id => @project, :id => @page.title
    else
      render :action => 'edit'
    end


    end
  rescue ActiveRecord::StaleObjectError, Redmine::WikiFormatting::StaleSectionError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
    render :action => 'edit'
  end
   


  end
  end
