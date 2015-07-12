class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         :omniauth_providers => [:google_oauth2, :facebook]

  has_many :folders
  has_many :topics
  has_many :jots

  validates :display_name, {
    :presence => true,
    :length => {
      :minimum => 3,
      :maxmium => 16
    },
    :uniqueness => true
  }
  def self.find_for_google_oauth2(access_token)
      data = access_token.info
      user = User.where(:email => data['email']).first

      unless user
        user = User.create!(
          :auth_provider => access_token['provider'],
          :auth_provider_uid => access_token['uid'],
          :auth_token => access_token['credentials']['token'],
          :auth_refresh_token => access_token['credentials']['refresh_token'],
          :auth_token_expiration => DateTime.strptime(access_token['credentials']['expires_at'].seconds.to_s, '%s').seconds,
          :display_name => data['name'],
          :email => data['email'],
          :password => Devise.friendly_token[0,16]
        )
      else
        unless access_token['credentials']['refresh_token'].nil?
          auth_refresh_token = access_token['credentials']['refresh_token']
        else
          auth_refresh_token = user.auth_refresh_token
        end

        user.update!(
          :auth_token => access_token['credentials']['token'],
          :auth_token_expiration => DateTime.strptime(access_token['credentials']['expires_at'].seconds.to_s, '%s'),
          :auth_refresh_token => auth_refresh_token
        )
      end
      user
  end

  def self.find_for_facebook(access_token)
      data = access_token.info
      user = User.where(:email => data['email']).first

      # Uncomment the section below if you want users to be created if they don't exist
      unless user
        user = User.create!(
          :auth_provider => access_token['provider'],
          :auth_provider_uid => access_token['uid'],
          :display_name => data['name'],
          :email => data['email'],
          :password => Devise.friendly_token[0,16]
        )
      end
      user
  end

  def save_google_token(token, expiration)
    update(
      :auth_token => token,
      :auth_token_expiration => DateTime.strptime(expiration.seconds.to_s, '%s'),
    )
  end
end
