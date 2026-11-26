#!/usr/bin/env ruby
# Sophia's cards: real Disney Lorcana cards, found with the lorcast.com API (no key).
#
#   ruby scripts/lorcana_cards.rb
#
# Writes into _kids/sophia/_data:
# - packs.yml: one real booster pack per Lorcana set (TCGplayer product id; the pack photo is hotlinked like Simon's).
# - card_pools/lor<N>.json: every card of the set, for opening a pack (pictures hotlinked from cards.lorcast.io).
# - book_packs.yml (when roadmap.yml exists): two Disney Princess cards per book from two different sets.
#   Must books get the rarest princess cards (iconic, enchanted, epic), Better books the next ones
#   (legendary, super rare, rare). No two books share their first card. Books next to each other get
#   different packs and different princesses. The second card is from another set, the same princess when there is one.
# Nothing is copied into the repository except these lists.
require 'json'
require 'yaml'
require 'net/http'

ROOT = File.expand_path('..', __dir__)
DATA = File.join(ROOT, '_kids/sophia/_data')
API = 'https://api.lorcast.com'
IMG = 'https://cards.lorcast.io/card/digital/'
# Lorcana set code => TCGplayer product id of its booster pack (tcgcsv.com, category 71).
SETS = { '1' => 482406, '2' => 516297, '3' => 531523, '4' => 543860, '5' => 555142, '6' => 578095, '7' => 607760,
         '8' => 623063, '9' => 649927, '10' => 652701, '11' => 664821, '12' => 678167, '13' => 690386, '14' => 706241 }.freeze
CODE = { 'Common' => 'C', 'Uncommon' => 'U', 'Rare' => 'R', 'Super_rare' => 'SR', 'Legendary' => 'L', 'Epic' => 'EP',
         'Enchanted' => 'E', 'Iconic' => 'IC' }.freeze
LABEL = { 'C' => '커먼', 'U' => '언커먼', 'R' => '레어', 'SR' => '슈퍼 레어', 'L' => '레전더리', 'EP' => '에픽', 'E' => '인챈티드',
          'IC' => '아이코닉' }.freeze
# The official Disney Princess line-up, with their Korean names.
KO = { 'Snow White' => '백설공주', 'Cinderella' => '신데렐라', 'Aurora' => '오로라', 'Ariel' => '아리엘', 'Belle' => '벨',
       'Jasmine' => '자스민', 'Pocahontas' => '포카혼타스', 'Mulan' => '뮬란', 'Tiana' => '티아나', 'Rapunzel' => '라푼젤',
       'Merida' => '메리다', 'Moana' => '모아나', 'Raya' => '라야', 'Belle & Beast' => '벨과 야수',
       'Pocahontas & Meeko' => '포카혼타스와 미코', 'Rapunzel & Flynn Rider' => '라푼젤과 플린 라이더' }.freeze
MUST = %w[IC E EP].freeze
BETTER = %w[L SR R].freeze

def get(path)
  10.times do |i|
    res = Net::HTTP.get_response(URI(API + path))
    return JSON.parse(res.body.force_encoding('UTF-8')) if res.is_a?(Net::HTTPSuccess)
    sleep 1 + i
  rescue StandardError
    sleep 1 + i
  end
  abort "lorcast: no answer for #{path}"
end

def pic(card, size) = card['image_uris']['digital'][size].sub(/\?.*\z/, '')

