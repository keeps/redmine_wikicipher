module Redmine
  module WikiFormatting
    module Textile
      module Helper

        def heads_for_wiki_formatter_with_wikicipher
          heads_for_wiki_formatter_without_wikicipher
          unless @heads_for_wiki_formatter_with_wikicipher_included
            content_for :header_tags do
              javascript_include_tag('jstoolbar/wikicipher', :plugin => 'redmine_wikicipher') +
              javascript_include_tag("jstoolbar/lang/wikicipher-#{current_language.to_s.downcase}", :plugin => 'redmine_wikicipher') +
              stylesheet_link_tag('jstoolbar_wikicipher', :plugin => 'redmine_wikicipher')
            end
            @heads_for_wiki_formatter_with_wikicipher_included = true
          end
        end

        alias_method_chain :heads_for_wiki_formatter, :wikicipher

      end
    end
  end
end
