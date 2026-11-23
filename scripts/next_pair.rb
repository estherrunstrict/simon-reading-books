#!/usr/bin/env ruby
# Decides whether the next two books are due and which ones they are.
#
#   ruby scripts/next_pair.rb            prints JSON
#
# The pair in _data/weekly.yml is "done" when one of its books is in _books/ with
# status: finished and a finished date on or after weekly.proposed (the guardian's
# GitHub save from the home page writes that file). Then the next pair is:
#   1. the book Simon did not pick, if it is not on the shelf yet, and
#   2. the next book in _data/roadmap.yml for his grade, in the order
#      this grade's must -> next grade's must -> the grade after's must -> this grade's better.
# The new pair is shown from the Saturday after the finished date.
require 'yaml'
require 'json'
require 'date'

ROOT = File.expand_path('..', __dir__)
GRADES = %w[초5 초6 중1 중2 중3 고1 고2].freeze

def load_yaml(path)
  text = File.read(path, encoding: 'UTF-8')
  begin
    YAML.safe_load(text, permitted_classes: [Date, Time])
  rescue ArgumentError
    YAML.safe_load(text, [Date, Time])
  end
end

def front_matter(path)
  m = File.read(path, encoding: 'UTF-8').match(/\A---\s*\n(.*?)\n---/m)
  return nil unless m
  begin
    YAML.safe_load(m[1], permitted_classes: [Date, Time])
  rescue ArgumentError
    YAML.safe_load(m[1], [Date, Time])
  end
end

def norm(s)
  s.to_s.downcase.gsub(/[[:space:][:punct:]]/, '')
end

def to_date(v)
  v.is_a?(Date) ? v : Date.parse(v.to_s)
end

today = ARGV[0] ? Date.parse(ARGV[0]) : Date.today
weekly = load_yaml(File.join(ROOT, '_data/weekly.yml'))
roadmap = load_yaml(File.join(ROOT, '_data/roadmap.yml'))
books = Dir[File.join(ROOT, '_books/*.md')].map { |p| front_matter(p) }.compact
shelf_titles = books.map { |b| norm(b['title']) }

proposed = to_date(weekly['proposed'])
pair = weekly['books'] || []
done = books.find do |b|
  b['status'] == 'finished' && b['finished'] && to_date(b['finished']) >= proposed &&
    pair.any? { |p| norm(p['title']) == norm(b['title']) }
end

unless done
  puts JSON.pretty_generate(ready: false, reason: '이번 주에 고른 책이 아직 책장(_books)에 다 읽은 책으로 들어오지 않았어요.',
                            proposed: proposed.to_s, pair: pair.map { |p| p['title'] })
  exit 0
end

school_year = today.month >= 3 ? today.year : today.year - 1
idx = GRADES.index(weekly['grade']).to_i + (school_year - weekly['grade_year'].to_i)
idx = [[idx, 0].max, GRADES.size - 1].min
grade = GRADES[idx]

queue = []
[0, 1, 2].each { |k| g = GRADES[idx + k]; queue.concat((roadmap.dig(g, 'must') || []).map { |b| b.merge('tier' => "#{g} Must") }) if g }
queue.concat((roadmap.dig(grade, 'better') || []).map { |b| b.merge('tier' => "#{grade} Better") })
# When everything for this grade is read, keep going with the later grades' better lists.
GRADES[(idx + 1)..-1].each { |g| queue.concat((roadmap.dig(g, 'better') || []).map { |b| b.merge('tier' => "#{g} Better") }) }

taken = shelf_titles.dup
picks = []
other = pair.find { |p| norm(p['title']) != norm(done['title']) }
if other && !taken.include?(norm(other['title']))
  picks << other.merge('keep' => true)
  taken << norm(other['title'])
end
queue.each do |b|
  break if picks.size == 2
  next if taken.include?(norm(b['title']))
  picks << b.merge('keep' => false)
  taken << norm(b['title'])
end

finished_on = to_date(done['finished'])
saturday = finished_on + 1
saturday += 1 until saturday.saturday?
saturday += 7 while saturday < today

puts JSON.pretty_generate(ready: true, finished: done['title'], finished_on: finished_on.to_s, grade: grade,
                          proposed: saturday.to_s, books: picks)