names = get('/v0/sets')['results'].to_h { |s| [s['code'], s['name']] }
packs = []
princesses = []
Dir.mkdir(File.join(DATA, 'card_pools')) unless Dir.exist?(File.join(DATA, 'card_pools'))
SETS.each do |code, product|
  id = "lor#{code}"
  cards = get("/v0/sets/#{code}/cards").select { |c| CODE[c['rarity']] }
  packs << { 'id' => id, 'name' => names[code], 'product' => product }
  rows = cards.map { |c| [c['collector_number'], [c['name'], c['version']].compact.join(' - '), CODE[c['rarity']], c['ink'].to_s, pic(c, 'normal')[%r{/(crd_[0-9a-f]+)\.avif}, 1]] }
  File.write(File.join(DATA, 'card_pools', "#{id}.json"), JSON.generate({ 'set' => id, 'game' => 'lorcana', 'img' => IMG, 'cards' => rows }) + "\n")
  cards.select { |c| KO[c['name']] }.each do |c|
    princesses << { 'tcg_id' => "#{id}-#{c['collector_number']}", 'name' => [c['name'], c['version']].compact.join(' - '),
                    'name_ko' => KO[c['name']], 'who' => c['name'].split(' & ').first, 'set' => names[code], 'set_id' => id,
                    'code' => CODE[c['rarity']], 'rarity_label' => LABEL[CODE[c['rarity']]],
                    'image' => pic(c, 'large'), 'image_small' => pic(c, 'normal') }
  end
end
File.write(File.join(DATA, 'packs.yml'),
           "# 소피아의 책마다 짝지어 주는 진짜 디즈니 로카나 부스터 팩이에요(scripts/lorcana_cards.rb가 써요).\n" \
           "# product는 TCGplayer 상품 번호예요. 팩 사진은 저장소에 복사하지 않고 바로 불러와요.\n" + packs.to_yaml.sub(/\A---\n/, ''))
puts "#{packs.size} packs, #{princesses.size} princess cards"

roadmap_file = File.join(DATA, 'roadmap.yml')
exit unless File.exist?(roadmap_file)
roadmap = YAML.safe_load(File.read(roadmap_file, encoding: 'UTF-8'))
books = roadmap.values.flat_map { |t| (t['must'] || []).map { |b| [b, MUST] } + (t['better'] || []).map { |b| [b, BETTER] } }
rank = %w[C U R SR L EP E IC]
used = {}
alt_used = Hash.new(0)
set_count = Hash.new(0)
recent = []
prev_set = nil
out = {}
strip = ->(c) { c.reject { |k, _| %w[who set_id code].include?(k) } }
books.each do |b, tiers|
  free = princesses.reject { |c| used[c['tcg_id']] }
  cands = free.select { |c| tiers.include?(c['code']) }
  cands = free.select { |c| rank.index(c['code']) >= rank.index('R') } if cands.empty?
  cands = free if cands.empty?
  first = cands.min_by do |c|
    [c['set_id'] == prev_set ? 1 : 0, recent.include?(c['who']) ? 1 : 0, set_count[c['set_id']], -rank.index(c['code']), c['tcg_id']]
  end
  used[first['tcg_id']] = true
  set_count[first['set_id']] += 1
  prev_set = first['set_id']
  recent = ([first['who']] + recent).first(3)
  others = princesses.reject { |c| c['set_id'] == first['set_id'] || used[c['tcg_id']] }
  second = others.min_by do |c|
    [alt_used[c['tcg_id']], c['who'] == first['who'] ? 0 : 1, (rank.index(c['code']) - rank.index(first['code'])).abs, c['tcg_id']]
  end
  alt_used[second['tcg_id']] += 1
  out[b['slug']] = [strip.(first), strip.(second)]
end
File.write(File.join(DATA, 'book_packs.yml'),
           "# 소피아의 책마다 짝지은 디즈니 프린세스 카드 두 장과 그 팩이에요(scripts/lorcana_cards.rb가 써요). 첫째를 쓰고,\n" \
           "# 다음 책으로 같이 고른 책이 같은 팩이면 둘째를 써요. Must는 아이코닉·인챈티드·에픽, Better는 레전더리·슈퍼 레어·레어예요.\n" +
           out.to_yaml.sub(/\A---\n/, ''))
puts "#{out.size} books, #{used.size} first cards, #{alt_used.size} second cards"
