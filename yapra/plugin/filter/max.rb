# yapla/plugin/filter/max.rb
# yapla plugin to filter a number of entries
#
# Example:
# - module: Filter::Max
#   config:
#     max: 10
#
# Copyright (C) 2009 Taku YASUI <tach@debian.org>
#
# You can use/modify/distribute under the same license of yapra.
# Please see the LICENSE file

require 'yapra/plugin/base'

module Yapra::Plugin::Filter
	class Max < Yapra::Plugin::Base
		def run(data)
			data[0, config['max'] || data.size]
		end
	end
end

# vim: ts=2 sw=2 ft=ruby:
