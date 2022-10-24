# frozen_string_literal: true

FactoryBot.define do
  factory :jwt_denylist do
    sequence(:jti) { |i| "jwt-#{i}" }
  end
end
