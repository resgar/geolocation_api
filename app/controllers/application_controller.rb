class ApplicationController < ActionController::API
  include ApiAuthentication
  include ErrorHandling
end
