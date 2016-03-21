class Topic < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :user
  belongs_to :folder
  has_many :jots, :dependent => :destroy
  has_many :topic_shares, :dependent => :destroy

  validates_presence_of :user_id

  default_scope { order("updated_at DESC") }

  def self.autocreate_first_topic(folder_id, user_id)
    topic = Topic.new(:title => "My First Topic", :folder_id => folder_id, :user_id => user_id)
    topic.save!
    topic
  end

  def self.autogenerate_if_nesessary(jot, user)
    # Only return new_topic if a new one is created
    new_topic = nil

    if jot.topic_id.nil? || jot.topic_id.to_i <= 0 || Topic.where('id = ?', jot.topic_id).empty?
      if new_topic # was already generated from another jot in the collection
        topic_id = new_topic.id
      else
        time = Time.new
        topic = user.topics.new
        topic.title = "New #{time.strftime('%b %d')}"
        topic.save

        new_topic = topic
        topic_id = topic.id
      end
    else
      topic_id = jot.topic_id
    end

    return { :new_topic => new_topic, :topic_id => topic_id }
  end
end
