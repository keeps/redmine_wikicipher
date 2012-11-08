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

  module InstanceMethods
	def encodeContent(originalText,params)
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

      		return originalText
	end
	def decodeContentWithTags(originalText,params)
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
	
			
				return originalText
			end
	end
	def decodeContentExport(originalText,params)
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
			end
	return originalText
	end
	def decodeContent(originalText,params)
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
    @content.text = decodeContent(@content.text,params);
    if User.current.allowed_to?(:export_wiki_pages, @project)
      if params[:format] == 'pdf'
	params[:decode]='1'
         @content.text = decodeContentExport(@content.text,params);
        send_data(wiki_page_to_pdf(@page, @project), :type => 'application/pdf', :filename => "#{@page.title}.pdf")
        return
      elsif params[:format] == 'html'
	params[:decode]='1'
	@content.text = decodeContentExport(@content.text,params);
        export = render_to_string :action => 'export', :layout => false
        send_data(export, :type => 'text/html', :filename => "#{@page.title}.html")
        return
      elsif params[:format] == 'txt'
	params[:decode]='1'
	@content.text = decodeContentExport(@content.text,params);
        send_data(@content.text, :type => 'text/plain', :filename => "#{@page.title}.txt")
        return
      end
    end
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
    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    # To prevent StaleObjectError exception when reverting to a previous version
    @content.version = @page.content.version
    params[:decode]='1'
    @content.text = decodeContentWithTags(@content.text,params)

    @text = @content.text
    if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
      @section = params[:section].to_i
      @text, @section_hash = Redmine::WikiFormatting.formatter.new(@text).get_section(@section)
      render_404 if @text.blank?
    end
end

def update_with_encryption
    return render_403 unless editable?
    @page.content = WikiContent.new(:page => @page) if @page.new_record?
    @page.safe_attributes = params[:wiki_page]

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
      @content.text = Redmine::WikiFormatting.formatter.new(@content.text).update_section(params[:section].to_i, @text, @section_hash)
    else
      @content.version = params[:content][:version]
      @content.text = @text
    end
    @content.author = User.current
    @content.text = encodeContent(@content.text,params)
    @page.content = @content
    if @page.save
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      call_hook(:controller_wiki_edit_after_save, { :params => params, :page => @page})
      redirect_to :action => 'show', :project_id => @project, :id => @page.title
    else
      render :action => 'edit'
    end

  rescue ActiveRecord::StaleObjectError, Redmine::WikiFormatting::StaleSectionError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
    render :action => 'edit'
  end
   


  end
  end
