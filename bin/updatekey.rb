 #!/usr/bin/env ruby
require 'pg'
require 'digest'
require 'openssl'
require 'yaml'

def decrypt(text,key)
	e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
        e.decrypt key
        s = text.lines.to_a.pack("H*").unpack("C*").pack("c*")
        s = e.update s
        s << e.final
end

def encrypt(text,key)
	e = OpenSSL::Cipher::Cipher.new 'DES-EDE3-CBC'
	e.encrypt key
	s = e.update text
	s << e.final
	s.unpack('H*')[0].upcase
end

unless ARGV.length > 0
  puts "Usage: ruby updatekey.rb oldkey newkey\n"
  puts "       ruby updatekey.rb oldkey (to remove encryption)\n"
  exit
end



$VERBOSE=nil
originalkey=Digest::SHA256.hexdigest(ARGV[0])
newkey=nil

if ARGV[1].to_s.strip!=''
	newkey=Digest::SHA256.hexdigest(ARGV[1])
end

config = YAML.load_file("db.yaml")
@host = config["config"]["host"]
@port = config["config"]["port"]
@username = config["config"]["username"]
@password = config["config"]["password"]
@database = config["config"]["database"]

puts "New key provided. Updating encryption"
begin
	conn=PGconn.connect( :hostaddr=>@host, :port=>@port, :dbname=>@database, :user=>@username, :password=>@password)
	# updating wiki_contents table
	puts "UPDATING wiki_contents"
	res = conn.exec("SELECT id,text FROM wiki_contents")
	res.each{ |row|
		content = row["text"]
	    	id = row["id"]
		matches = content.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)
		matches.each do |m|
			tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
			decoded = decrypt(tagContent,originalkey)
			if newkey!=nil
				encoded = encrypt(decoded,newkey)
				encodedWithTags='{{coded_start}}'+encoded.strip+'{{coded_stop}}'
				content = content.gsub(m, encodedWithTags)
			else
				content = content.gsub(m, decoded)
			end
		end
		if newkey==nil
			content = content.gsub('{{cipher}}','')
		end
		conn.exec("UPDATE wiki_contents SET text='"+content+"' WHERE id="+id)
	}
	
	#updating wiki_content_versions table
	puts "UPDATING wiki_content_versions"
	res = conn.exec("SELECT id,encode(data,'escape') as text FROM wiki_content_versions")
	res.each{ |row|
		content = row["text"]
		id = row["id"]
		if content.strip.match(/^\{\{history\_coded\_start\}\}/m)
			matches1 = content.scan(/\{\{history\_coded\_start\}\}.*?\{\{history\_coded\_stop\}\}/m)
			matches1.each do |m1|
				historyContentCoded = m1.gsub('{{history_coded_start}}','').gsub('{{history_coded_stop}}','').strip
				historyContentDecoded = decrypt(historyContentCoded,originalkey)

				matches2 = historyContentDecoded.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)
				matches2.each do |m2|
					tagContentCoded = m2.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
					tagContentDecoded = decrypt(tagContentCoded,originalkey)
					if newkey!=nil
						tagContentRecoded = encrypt(tagContentDecoded,newkey)
						tagContentRecodedWithTags='{{coded_start}}'+tagContentRecoded.strip+'{{coded_stop}}'
						historyContentDecoded = historyContentDecoded.gsub(m2, tagContentRecodedWithTags)
					else
						historyContentDecoded = historyContentDecoded.gsub(m2, tagContentDecoded)
					end
	    			end
				if newkey!=nil
					historyContentRecoded = encrypt(historyContentDecoded,newkey)
					historyContentRecodedWithTags='{{history_coded_start}}'+historyContentRecoded.strip+'{{history_coded_stop}}'
					content = content.gsub(m1, historyContentRecodedWithTags)
				else
					content = content.gsub(m1, historyContentDecoded)
				end
				
	    		end
		else
			matches = content.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)
			matches.each do |m|
				tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
				decoded = decrypt(tagContent,originalkey)
				if newkey!=nil
					encoded = encrypt(decoded,newkey)
					encodedWithTags='{{coded_start}}'+encoded.strip+'{{coded_stop}}'
					content = content.gsub(m, encodedWithTags)
				else
					content = content.gsub(m, decoded)
				end
	    		end

		end
		if newkey==nil
			content = content.gsub('{{cipher}}','')
		end
	    	conn.exec("UPDATE wiki_content_versions SET data=decode('"+content+"','escape') WHERE id="+id)
	}
rescue OpenSSL::Cipher::CipherError => e 
	puts "Wrong key provided\n"
	puts e
end


