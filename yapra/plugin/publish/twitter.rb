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
	class Twitter < Yapra::Plugin::Base
		def run(data)
			prefix = config['prefix'] || ''

			hashtags = ''
			case config['hashtags'].class.to_s
			when 'String'
				hashtags = ' ' + config['hashtags']
			when 'Array'
				config['hashtags'].each do |s|
					s.match(/^#/) or s = '#' + s
					hashtags += ' ' + s
				end
			end

			c = ::Twitter::Client.new(
				:oauth_access => {
					'key' => config['access_key'],
					'secret' => config['access_secret'],
				},
				:oauth_consumer => {
					'key' => config['consumer_key'],
					'secret' => config['consumer_secret'],
				}
			)

			posts = c.timeline_for(:me,:count=>config["check"])
			posted_entries = posts.map do |post| post.text.gsub!(/ http.+\z/m, '') end
			posted_entries or return data

			data.reverse.each do |item|
				link  = item.link
				title = item.title.toutf8

				next if posted_entries.include? title

				comment = [prefix, title, link].join(' ')
				comment += hashtags
				s = c.status(:post, comment)
			end

			return data
		end
	end
end

# vim: ts=2 sw=2 ft=ruby:
