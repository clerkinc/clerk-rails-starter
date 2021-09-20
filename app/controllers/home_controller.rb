class HomeController < ApplicationController
  before_action :require_login, only: :profile

  def show
  end

  # GET /profile
  def profile
  end
end
