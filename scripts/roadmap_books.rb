#!/usr/bin/env ruby
# Looks up every book in _data/roadmap.yml on Aladin and writes what the site needs to show it:
#
#   ruby scripts/roadmap_books.rb [--refresh] [slug ...]
#
# For each book: the cover (saved as assets/covers/<slug>.webp, 400 px wide), ISBN-13, page count and
# size in mm, kept in _data/book_meta.yml. Books already in that file are skipped unless --refresh or
# their slug is named. Needs cwebp (brew install webp). Aladin answers plain HTTP requests, so no browser.
require 'yaml'
require 'net/http'
require 'uri'
require 'cgi'
require 'tmpdir'

ROOT = File.expand_path('..', __dir__)
META = File.join(ROOT, '_data/book_meta.yml')
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15'

def get(url, tries = 3)
  uri = URI(url)
  tries.times do |i|
    begin
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 20) do |h|
        h.get(uri.request_uri, 'User-Agent' => UA, 'Accept-Language' => 'ko-KR,ko')
      end
      return get(URI.join(url, res['location']).to_s, tries) if res.is_a?(Net::HTTPRedirection)
      return res.body.force_encoding('UTF-8') if res.is_a?(Net::HTTPSuccess)
    rescue StandardError
      nil
    end
    sleep 1.5 * (i + 1)
  end
  nil
end

def norm(s)
  CGI.unescapeHTML(s.to_s).downcase.gsub(/[[:space:][:punct:]·ㆍ‧]/, '')
end

def strip_tags(s)
  CGI.unescapeHTML(s.to_s.gsub(/<[^>]+>/, ' ')).gsub(/\s+/, ' ').strip
end

def candidates(html)
  html.to_s.split('<div class="ss_book_box"').drop(1).map do |box|
    cat = box[/class="tit_category">\[([^\]]+)\]/, 1].to_s
    title = strip_tags(box[/class="bo3">(.*?)<\/a>/m, 1])
    id = box[/ItemId=(\d+)/, 1]
    lines = box.scan(/<li>(.*?)<\/li>/m).map { |m| strip_tags(m[0]) }
    who = lines.find { |l| l.match?(/\((지은이|글|엮은이|원작)\)|\|\s*\d{4}년/) && !l.include?(title + ' (') }.to_s
    sales = box[/sales_point">\s*([\d,]+)/, 1].to_s.delete(',').to_i
    { id: id, cat: cat, title: title, who: who, sales: sales }
  end
end

def pick(cands, book)
  want = norm(book['title'])
  author = book['author'].to_s.split(/[ .]/).reject(&:empty?)
  ok = cands.select do |c|
    c[:id] && c[:cat] == '국내도서' && !c[:title].match?(/세트|전\s*\d+권|eBook|오디오북|큰글|워크북|활동지|만화/) &&
      norm(c[:title]).start_with?(want) && (author.empty? || author.any? { |a| c[:who].include?(a) } || book['publisher'].to_s.include?('번역'))
  end
  ok = cands.select { |c| c[:id] && c[:cat] == '국내도서' && norm(c[:title]).start_with?(want) } if ok.empty?
  pub = norm(book['publisher'])
  ok.max_by { |c| [!pub.empty? && norm(c[:who]).include?(pub) ? 1 : 0, c[:sales]] }
end

refresh = ARGV.delete('--refresh')
only = ARGV
roadmap = YAML.safe_load(File.read(File.join(ROOT, '_data/roadmap.yml'), encoding: 'UTF-8'))
meta = File.exist?(META) ? (YAML.safe_load(File.read(META, encoding: 'UTF-8')) || {}) : {}
books = roadmap.values.flat_map { |t| (t['must'] || []) + (t['better'] || []) }
tmp = Dir.mktmpdir('covers')
missing = []
books.each do |b|
  slug = b['slug']
  next if meta[slug] && !refresh && !only.include?(slug)
  next unless only.empty? || only.include?(slug)
  q = "#{b['title']} #{b['author'].to_s.split(/[ .]/).last}"
  q += " #{b['publisher']}" unless b['publisher'].to_s.include?('번역')
  html = get("https://www.aladin.co.kr/search/wsearchresult.aspx?SearchTarget=Book&SearchWord=#{CGI.escape(q)}")
  c = pick(candidates(html), b)
  unless c
    html = get("https://www.aladin.co.kr/search/wsearchresult.aspx?SearchTarget=Book&SearchWord=#{CGI.escape(b['title'])}")
    c = pick(candidates(html), b)
  end
  unless c
    missing << b['title']; warn "  no match: #{b['title']}"; next
  end
  page = get("https://www.aladin.co.kr/shop/wproduct.aspx?ItemId=#{c[:id]}").to_s
  text = strip_tags(page)
  cover = page[/property="og:image" content="([^"]+)"/, 1]
  isbn = text[/ISBN\s*:?\s*(97[89]\d{10})/, 1] || page[/(97[89]\d{10})/, 1]
  pages = text[/(\d{2,4})쪽/, 1]
  dims = text.match(/(\d{2,3})\s*\*\s*(\d{2,3})\s*(?:\*\s*(\d{1,3}))?\s*mm/)
  size = dims ? [dims[1].to_i, dims[2].to_i, (dims[3] || (pages.to_i / 14).clamp(6, 40)).to_i] : nil
  out = File.join(ROOT, 'assets/covers', "#{slug}.webp")
  if cover && (!File.exist?(out) || refresh || only.include?(slug))
    jpg = File.join(tmp, "#{slug}.jpg")
    data = get(cover)
    if data && data.bytesize > 2000
      File.binwrite(jpg, data)
      system('cwebp', '-quiet', '-q', '85', '-resize', '400', '0', jpg, '-o', out) || warn("  cwebp failed: #{slug}")
    end
  end
  meta[slug] = {
    'aladin' => c[:id].to_i, 'aladin_title' => c[:title], 'isbn' => isbn, 'pages' => pages&.to_i, 'size_mm' => size,
    'cover' => File.exist?(out) ? "/assets/covers/#{slug}.webp" : nil
  }.compact
  puts "#{b['title']} -> #{c[:title]} (#{isbn}, #{pages}쪽, #{size&.join('x')})"
  File.write(META, "# _data/roadmap.yml 책마다 알라딘에서 찾은 표지·ISBN·쪽수·크기예요. scripts/roadmap_books.rb가 써요.\n" +
                   meta.to_yaml.sub(/\A---\n/, ''))
  sleep 0.6
end
puts "#{meta.size}/#{books.size} books have data" + (missing.empty? ? '' : "; no match: #{missing.join(', ')}")
