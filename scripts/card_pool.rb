#!/usr/bin/env ruby
# Writes the card list of a Pokémon TCG set to _data/card_pools/<set id>.json, so a booster pack on the
# reading page can draw its random cards from the real set. Only names, numbers and rarities are stored;
# the pictures stay on images.pokemontcg.io (https://images.pokemontcg.io/<set>/<number>.png).
#
#   ruby scripts/card_pool.rb sv1 sv3pt5
require 'json'
require 'net/http'
require 'uri'

ROOT = File.expand_path('..', __dir__)
# Short codes for the rarities the pack logic knows; anything else is left out of the pool.
CODES = {
  'Common' => 'C', 'Uncommon' => 'U', 'Rare' => 'R', 'Double Rare' => 'RR', 'Ultra Rare' => 'UR',
  'Illustration Rare' => 'IR', 'Special Illustration Rare' => 'SIR', 'Hyper Rare' => 'HR',
  'ACE SPEC Rare' => 'ACE', 'Rare Holo' => 'R'
}.freeze

def get(url)
  6.times do |i|
    res = Net::HTTP.get_response(URI(url)) rescue nil
    if res.is_a?(Net::HTTPSuccess) && !res.body.to_s.empty?
      begin
        return JSON.parse(res.body)
      rescue JSON::ParserError
        nil
      end
    end
    sleep(2 + i * 3)
  end
  abort "pokemontcg.io did not answer: #{url}"
end

ARGV.each do |set|
  cards = []
  page = 1
  loop do
    q = URI.encode_www_form(q: "set.id:#{set}", page: page, pageSize: 250, select: 'number,name,rarity,supertype')
    data = get("https://api.pokemontcg.io/v2/cards?#{q}")
    cards.concat(data['data'])
    break if cards.size >= data['totalCount'].to_i || data['data'].empty?
    page += 1
  end
  skipped = Hash.new(0)
  rows = cards.filter_map do |c|
    code = CODES[c['rarity']]
    next(skipped[c['rarity'].to_s] += 1) && nil unless code
    [c['number'], c['name'], code, c['supertype'] == 'Pokémon' ? 'P' : c['supertype'][0]]
  end
  rows.sort_by! { |r| [r[0].to_i, r[0]] }
  out = { 'set' => set, 'img' => "https://images.pokemontcg.io/#{set}/", 'cards' => rows }
  path = File.join(ROOT, '_data/card_pools', "#{set}.json")
  Dir.mkdir(File.dirname(path)) unless Dir.exist?(File.dirname(path))
  File.write(path, JSON.generate(out) + "\n")
  counts = rows.group_by { |r| r[2] }.transform_values(&:size)
  puts "#{set}: #{rows.size} cards #{counts}#{skipped.empty? ? '' : " (left out: #{skipped})"}"
end
