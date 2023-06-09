require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  # remove any non-numbers, including spaces, from the number
  number.gsub!(/[^0-9]/, '')

  # get length of string
  num_length = number.length

  # determine if number is good or bad
  if num_length < 10
    'Invalid Number'
  elsif num_length == 10
    number
  elsif num_length == 11 && number[0] == '1'
    number[1..10]
  elsif num_length == 11 && number[0] != '1'
    'Invalid Number'
  else
    'Invalid Number'
  end
end

def find_hour(time)
  begin
    Time.strptime(time, '%m/%d/%Y %k:%M').hour
  rescue
    'error'
  end
end

def find_day(day)
  begin
    Date.strptime(day, '%m/%d/%y %k:%M').wday
  rescue
    'error'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_hash = {}
day_hash = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  time = find_hour(row[:regdate])
  if hour_hash.key?(time)
    hour_hash[time] += 1
  else
    hour_hash[time] = 1
  end

  day = find_day(row[:regdate])
  if day_hash.key?(day)
    day_hash[day] += 1
  else
    day_hash[day] = 1
  end

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "By Hour:"
print hour_hash.sort_by { |_k, v| v }.reverse
puts "\nBy Day:"
print day_hash.sort_by { |_k, v| v }.reverse
