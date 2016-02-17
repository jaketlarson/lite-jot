class Folder < ActiveRecord::Base
  acts_as_paranoid

  has_many :topics, :dependent => :destroy
  has_many :folder_shares, :dependent => :destroy
  has_many :topic_shares, :dependent => :destroy
  
  belongs_to :user

  validates_presence_of :user_id

  def self.autocreate_first_folder(user_id)
    folder = Folder.new(:title => "My First Folder", :user_id => user_id)
    folder.save!
    folder
  end
end
