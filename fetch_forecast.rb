#!/usr/bin/env ruby
# encoding: utf-8

require 'ostruct'
require 'json'
require 'open-uri'
require 'time'

# This Script checks weather forecast for today and emails to each recipient
# if weather is good for groundhandling
#
# Run this script at 06:00 every day via cronjob

HUMAN_BEARINGS = ["N", "NNO", "NO", "ONO", "O", "OSO", "SO", "SSO", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
WIND_RANGE = (14..25) # km/h
TIME_START = '09:00'
TIME_STOP = '22:00'
MAX_PRECIPITATION = 0.1 # mm/h
DEBUG = ARGV.include?('-d') || ARGV.include?('--debug')

CONFIG = JSON.parse(File.read("config.json"), symbolize_names: true)

ACTIVE_MONGO = ARGV.include?('--persist')
if ACTIVE_MONGO
  require 'mongo'
  Mongo::Logger.logger.level = Logger::WARN
  MONGODB_CLIENT = Mongo::Client.new([CONFIG[:db][:host]], CONFIG[:db])
end

API_KEY = CONFIG[:darksky_api_key]
LOCATIONS = CONFIG[:locations]
RECIPIENTS = CONFIG[:recipients]
ADMIN_EMAIL = CONFIG[:admin_email]

def fetch(lat, lon, api_key)
  time = Date.today.to_time.to_i
  url = "https://api.darksky.net/forecast/#{api_key}/#{lat},#{lon},#{time}?units=ca&lang=de&exclude=alerts"
  begin
    response = open(url).read.to_s
  rescue OpenURI::HTTPError => e
    sleep 10 # sleep 10 seconds and retry
    response = open(url).read.to_s
  end
  json = JSON.parse(response)
  json.merge!("_request" => {time: Time.now, lat: lat, lon: lon, api_key: api_key, url: url})

  if ACTIVE_MONGO
    mongo_result = MONGODB_CLIENT["darksky_forecast"].insert_one(json)
    abort("MongoDB error: #{mongo_result.documents}") unless mongo_result.n == 1
  end

  json
end

def human_bearing(bearing)
  HUMAN_BEARINGS[bearing / 22.5]
end

def convert(json)
  wind_speed = json['windSpeed']
  precipitation = json['precipIntensity']

  OpenStruct.new({
    time: Time.at(json['time']),
    clouds_eighth: (json['cloudCover']*8).round,
    wind_speed: wind_speed,
    wind_unit: 'km/h',
    wind_code: human_bearing(json['windBearing']),
    precipitation_value: precipitation,
    temp: json['temperature'],
    temp_unit: '°C',
    good: WIND_RANGE.include?(wind_speed) && precipitation <= MAX_PRECIPITATION
  })
end

def generate_mail(recipient)
  location = LOCATIONS[recipient[:location].to_sym]
  json = fetch(location[:lat], location[:long], API_KEY)

  location_name = location[:name]
  forecasts = json['hourly']['data'].map { |json| convert(json) }

  # today between 09:00-21:00 and sunrise-sunset
  start_time = [Time.parse(TIME_START), Time.at(json['daily']['data'][0]['sunriseTime'])].max
  end_time = [Time.parse(TIME_STOP), Time.at(json['daily']['data'][0]['sunsetTime'])].min
  todays = forecasts.select do |forecast|
    forecast.time.between?(start_time, end_time)
  end

  formatted_todays = todays.select(&:good).map do |forecast|
    status = forecast.good ? 'GUT' : 'schlecht'
    time = "#{forecast.time.strftime('%H:%M')}"
    wind = "#{forecast.wind_code.rjust(3)} #{forecast.wind_speed.round(0).to_s.rjust(2)} #{forecast.wind_unit}"
    clouds = "#{forecast.clouds_eighth}/8"
    precipitation = "#{(forecast.precipitation_value).round(2)} mm/h"

    temp_range = "#{forecast.temp.round(1).to_s.rjust(4)}#{forecast.temp_unit}"

    formatted_data = [wind, temp_range, clouds, precipitation]
    "#{time}: #{formatted_data.join(' | ')}"
  end

  if todays.any?(&:good) || DEBUG
    formatted_today = todays.first.time.strftime('%d.%m.%Y')
    name = recipient[:name]
    email = recipient[:email]

    lat = location[:lat]
    lon = location[:long]

    mail = <<-MAIL
To: #{email}
From: "Groundhandling Forecast" <#{ADMIN_EMAIL}>
Subject: Groundhandling am #{formatted_today}?
Auto-Submitted: auto-generated
Content-Type: text/plain; charset="utf-8"
MIME-Version: 1.0

Hallo #{name},

Lust auf Groundhandling in "#{location_name}"? Das heutige Wetter am #{formatted_today} könnte zu den folgenden Uhrzeiten geeignet sein:

#{formatted_todays.join("\n")}

#{location[:notice].chomp}
Windy: https://www.windy.com/?#{lat},#{lon},11
Air: https://www.meteoblue.com/de/wetter/vorhersage/air/#{lat},#{lon}

Die Vorhersage basiert auf diesen Bedingungen:
- Wind: #{WIND_RANGE.min} – #{WIND_RANGE.max} km/h
- max. Niederschlag: #{MAX_PRECIPITATION} mm/h
- Zeitraum: #{start_time.strftime('%H:%M')} – #{end_time.strftime('%H:%M')}
- Position: #{lat},#{lon}

Meteo-Quelle: https://darksky.net

Zitat des Tages: „Das Wetter wird auf dem Platz gemacht!“ – irgendein Fluglehrer

Dein Groundhandling Forecast Team

Diese Email wurde automatisch generiert. Bei Fragen/Anregungen/Beschwerden: Email an #{ADMIN_EMAIL}
    MAIL
    puts mail if DEBUG
    if !DEBUG
      `echo -n "#{mail}" | /usr/sbin/sendmail -t`
      exit 1 unless $?.success? # sends error mail via cronic
    end
  end
end


RECIPIENTS.select! { |r| r[:email] == ADMIN_EMAIL } if DEBUG
RECIPIENTS.each do |recipient|
  generate_mail(recipient)
end
