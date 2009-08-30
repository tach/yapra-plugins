require 'yapra/plugin/base'
require 'hpricot'
require 'kconv'
require 'open-uri'
require 'rss'

module Yapra::Plugin::Filter
  class FCBotigaNew < Yapra::Plugin::Base
    BASE_URL = 'http://www.fcbotiga.jp/fcb/'
    CREATOR = 'FCBOTIGA'

    def run(data)
      ret = []

      data.each do |str|
        doc = Hpricot(str)
        rss = RSS::Maker.make("1.0")
        urls = {}
        doc.search("//table[@width='620']").each do |table|

          # get release date
          date = nil
          table.search("//tr/td/p/strong/font") do |title|
            m, d, = title.inner_html.scan(/(\d+)月(\d+)日/u).flatten
            m && d or next
            date = Time.local(Time.now.year, m.to_i, d.to_i)
            if (date > Time.now)
              date = Time.local(Time.now.year - 1, m.to_i, d.to_i)
            end
          end
          date or next

          # get item descriptions
          table.search("//a") do |a|
            href = BASE_URL + a['href']
            urls[href] and next
            urls[href] = true
            page = Hpricot(open(href).read.toutf8)
            item = RSS::RDF::Item.new
            item.title = page.at("title").inner_html.split("｜").first
            item.date = date
            item.link = href
            item.dc_creator = CREATOR
            page.search("//table[@width='580']") do |desc|
              base = File.dirname(href)
              desc.search("//img") do |img|
                img["src"] =~ %r!^https?://! or img["src"] = File.join(base, img["src"])
                p img["src"]
              end
              item.description = desc.to_s
            end
            ret.push(item)
          end
        end
      end

      return ret
    end
  end
end

# vim: ts=2 sw=2 et ft=ruby:
