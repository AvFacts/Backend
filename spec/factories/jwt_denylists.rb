FactoryBot.define do
  factory :jwt_denylist do
    sequence(:jti) { |i| "jwt-#{i}" }
  end
end
