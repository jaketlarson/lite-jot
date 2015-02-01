class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :username, {
    :presence => true,
    :length => {
      :minimum => 3,
      :maxmium => 16
    },
    :format => {
      :with => /\A[a-zA-Z0-9]+\Z/
    },
    :uniqueness => true
  }
end
