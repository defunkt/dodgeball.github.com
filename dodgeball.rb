require 'sinatra/base'

require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'

## -- DATABASE STUFF --

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/local.db")

class Team
  include DataMapper::Resource
  has n, :sponsors

  property :id,         Serial
  property :name,       String
  property :company,    String
  property :charity,    String
  property :charity_url,  String
  property :github,       String
  property :twitter,      String
  property :image,        String
  property :donation,     Integer
  property :sponsored,    Integer
  property :valid,        Boolean
  property :owner,        String
  property :email,        String
  property :player_1,     String
  property :player_2,     String
  property :player_3,     String
  property :player_4,     String
  property :player_5,     String
  property :player_6,     String
  property :player_7,     String
  property :player_8,     String
  property :updated_at,   DateTime
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

  def get_data
    @teams = Team.all(:valid => true)
    @pot = 3001
  end

  get '/' do
    get_data
    @team = Team.new
    erb :index
  end

  post '/new' do
    @team = Team.new
    @team.name = params['team-name']
    @team.company  = params['company-name']
    @team.charity  = params['charity-name']
    @team.charity_url = params['charity-url']
    @team.twitter  = params['company-twitter']
    @team.email    = params['contact-email']
    @team.image    = params['team-image']
    @team.player_1 = params['player-1']
    @team.player_2 = params['player-2']
    @team.player_3 = params['player-3']
    @team.player_4 = params['player-4']
    @team.player_5 = params['player-5']
    @team.player_6 = params['player-6']
    @team.player_7 = params['player-7']
    @team.player_8 = params['player-8']
    if @team.save
      redirect '/'
    else
      get_data
      erb :index
    end
  end

end
