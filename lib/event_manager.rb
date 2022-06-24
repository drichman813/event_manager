require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

@hours_of_registration = Array.new()
@days_of_week_registration = Array.new()

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
    phone_number.delete!('^0-9')
    if phone_number.length == 10 
        phone_number
    elsif phone_number.length == 11
        if phone_number[0] == '1'
            phone_number.slice!(0)
        else
            phone_number = "Invalid phone number"
        end
    else
        phone_number = "Invalid phone number"
    end
end

def get_time(time_string)
    Time.strptime(time_string, "%m/%d/%y %H:%M")
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

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def get_most_used_registration_data(row)
    registration_time = get_time(row[:regdate])
    @hours_of_registration << registration_time.hour
    @days_of_week_registration << find_registration_day_of_week(registration_time)
end

def find_most_registered_hour(hours_array)
    hours_array
             .tally
             .sort{|a1,a2| a2[1]<=>a1[1]}
             .first
end

def find_most_registered_day(days_array)
    days_array
            .tally
            .sort{|a1,a2| a2[1]<=>a1[1]}
            .first
end

def find_registration_day_of_week(time)
    time.to_date.wday
end


puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


contents.each do |row|
  id = row[0]
  name = row[:first_name]

  phonenumber = clean_phone_number(row[:homephone])

  get_most_used_registration_data(row)

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts find_most_registered_hour(@hours_of_registration)
puts find_most_registered_day(@days_of_week_registration)
