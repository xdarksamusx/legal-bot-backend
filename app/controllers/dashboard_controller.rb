class DashboardController < ApplicationController

  before_action :authenticate_user!

  def index 
    @disclaimers = current_user.disclaimers.order(created_at: :desc)
  end




end
