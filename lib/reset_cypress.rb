# frozen_string_literal: true

# Rack application that an endpoint allowing the Cypress front-end to reset the
# database before each E2E test run. Only mounted in the `cypress` environment.

class ResetCypress

  # @private
  def call(_env)
    reset
    create_admin_user
    return response
  end

  private

  def reset
    models.each { |model| truncate model }
  end

  def response
    [200, {"Content-Type" => "text/plain"}, ["Cypress reset finished"]]
  end

  def models
    [ActiveStorage::Blob, ActiveStorage::Attachment, User, Episode]
  end

  def truncate(model)
    model.connection.execute "TRUNCATE #{model.quoted_table_name} CASCADE"
  end

  def create_admin_user
    User.create! username: "cypress", password: "password123"
  end
end
