#!/usr/bin/ruby -Ku
#
# yapla/plugin/feed/mixi_diary_list.rb
# yapla plugin to fetch user's diary list of Mixi
#
# Example:
# - module: Feed::MixiDiaryList
#   config:
#     email: username@example.com
#     password: your_password
#
# Copyright (C) 2009 Taku YASUI <tach@debian.org>
#
# You can use/modify/distribute under the same license of yapra.
# Please see the LICENSE file

require 'yapra/plugin/base'
require 'hpricot'
require 'kconv'
require 'open-uri'
require 'rss'
require 'mechanize'

WWW::Mechanize.html_parser = Hpricot

class WWW::Mixi
	URI_BASE = URI.parse('http://mixi.jp/')

	def initialize(options={})
		@email = options[:email] or raise "Specify Mixi email"
		@password = options[:password] or raise "Specify Mixi password"
		@https = options[:https]
		@agent = WWW::Mechanize.new
		@logged_in = false
	end

	def login
		@logged_in and return true

		uri = URI_BASE.dup
		@https and uri.scheme = 'https'
		page = @agent.get(uri)
		page.form_with(:name => 'login_form') do |form|
			form['email'] = @email
			form['password'] = @password
		end.submit
		@agent.cookie_jar.empty?(URI_BASE) and raise "Login failed"
		@logged_in = true
	end

	def fetch(path = '')
		@logged_in or login
		uri = URI_BASE.dup
		path.match(%r!^https?://!) ? uri = URI.parse(path) : uri.path = path
		@agent.get(uri)
	end

	attr_reader :email, :logged_in
end

module Yapra::Plugin::Feed
	class MixiDiaryList < Yapra::Plugin::Base
		def parse_date(str)
			Time.local(*str.scan(/(\d+)年(\d+)月(\d+)日(\d+):(\d+)/).flatten)
		end

		def run(data)
			ret = []
			@mixi = WWW::Mixi.new(:email => config['email'], :password => config['password'])
			page = @mixi.fetch('/list_diary.pl')
			(page/".listDiaryBlock").each do |diary|
				item = RSS::RDF::Item.new

				# pickup title and link
				(diary/'.listDiaryTitle a').each do |a|
					a[:href].match(%r!\bview_diary\.pl\b!) or next
					item.link = WWW::Mixi::URI_BASE.to_s + a[:href]
					item.title = a.inner_html
				end

				# pickup description
				(diary/'p').each do |descr|
					item.description = NKF.nkf('-w', descr.inner_html)
				end

				# pickup datetime
				(diary/'dd').each do |dd|
					item.date = parse_date(NKF.nkf('-w', dd.inner_html))
				end

				ret.push(item)
			end

			return ret
		end
	end
end

# vim: ts=2 sw=2 ft=ruby:
