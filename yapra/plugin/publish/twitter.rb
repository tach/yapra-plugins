# yapla/plugin/filter/max.rb
# yapla plugin to filter a number of entries
#
# Example:
# - module: Publish::Twitter
#   config:
#     login: xxxxxx
#     password: xxx
#     check: 30##
#     prefix:
#
# Copyright (C) 2007 itoshi
# Copyright (C) 2009 Taku YASUI <tach@debian.org>
#
# You can use/modify/distribute under the same license of yapra.
# Please see the LICENSE file
#

begin
	require 'rubygems'
rescue LoadError
end
require 'twitter'
require 'kconv'

module Yapra::Plugin::Publish
	class Twitter
		def run(data)
			prefix = config['prefix'] || ''
			c = Twitter::Client.new(:login=>config["login"], :password=>config["password"])

			posts = c.timeline_for(:me,:count=>config["check"])
			posted_entries = posts.map do |post| post.text.gsub!(/ http.+$/, '') end

			data.reverse.each do |item|
				link  = item.link
				title = item.title.toutf8

				next if posted_entries.include? title

				comment = [prefix, title, link].join(' ')
				s = c.status(:post, comment)
			end

			return data
		end
	end
end

# vim: ts=2 sw=2 ft=ruby:
