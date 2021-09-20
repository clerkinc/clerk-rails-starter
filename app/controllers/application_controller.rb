require "clerk/authenticatable"

class ApplicationController < ActionController::Base
  include Clerk::Authenticatable

  helper_method :current_user

  def current_user
    @current_user ||= clerk_user
  end

  protected

  def require_login
    if !current_user
      flash[:error] = "You must be logged in to access the page at `#{request.path}` <br/> Please login and retry."

      redirect_to root_url
    end
  end
end
