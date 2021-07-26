require "clerk/authenticatable"

class ApplicationController < ActionController::Base
  include Clerk::Authenticatable

  helper_method :current_user

  def current_user
    @current_user ||= clerk_user
  end
end
