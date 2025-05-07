# class UsersController < ApplicationController
#   before_action :authenticate_user!

#   def current

#     if current_user
#       render json: {id: current_user.id, email: current_user.email}
#     else
#       render json: {error: "Not Logged in"}, status: :unauthorized
#     end

#   end



# end
