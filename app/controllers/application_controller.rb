class ApplicationController < ActionController::Base

  respond_to :json, :html

  protect_from_forgery unless: -> { request.format.json? }
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
