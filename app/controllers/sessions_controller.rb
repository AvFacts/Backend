require 'securerandom'

# Semi-RESTful singleton API controller for logging and an out of the app.
# Credentials are passed as JSON Web Tokens encoded into the `Authorization`
# header.

class SessionsController < ApplicationController
  skip_before_action :authenticate_with_warden

  # Logs a user in from a given username and password.
  #
  # Routes
  # ------
  #
  # * `POST /session.json`
  #
  # Query Parameters
  # ----------------
  #
  # |            |                      |
  # |:-----------|:---------------------|
  # | `username` | The {User} username. |
  # | `password` | The user's password. |
  #
  # Response
  # --------
  #
  # **Successful authentication:** 200 OK and the valid `Authorization` header.
  #
  # **Invalid credentials:** 401 Unauthorized.

  def create
    request.env['warden'].authenticate!
    respond_to do |format|
      format.json { render json: {success: true} }
      format.any { head :ok }
    end
  end

  # Logs a user out.
  #
  # Routes
  # ------
  #
  # * `DELETE /session.json`

  def destroy
    request.env['warden'].logout :user
    respond_to do |format|
      format.json { render json: {success: true} }
      format.any { head :ok }
    end
  end
end
