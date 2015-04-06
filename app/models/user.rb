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
    # :format => {
    #   :with => /\A[a-zA-Z0-9]+\Z/
    # },
    :uniqueness => true
  }
  def self.find_for_google_oauth2(access_token)
      data = access_token.info
      user = User.where(:email => data['email']).first

      # Uncomment the section below if you want users to be created if they don't exist
      unless user
        user = User.create!(
          provider: access_token['provider'],
          provider_uid: access_token['uid'],
          google_token: access_token['credentials']['token'],
          display_name: data['name'],
          email: data['email'],
          password: Devise.friendly_token[0,16]
        )
      else
        user.google_token = access_token['credentials']['token']
        user.save
      end
      user
  end

  def self.find_for_facebook(access_token)
      data = access_token.info
      user = User.where(:email => data['email']).first

      # Uncomment the section below if you want users to be created if they don't exist
      unless user
        user = User.create!(
          provider: access_token['provider'],
          provider_uid: access_token['uid'],
          display_name: data['name'],
          email: data['email'],
          password: Devise.friendly_token[0,16]
        )
      end
      user
  end
end
