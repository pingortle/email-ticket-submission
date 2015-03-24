require 'sinatra'
require 'mail'
require 'rest_client'
require 'sass/plugin/rack'

require './env' if File.exists? 'env.rb'
CAPTCHA_USERNAME = ENV['CAPTCHA_USERNAME']
CAPTCHA_SECRET = ENV['CAPTCHA_SECRET']
MAILGUN_KEY = ENV['MAILGUN_KEY']
MAILGUN_SUBDOMAIN = ENV['MAILGUN_SUBDOMAIN']
TICKETS_EMAIL_ADDRESS = ENV['TICKETS_EMAIL_ADDRESS']
LOGO_URL = ENV['LOGO_URL']
LOGO_URL_2X = ENV['LOGO_URL_2X']

require './captcha'

use Sass::Plugin::Rack

enable :sessions

configure do
  use Rack::Static,
      urls: ['/stylesheets'],
      root: File.expand_path('../tmp', __FILE__)

  Sass::Plugin.options.merge!(template_location: 'public/stylesheets/sass',
                              css_location: 'tmp/stylesheets')
end

get '/' do
  random = rand(36**16).to_s(36)
  session[:random] = random
  haml :index, :format => :html5, :locals => {:random => random}
end

post '/' do
  random = session[:random]
  halt(403, haml(:failure, :format => :html5)) if Captcha.get_text(CAPTCHA_SECRET, random) != params["captcha"]
  email = params[:email]
  name = params[:name]

  html_body = haml(:email_template, :locals => {:data => params})

  key = MAILGUN_KEY
  subdomain = MAILGUN_SUBDOMAIN
  tickets_email = TICKETS_EMAIL_ADDRESS
  RestClient.post "https://api:#{key}@api.mailgun.net/v2/#{subdomain}/messages",
    :from => "#{name} <#{email}>",
    :to => tickets_email,
    :subject => "New Ticket",
    :html => html_body

  haml :success, :format => :html5
end
