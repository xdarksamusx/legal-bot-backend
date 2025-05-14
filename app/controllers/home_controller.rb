class HomeController < ApplicationController

  def check 
    if current_user
      render json: {logged_in: true}, status: :ok 
    else
      render json: {logged_in: false}, status: :unauthorized
    end
  end
  
  


  
end
