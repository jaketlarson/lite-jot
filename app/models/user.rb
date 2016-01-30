class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         :omniauth_providers => [:google_oauth2, :facebook]

  has_many :folders
  has_many :topics
  has_many :jots
  has_many :shares, :foreign_key => 'owner_id'
  has_many :support_tickets

  validates :display_name, {
    :presence => true,
    :length => {
      :minimum => 1,
      :maximum => 50
    }
  }

  validate :freeze_email, :on => :update

  serialize :notifications_seen
  serialize :preferences

  after_create :send_signup_email, :update_associated_shares

  self.per_page = 25

  attr_accessor :current_password

  def freeze_email
    errors.add(:email, 'cannot be changed') if self.email_changed?
  end

  def send_signup_email
    UserNotifier.send_signup_email(self).deliver
  end

  def update_associated_shares
    # This method sets the new user's id in any shares that were sent
    # to their email before they registered.
    shares = Share.where('recipient_email = ?', self.email)
    if !shares.empty?
      shares.each do |share|
        share.recipient_id = self.id
        share.save
      end
    end
  end

  def intro_seen
    self.saw_intro = true
    self.save
  end

  def set_preference(pref_name, value = value.to_s)
    if self.preferences.nil? || self.preferences.blank?
      preferences = {}
    else
      preferences = JSON.parse(self.preferences)
    end

    preferences[pref_name] = value.to_s
    self.preferences = preferences.to_json
    self.save
  end

  def self.find_for_google_oauth2(access_token)
    data = access_token.info
    user = User.where(:email => data['email']).first

    unless user
      user = User.create!(
        :auth_provider => access_token['provider'],
        :auth_provider_uid => access_token['uid'],
        :auth_token => access_token['credentials']['token'],
        :auth_refresh_token => access_token['credentials']['refresh_token'],
        :auth_token_expiration => DateTime.strptime(access_token['credentials']['expires_at'].seconds.to_s, '%s'),
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
      :auth_token_expiration => DateTime.now + expiration.seconds,
    )
  end

  # Used on initial data load
  def owned_and_shared_folders
    Folder.includes(:shares).where("user_id = ? OR (shares.recipient_id = ? AND (shares.is_all_topics = ? OR shares.specific_topics != ?))", self.id, self.id, true, '').order('folders.updated_at DESC').references(:shares)
  end

  # Used on sync cycles
  def owned_and_shared_folders_with_deleted_after_time(begin_at)
    Folder.with_deleted.includes(:shares).where("(user_id = ? OR (shares.recipient_id = ? AND (shares.is_all_topics = ? OR shares.specific_topics != ?))) AND (folders.updated_at > ? OR folders.created_at > ? OR folders.deleted_at > ?)", self.id, self.id, true, '', begin_at, begin_at, begin_at).order('folders.updated_at DESC').references(:shares)
  end
end
