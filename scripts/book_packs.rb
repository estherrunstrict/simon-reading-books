#!/usr/bin/env ruby
# Gives every book in _data/roadmap.yml its own Pokémon card, in two different real booster packs, and writes
# _data/book_packs.yml. The reading page uses the first pack, or the second when the other book Simon
# picked for next already has that pack, so the two books he chooses between never share a pack.
#
#   ruby scripts/book_packs.rb
#
# Each card is a Special Illustration Rare Pokémon from the pack's set (_data/card_pools/<set>.json).
# Books next to each other in the roadmap get different packs. Cards set by hand in KEEP stay as they are.
require 'yaml'
require 'json'

ROOT = File.expand_path('..', __dir__)
KEEP = { 'syalrotui-geomijul' => 'sv1-243', 'nonriya-nolja' => 'sv3pt5-201' }.freeze
# Korean names (PokeAPI species names, the official Korean names).
KO = {
  'Spidops' => '트래피더', 'Miraidon' => '미라이돈', 'Gardevoir' => '가디안', 'Great Tusk' => '위대한엄니', 'Koraidon' => '코라이돈',
  'Iron Treads' => '무쇠바퀴', 'Meowscarada' => '마스카나', 'Wo-Chien' => '총지엔', 'Skeledirge' => '라우드본', 'Chi-Yu' => '위유이',
  'Quaquaval' => '웨이니발', 'Chien-Pao' => '파오젠', 'Tinkaton' => '두드리짱', 'Ting-Lu' => '딩루', 'Squawkabilly' => '시비꼬',
  'Eiscue' => '빙큐보', 'Charizard' => '리자몽', 'Revavroom' => '부르르룸', 'Pidgeot' => '피죤투', 'Venusaur' => '이상해꽃',
  'Blastoise' => '거북왕', 'Alakazam' => '후딘', 'Zapdos' => '썬더', 'Garchomp' => '한카리아스', 'Golisopod' => '갑주무사',
  'Tapu Koko' => '카푸꼬꼬꼭', 'Iron Hands' => '무쇠손', 'Iron Valiant' => '무쇠무인', 'Sandy Shocks' => '모래털가죽',
  'Roaring Moon' => '고동치는달', 'Gholdengo' => '타부자고', 'Altaria' => '파비코리', 'Iron Leaves' => '무쇠잎새',
  'Gouging Fire' => '꿰뚫는화염', 'Walking Wake' => '굽이치는물결', 'Iron Crown' => '무쇠감투', 'Iron Boulder' => '무쇠암석',
  'Raging Bolt' => '날뛰는우레', 'Sinistcha' => '그우린차', 'Ogerpon' => '오거폰', 'Greninja' => '개굴닌자', 'Ursaluna' => '다투곰',
  'Hydrapple' => '과미드라', 'Galvantula' => '전툴라', 'Dachsbun' => '바우첼', 'Terapagos' => '테라파고스', 'Durant' => '아이앤트',
  'Milotic' => '밀로틱', 'Pikachu' => '피카츄', 'Latias' => '라티아스', 'Hydreigon' => '삼삼드래', 'Archaludon' => '브리두라스',
  'Exeggutor' => '나시', 'Volcanion' => '볼케니온', 'Bellibolt' => '찌리배리', 'Clefairy' => '삐삐', 'Zoroark' => '조로아크',
  'Zacian' => '자시안', 'Salamence' => '보만다', 'Yanmega' => '메가자리', 'Moltres' => '파이어', 'Ho-Oh' => '칠색조',
  'Mewtwo' => '뮤츠', 'Nidoking' => '니드킹', 'Crobat' => '크로뱃', 'Mabosstiff' => '마피티프'
}.freeze
OWNER = { "Team Rocket's" => '로켓단의', "Iono's" => '모야모의', "Lillie's" => '릴리에의', "N's" => 'N의', "Hop's" => '호브의',
          "Ethan's" => '히비키의', "Cynthia's" => '난천의', "Arven's" => '페퍼의' }.freeze
FORM = { 'Teal Mask' => '벽록의가면', 'Hearthflame Mask' => '화덕의가면', 'Wellspring Mask' => '우물의가면',
         'Cornerstone Mask' => '주춧돌의가면', 'Bloodmoon' => '붉은달', 'Alolan' => '알로라' }.freeze

def korean(name)
  rest = name.sub(/ ex\z/, '')
  owner = OWNER.keys.find { |k| rest.start_with?("#{k} ") }
  rest = rest.delete_prefix("#{owner} ") if owner
  form = FORM.keys.find { |k| rest.start_with?("#{k} ") }
  rest = rest.delete_prefix("#{form} ") if form
  base = KO[rest] or abort "no Korean name for #{rest} (#{name}): add it to KO"
  base = form == 'Alolan' || form == 'Bloodmoon' ? "#{FORM[form]} #{base}" : form ? "#{base} #{FORM[form]}" : base
  [owner && OWNER[owner], base].compact.join(' ') + (name.end_with?(' ex') ? ' ex' : '')
end

packs = YAML.safe_load(File.read(File.join(ROOT, '_data/packs.yml'), encoding: 'UTF-8'))
pools = packs.to_h { |p| [p['id'], JSON.parse(File.read(File.join(ROOT, '_data/card_pools', "#{p['id']}.json")))] }
hits = pools.transform_values { |pl| pl['cards'].select { |c| c[2] == 'SIR' && c[3] == 'P' } }
roadmap = YAML.safe_load(File.read(File.join(ROOT, '_data/roadmap.yml'), encoding: 'UTF-8'))
books = roadmap.values.flat_map { |t| (t['must'] || []) + (t['better'] || []) }

def card_for(pack, row)
  set = pack['id']
  { 'tcg_id' => "#{set}-#{row[0]}", 'name' => row[1], 'name_ko' => korean(row[1]), 'set' => pack['name'] }
end

used = Hash.new(0)
ids = packs.map { |p| p['id'] }
out = {}
books.each_with_index do |b, i|
  first = i % ids.size
  keep = KEEP[b['slug']]
  first = ids.index(keep.split('-').first) if keep
  second = (first + 4) % ids.size
  out[b['slug']] = [first, second].map.with_index do |k, n|
    pack = packs[k]
    list = hits[pack['id']]
    free = list.reject { |c| KEEP.value?("#{pack['id']}-#{c[0]}") }
    row = n.zero? && keep ? list.find { |c| "#{pack['id']}-#{c[0]}" == keep } : free[used[pack['id']] % free.size]
    used[pack['id']] += 1 unless n.zero? && keep
    card_for(pack, row)
  end
end
File.write(File.join(ROOT, '_data/book_packs.yml'),
           "# 책마다 짝지은 카드와 팩 두 가지예요(scripts/book_packs.rb가 써요). 첫째를 쓰고, 다음 책으로 같이 고른 책이\n" \
           "# 같은 팩이면 둘째를 써요. 카드는 모두 그 팩 세트의 스페셜 일러스트 레어예요.\n" + out.to_yaml.sub(/\A---\n/, ''))
puts "#{out.size} books, #{used.values.sum + KEEP.size} cards from #{ids.size} packs"
