require 'sinatra/base'

require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'

require 'tinder'

## -- DATABASE STUFF --

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/local.db")

class Team
  include DataMapper::Resource
  has n, :sponsors

  property :id,         Serial
  property :name,       String, :required => true, :message => "Cmon, you need a team name"
  property :company,    String, :required => true, :message => "Needs a company name"
  property :charity,    String, :required => true, :message => "You gotta play for a charity, my friend"
  property :charity_url,  String
  property :github,       String
  property :twitter,      String
  property :image,        Text
  property :donation,     Integer, :default => 3000
  property :sponsored,    Integer
  property :cool,         Boolean, :default => false
  property :pledge,       Boolean, :default => false, :required => true, :message => "You need to pledge to donate, baby"
  property :owner,        String
  property :email,        String, :required => true, :message => "We need an email address to set up the donation"
  property :player_1,     String
  property :player_2,     String
  property :player_3,     String
  property :player_4,     String
  property :player_5,     String
  property :player_6,     String
  property :player_7,     String
  property :player_8,     String
  property :updated_at,   DateTime

  def players
    [player_1, player_2, player_3, player_4, player_5, player_6, player_7, player_8].uniq.reject { |a| a == '' }
  end

  def team_image(size = 100)
    if (!image || image == '')
      img = "https://a248.e.akamai.net/assets.github.com/images/gravatars/gravatar-140.png"
    else
      img = image
    end
    "<img height=\"#{size}\" width=\"#{size}\" src=\"#{img}\"/>"
  end
end

class Sponsor
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String
  property :amount,     Integer
  property :github,     String
  property :twitter,    String
end

DataMapper.auto_upgrade!

class Dodgeball < Sinatra::Base
  enable :sessions
  set :session_secret, "8c23f5ecdef9c54b81244e5426727279"

  def notify_campfire(team)
    hubot = Tinder::Campfire.new ENV['CF_GROUP'], :token => ENV['CF_TOKEN']
    room = hubot.find_room_by_name(ENV['CF_ROOM'])
    room.speak "new dodgeball signup: #{team.name} of #{team.company}"
  end

  def get_data
    @teams = Team.all(:cool => true)
    @pot = 0
    @teams.each do |team|
      @pot += team.donation
    end
  end

  def fill_team(team, params)
    team.name = params['team-name']
    team.company  = params['company-name']
    team.charity  = params['charity-name']
    team.charity_url = params['charity-url']
    team.twitter  = params['company-twitter']
    team.email    = params['contact-email']
    team.image    = params['team-image']
    team.player_1 = params['player-1']
    team.player_2 = params['player-2']
    team.player_3 = params['player-3']
    team.player_4 = params['player-4']
    team.player_5 = params['player-5']
    team.player_6 = params['player-6']
    team.player_7 = params['player-7']
    team.player_8 = params['player-8']
  end

  helpers do

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', ENV['DODGEWORD']]
    end

  end
  

  get '/' do
    get_data
    @team = Team.new
    erb :index
  end

  get '/thankyou' do
    get_data
    erb :thankyou
  end

  get '/admin' do
    protected!
    @new_teams = Team.all(:cool => false)
    @cool_teams = Team.all(:cool => true)
    erb :admin
  end

  get '/edit/:id' do
    protected!
    @team = Team.first(:id => params[:id].to_i)
    erb :edit
  end

  get '/verify/:id' do
    protected!
    @team = Team.first(:id => params[:id].to_i)
    @team.cool = true
    @team.save
    redirect '/admin'
  end

  get '/unverify/:id' do
    protected!
    @team = Team.first(:id => params[:id].to_i)
    @team.cool = false
    @team.save
    redirect '/admin'
  end

  get '/delete/:id' do
    protected!
    @team = Team.first(:id => params[:id].to_i)
    @team.destroy
    redirect '/admin'
  end

  post '/save' do
    protected!
    @team = Team.first(:id => params[:teamid].to_i)
    fill_team(@team, params)
    if @team.save
      redirect '/admin'
    else
      erb :edit
    end
  end

  post '/new' do
    @team = Team.new
    fill_team(@team, params)
    if @team.save
      notify_campfire(@team)
      redirect '/thankyou'
    else
      get_data
      erb :index
    end
  end

end
