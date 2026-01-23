class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :recipes, dependent: :destroy

  ADMIN_EMAIL = 'pngauthier@hotmail.fr'.freeze

  def admin?
    email == ADMIN_EMAIL
  end
end
