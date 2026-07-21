class Chantier < ApplicationRecord
  validates :nom, presence: true

  def self.visible_to(user)
    return all if user&.admin?
    return none unless user

    where(email_technicien: user.email)
      .or(where(email_contremaitre: user.email))
      .or(where(email_chef_equipe: user.email))
  end
end
