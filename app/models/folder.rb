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

  def self.is_empty(folder_id)
    folder_check = Folder.where('id = ?', folder_id)
    folder_check.empty?
  end

  def self.is_owned(folder_id, user)
    if !folder_id.nil? && folder_id.to_i > 0
      if !self.is_empty(folder_id)
        folder_check = Folder.where('id = ?', folder_id)
        if folder_check.first.user_id != user.id
          folder_is_owned = false
        end
      end
    end
  end

  def self.autogenerate_if_nesessary(jot, user)
    # Only return new_folder if a new one is created
    new_folder = nil

    if jot.folder_id.nil? || jot.folder_id.to_i <= 0 || Folder.where('id = ?', jot.folder_id).empty?
      if new_folder # was already generated from another jot in the collection
        folder_id = new_folder.id
      else
        time = Time.new
        folder = user.folders.new
        folder.title = "New #{time.strftime('%b %d')}"
        folder.save

        new_folder = folder
        folder_id = folder.id
      end
    else
      folder_id = jot.folder_id
    end

    return { :new_folder => new_folder, :folder_id => folder_id }
  end
end
