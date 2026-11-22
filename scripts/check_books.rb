#!/usr/bin/env ruby
# Checks the front matter of every _books/*.md file against the shape that
# _layouts/book.html, index.html and assets/readcheck.js rely on.
#
#   ruby scripts/check_books.rb              all books
#   ruby scripts/check_books.rb path.md ...  only these files
#
# Exits 1 when any file has an error. Warnings do not change the exit code.

require 'yaml'
require 'date'

ROOT = File.expand_path('..', __dir__)

FIELDS = %w[title author status rating genre pages started finished summary quote cover isbn structure published quiz layout].freeze
STRUCTURES = %w[mountain three map].freeze
REQUIRED = %w[title author status summary].freeze

def load_yaml(text)
  YAML.safe_load(text, permitted_classes: [Date, Time])
rescue ArgumentError
  YAML.safe_load(text, [Date, Time])
end

def front_matter(path)
  text = File.read(path, encoding: 'UTF-8')
  match = text.match(/\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\z)/m)
  return [nil, '맨 위에 --- 로 감싼 front matter가 없어요'] unless match

  data = load_yaml(match[1])
  data.is_a?(Hash) ? [data, nil] : [nil, 'front matter가 key: value 목록이 아니에요']
rescue Psych::Exception => e
  [nil, "YAML을 읽지 못했어요 (#{e.message})"]
rescue SystemCallError => e
  [nil, "파일을 읽지 못했어요 (#{e.message})"]
end

def text?(value)
  value.is_a?(String) && !value.strip.empty?
end

def date?(value)
  return true if value.is_a?(Date) || value.is_a?(Time)

  value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/) && !Date.strptime(value, '%Y-%m-%d').nil?
rescue ArgumentError
  false
end

def show(value)
  value.inspect
end

def quiz_errors(quiz)
  return ['quiz: 질문 목록이어야 하고 하나 이상 있어야 해요'] unless quiz.is_a?(Array) && !quiz.empty?

  quiz.each_with_index.flat_map do |item, i|
    at = "quiz #{i + 1}번"
    next ["#{at}: q, choices, answer가 있는 항목이어야 해요"] unless item.is_a?(Hash)

    errors = []
    errors << "#{at}: q(질문)를 글로 적어야 해요" unless text?(item['q'])
    choices = item['choices']
    if !choices.is_a?(Array) || choices.size < 2 || !choices.all? { |c| text?(c) }
      errors << "#{at}: choices(보기)는 2개 이상의 글이어야 해요. 숫자나 yes, no는 따옴표로 감싸세요"
    elsif !item['answer'].is_a?(Integer) || !(1..choices.size).cover?(item['answer'])
      errors << "#{at}: answer(정답 번호)는 1부터 #{choices.size} 사이의 정수여야 해요 (지금 값 #{show(item['answer'])})"
    end
    errors << "#{at}: why(설명)는 글이어야 해요" if item.key?('why') && !text?(item['why'])
    unknown = item.keys - %w[q choices answer why]
    errors << "#{at}: 모르는 항목이에요 (#{unknown.join(', ')})" unless unknown.empty?
    errors
  end
end

def book_errors(data, shelf_keys)
  errors = []
  (data.keys - FIELDS).each { |k| errors << "#{k}: 모르는 항목이에요. 철자를 확인해 주세요" }
  REQUIRED.each { |k| errors << "#{k}: 꼭 필요해요" unless text?(data[k]) }

  if data.key?('status') && !shelf_keys.include?(data['status'])
    errors << "status: #{show(data['status'])}는 책장 이름이 아니에요. #{shelf_keys.join(', ')} 중 하나여야 해요"
  end
  if data.key?('rating') && !(data['rating'].is_a?(Integer) && (1..5).cover?(data['rating']))
    errors << "rating: 1부터 5 사이의 정수여야 해요 (지금 값 #{show(data['rating'])})"
  end
  if data.key?('pages') && !(data['pages'].is_a?(Integer) && data['pages'] > 0)
    errors << "pages: 0보다 큰 정수여야 해요 (지금 값 #{show(data['pages'])})"
  end
  %w[genre quote].each do |k|
    errors << "#{k}: 글이어야 해요" if data.key?(k) && !text?(data[k])
  end
  if data.key?('cover') && !(data['cover'].is_a?(String) && data['cover'].match?(%r{\Ahttps://\S+\z}))
    errors << "cover: https://로 시작하는 그림 주소여야 해요 (지금 값 #{show(data['cover'])})"
  end
  if data.key?('isbn') && !(data['isbn'].is_a?(String) && data['isbn'].match?(/\A[0-9X-]{10,17}\z/))
    errors << "isbn: 따옴표로 감싼 ISBN 숫자여야 해요 (지금 값 #{show(data['isbn'])})"
  end
  if data.key?('structure') && !STRUCTURES.include?(data['structure'])
    errors << "structure: #{STRUCTURES.join(', ')} 중 하나여야 해요 (지금 값 #{show(data['structure'])})"
  end
  %w[started finished].each do |k|
    errors << "#{k}: YYYY-MM-DD 날짜여야 해요 (지금 값 #{show(data[k])})" if data.key?(k) && !date?(data[k])
  end
  errors << 'published: true 또는 false여야 해요' if data.key?('published') && ![true, false].include?(data['published'])
  errors.concat(quiz_errors(data['quiz'])) if data.key?('quiz')
  errors
end

def book_warnings(data)
  return [] unless data['status'] == 'finished' && !data['finished']

  ['finished: 다 읽은 책인데 다 읽은 날이 없어서 올해 목표 숫자에 세지 않아요']
end

shelf_keys = YAML.load_file(File.join(ROOT, '_data', 'shelves.yml')).map { |s| s['key'] }
files = ARGV.empty? ? Dir[File.join(ROOT, '_books', '*.md')].sort : ARGV
failed = 0

files.each do |path|
  name = path.start_with?(ROOT + '/') ? path.sub(ROOT + '/', '') : path
  data, problem = front_matter(path)
  errors = problem ? [problem] : book_errors(data, shelf_keys)
  errors.each { |e| puts "#{name}: #{e}" }
  book_warnings(data || {}).each { |w| puts "#{name}: 주의 #{w}" }
  failed += 1 unless errors.empty?
end

if failed.zero?
  puts "통과: 책 #{files.size}권을 확인했어요"
else
  puts "실패: 책 #{files.size}권 중 #{failed}권에 문제가 있어요"
  exit 1
end
