require 'redmine'

require_dependency 'redmine_wikicipher/hooks'
require_dependency 'redmine_wikicipher/macros'
require_dependency 'redmine/wiki_formatting/textile/wikicipher_helper'

Redmine::Plugin.register :redmine_wikicipher do
  name 'Redmine Wikicipher plugin'
  author 'sleroux@keep.pt'
  author_url 'mailto:sleroux@keep.pt'
  description 'This plugin adds the ability to encrypt section of text'
  version '1.0.0'
  if Redmine::VERSION::MAJOR > 1
    raise Redmine::PluginRequirementError.new("redmine_wikicipher plugin requires Redmine 1.x but current is #{Redmine::VERSION}")
  end
end

