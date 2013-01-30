require 'redmine'
# encoding: utf-8
module WikiPagePatch
	def self.included(base) # :nodoc:
		base.send(:include, InstanceMethods)
		base.class_eval do
			alias_method_chain :diff, :decryption
			alias_method_chain :annotate, :decryption
		end
  	end

  module InstanceMethods
    $key = Digest::SHA256.hexdigest(Redmine::Configuration['database_cipher_key'].to_s.strip)

    def decrypt(encodedContent)

		e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
		e.decrypt $key
		s = encodedContent.to_a.pack("H*").unpack("C*").pack("c*")
		s = e.update s
		decoded = s << e.final
		return decoded
	end



    def decodeContentWithTags(originalText)
		if Redmine::Configuration['database_cipher_key'].to_s.strip != ''
				matches = originalText.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)	
				matches.each do |m|
					tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
					decoded = decrypt(tagContent)
					decoded = '{{cipher}}'+decoded+'{{cipher}}'
					originalText = originalText.gsub(m.strip, decoded.strip)
				end
			end			
		return originalText
	end

    def decodeContent(originalText)
	matches = originalText.scan(/\{\{history\_coded\_start\}\}.*?\{\{history\_coded\_stop\}\}/m)	
	matches.each do |m|
		tagContent = m.gsub('{{history_coded_start}}','').gsub('{{history_coded_stop}}','').strip
		decoded = decrypt(tagContent)
		decoded = ''+decoded+''
		originalText = originalText.gsub(m.strip, decoded.strip)
	end
	originalText = decodeContentWithTags(originalText)
	return originalText
    end

    def annotate_with_decryption(version=nil)
     
    version = version ? version.to_i : self.content.version
    logger.warn('annotate version:'+version.to_s)
    c = content.versions.find_by_version(version)
    if c
	wa = WikiAnnotate.new(c)
        wa.lines.each do |line| 
            logger.warn(line)
            #line[2] = decodeContent(line[2])

	end
        wa
    else
	nil
    end
  end


    def diff_with_decryption(version_to=nil, version_from=nil)
	version_to = version_to ? version_to.to_i : self.content.version
    	version_from = version_from ? version_from.to_i : version_to - 1
    version_to, version_from = version_from, version_to unless version_from < version_to

    content_to = content.versions.find_by_version(version_to)
    content_from = content.versions.find_by_version(version_from)
    tempTo = WikiContent.new
    tempFrom = WikiContent.new
    tempTo.text = content_to.text
    tempTo.author = content_to.author
    tempFrom.text = content_from.text
    tempFrom.author = content_from.author
    tempFrom.id = content_from.id
    tempTo.id = content_to.id
    tempTo.page_id = content_to.page_id
    tempFrom.page_id = content_from.page_id
    tempTo.author_id = content_to.author_id
    tempFrom.author_id = content_from.author_id
    tempTo.comments = content_to.comments
    tempFrom.comments = content_from.comments
    tempTo.updated_on = content_to.updated_on
    tempFrom.updated_on = content_from.updated_on
    


    if(tempTo.text.strip.match(/^\{\{history\_coded\_start\}\}/m) && tempTo.text.strip.match(/\{\{history\_coded\_stop\}\}$/m))
	tempTo.text=decodeContent(tempTo.text)
    else
	tempTo.text=decodeContentWithTags(tempTo.text)
    end
    if(tempFrom.text.strip.match(/^\{\{history\_coded\_start\}\}/m) && tempFrom.text.strip.match(/\{\{history\_coded\_stop\}\}$/m))
	tempFrom.text=decodeContent(tempFrom.text)
    else
        tempFrom.text=decodeContentWithTags(tempFrom.text)
    end
    tempTo.version= content_to.version
    tempFrom.version=content_from.version
    (tempTo && tempFrom) ? WikiDiff.new(tempTo, tempFrom) : nil
    end
  end
end
