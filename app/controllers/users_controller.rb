class UsersController < ApplicationController
  def index
    render json: { message: "UsersController loaded" }
  end
end
