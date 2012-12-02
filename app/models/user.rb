# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ActiveRecord::Base
  attr_accessible :name, :email, :password, :password_confirmation, :admin

  has_secure_password

#  before_save { |user| user.email = email.downcase }
  before_save { self.email.downcase! }
  before_save :create_remember_token

  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence:   true,
                    format:     { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
#  validates :password, presence: true, length: { minimum: 6 }
# WDS: Removed presence: true as this causes the error "Password can't be blank"
#      The has_secure_password will produce an error of "Password digest" can't be blank
#      and the exercise wanted us to change this from "Password digest" to 
#      just "Password".  This was done in en.yml changing password_digest to "Password"
#      The absense of password causes the absense of password_digest
  validates :password, length: { minimum: 6 }
  validates :password_confirmation, presence: true

  has_many :microposts, dependent: :destroy
  
  def feed
    # This is preliminary. See "Following users" for the full implementation.
    Micropost.where("user_id = ?", id)
  end
  
  private

    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end

end
