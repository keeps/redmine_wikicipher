#!/bin/env ruby
# encoding: utf-8

require 'redmine'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
require 'wiki_controller_patch'
require 'wiki_page_patch'
require_dependency 'redmine_wikicipher/hooks'
require_dependency 'redmine_wikicipher/macros'
require_dependency 'redmine/wiki_formatting/textile/wikicipher_helper'

Redmine::Plugin.register :redmine_wikicipher do
  name 'Redmine Wikicipher plugin'
  author 'Sébastien Leroux'
  author_url 'mailto:sleroux@keep.pt'
  description 'This plugin adds the ability to encrypt section of text'
  version '0.0.7'
  url 'https://github.com/keeps/redmine_wikicipher'
end



if Rails::VERSION::MAJOR >= 3
	ActionDispatch::Callbacks.to_prepare do
		require_dependency 'wiki_controller'
         	require_dependency 'wiki_page'
  		WikiController.send(:include, WikiControllerPatch)
  		WikiPage.send(:include, WikiPagePatch)
	end
else
	ApplicationController.class_eval do
		filter_parameter_logging :password, :text
	end
	Dispatcher.to_prepare do
		require_dependency 'wiki_controller'
         	require_dependency 'wiki_page'
  		WikiController.send(:include, WikiControllerPatch)
  		WikiPage.send(:include, WikiPagePatch)
	end

end




