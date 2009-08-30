#!/usr/bin/ruby -Ku
#
# yapla/plugin/feed/fc_barcelona_jp_news.rb
# yapla plugin to fetch FC Barcelona Official Japanese News
#
# Example:
# - module: Feed::FCBarcelonaJPNews
#
# Copyright (C) 2009 Taku YASUI <tach@debian.org>
#
# You can use/modify/distribute under the same license of yapra.
# Please see the LICENSE file

require 'yapra/plugin/base'
require 'hpricot'
require 'rexml/document'
require 'kconv'
require 'open-uri'
require 'rss'

module Yapra::Plugin::Feed
	class FCBarcelonaJPNews < Yapra::Plugin::Base
		BASE_URI = 'http://www.fcbarcelona.jp/'
		CREATOR = 'FC Barcelona'

		def fetch_news_xml
			uri = URI.parse(BASE_URI)
			news_xml_uri = nil
			page = nil

			# read top page
			page = Hpricot(uri.read)

			# find news page
			(page/'#nav a').each do |a|
				if (NKF.nkf('-w', a.inner_html) == 'ニュース')
					@news_uri = URI.parse(a[:href].match(%r!^https?://!) ? a[:href] : BASE_URI + a[:href])
					news_xml_uri = @news_uri.clone
					news_xml_uri.path += 'news.xml'
				end
			end
			news_xml_uri or raise "Cannot find news link"

			# read xml file
			return news_xml_uri.read
		end

		def run(data)
			ret = []
			@news_uri = nil

			# parse XML and create RSS item
			doc = REXML::Document.new(fetch_news_xml)
			doc.elements.each('*//topic') do |topic|
				item = RSS::RDF::Item.new
				item.title = topic.get_elements('ttl').first.text
				uri = @news_uri.clone
				uri.path += '/' + topic.get_elements('url').first.text
				uri.path.gsub!(%r!/+!, '/')
				item.link = uri.to_s
				ret.push(item)
			end

			return ret
		end
	end
end

# vim: ts=2 sw=2 ft=ruby:
