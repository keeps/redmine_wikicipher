 #!/usr/bin/env ruby
require 'redmine'
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

if newkey!=nil
	begin
		conn=PGconn.connect( :hostaddr=>@host, :port=>@port, :dbname=>@database, :user=>@username, :password=>@password)
		# run the query
		res = conn.exec("SELECT id,text FROM wiki_contents")
		res.each{ |row|
		    content = row["text"]
		    id = row["id"]
		    matches = content.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)
		    matches.each do |m|
			tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
			puts "CODED:"+tagContent
			decoded = decrypt(tagContent,originalkey)
			puts "DECODED:"+tagContent
			encoded = encrypt(decoded,newkey)
			puts "RECODED:"+tagContent
			puts "-------------------------------------"
			encodedWithTags='{{coded_start}}'+encoded.strip+'{{coded_stop}}'
			content = content.gsub(m, encodedWithTags)
		    end
		    conn.exec("UPDATE wiki_contents SET text='"+content+"' WHERE id="+id)
		}
	rescue OpenSSL::Cipher::CipherError
		puts "Wrong key provided\n"
	end
else
	begin
		conn=PGconn.connect( :hostaddr=>@host, :port=>@port, :dbname=>@database, :user=>@username, :password=>@password)
		# run the query
		res = conn.exec("SELECT id,text FROM wiki_contents")
		res.each{ |row|
		    content = row["text"]
		    id = row["id"]
		    matches = content.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)
		    matches.each do |m|
			tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
			puts "CODED:"+tagContent
			decoded = decrypt(tagContent,originalkey)
			puts "DECODED:"+decoded
			puts "-------------------------------------"
			content = content.gsub(m, decoded)
		    end
		    conn.exec("UPDATE wiki_contents SET text='"+content+"' WHERE id="+id)
		}
	rescue OpenSSL::Cipher::CipherError
		puts "Wrong key provided\n"
	end
end



