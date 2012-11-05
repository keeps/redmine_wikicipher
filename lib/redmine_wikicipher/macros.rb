module RedmineWikicipher
  module Macros
    Redmine::WikiFormatting::Macros.register do
      desc "Coded start tag"
      macro :coded_start do |obj, args|
        render :partial => "issues/redmine_wikicipher_start", :layout => false,
               :locals => { :title => args.first }
      end

      desc "Coded stop tag"
      macro :coded_stop do |obj, args|
        render :partial => "issues/redmine_wikicipher_end", :layout => false
      end


      desc "Decoded start tag"
      macro :decoded_start do |obj, args|
        render :partial => "issues/redmine_wikicipher2_start", :layout => false,
               :locals => { :title => args.first }
      end
      desc "Decoded stop tag"
      macro :decoded_stop do |obj, args|
        render :partial => "issues/redmine_wikicipher2_end", :layout => false
      end
    end
  end
end

