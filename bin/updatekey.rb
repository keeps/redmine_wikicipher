 #!/usr/bin/env ruby

require 'pg'
require 'digest'
require 'openssl'

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

unless ARGV.length == 2
  puts "Usage: ruby updatekey.rb oldkey newkey\n"
  exit
end

conn=PGconn.connect( :hostaddr=>"127.0.0.1", :port=>5432, :dbname=>"redmine", :user=>"redmine", :password=>'my_password')
puts conn.internal_encoding
# run the query
res = conn.exec("SELECT id,text FROM wiki_contents")

originalkey=Digest::SHA256.hexdigest(ARGV[0])
newkey=Digest::SHA256.hexdigest(ARGV[1])

res.each{ |row|
    content = row["text"]
    id = row["id"]
    puts "CONTENT:"+content
    puts "ID:"+id
    matches = content.scan(/\{\{coded\_start\}\}.*?\{\{coded\_stop\}\}/m)
    matches.each do |m|
        tagContent = m.gsub('{{coded_start}}','').gsub('{{coded_stop}}','').strip
        puts "TAG CONTENT:"+tagContent
        decoded = decrypt(tagContent,originalkey)
	encoded = encrypt(decoded,newkey)
        encodedWithTags='{{coded_start}}'+encoded.strip+'{{coded_stop}}'
        content = content.gsub(m, encodedWithTags)
    end
    conn.exec("UPDATE wiki_contents SET text='"+content+"' WHERE id="+id)
}



