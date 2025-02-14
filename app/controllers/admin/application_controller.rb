class Admin::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  layout "admin"
end
