class V1::Admin::BaseController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_v1_admin!
end
