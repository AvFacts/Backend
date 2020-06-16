class JWTDenylist < ApplicationRecord
  self.table_name = 'jwt_denylist'

  validates :jti,
            presence:   true,
            uniqueness: {case_sensitive: false}

  def self.prune!
    where(arel_attribute(:created_at).lt(30.days.ago)).delete_all
  end
end
