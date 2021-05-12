class V1::Admin::NoticeCommentReplysController < V1::Admin::BaseController
  skip_before_action :authenticate_v1_admin!
  before_action :authenticate_v1_user!, only: %i[create destroy]

  def create
    Rails.cache.clear("notices-#{configure_create_params[:notice_id]}", namespace: 'notices-detail')
    Rails.cache.clear(namespace: "notices-#{configure_create_params[:notice_id]}-comments")
    render json: NoticeCommentReply.create_with_options(configure_create_params), each_serializer: NoticeCommentReplySerializer
  end

  def non_members_create
    Rails.cache.clear("notices-#{configure_non_members_create_params[:notice_id]}", namespace: 'notices-detail')
    Rails.cache.clear(namespace: "notices-#{configure_non_members_create_params[:notice_id]}-comments")
    render json: NoticeCommentReply.create_with_options(configure_non_members_create_params), each_serializer: NoticeCommentReplySerializer
  end

  def destroy
    Rails.cache.clear("notices-#{configure_destroy_params[:notice_id]}", namespace: 'notices-detail')
    Rails.cache.clear(namespace: "notices-#{configure_destroy_params[:notice_id]}-comments")
    render json: NoticeCommentReply.destroy_for_member(configure_destroy_params), each_serializer: NoticeCommentReplySerializer
  end

  def non_members_destroy
    Rails.cache.clear("notices-#{configure_non_members_destroy_params[:notice_id]}", namespace: 'notices-detail')
    Rails.cache.clear(namespace: "notices-#{configure_non_members_destroy_params[:notice_id]}-comments")
    render json: NoticeCommentReply.destroy_for_non_member(configure_non_members_destroy_params), each_serializer: NoticeCommentReplySerializer
  end

  private

  def create_attributes
    %w[notice_id notice_comment_id content]
  end

  def non_members_create_attributes
    %w[notice_id notice_comment_id nickname password content]
  end

  def destroy_attributes
    %w[notice_id notice_comment_id id]
  end

  def non_members_destroy_attributes
    %w[notice_id notice_comment_id id password]
  end

  def configure_create_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'content is required') if params[:content].blank?

    params.permit(create_attributes).merge(
      user: current_v1_user,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end

  def configure_non_members_create_params
    non_members_create_attributes.each do |key|
      raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required") if params[key].blank?
    end

    params.permit(non_members_create_attributes).merge(
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end

  def configure_destroy_params
    params.permit(destroy_attributes).merge(user: current_v1_user)
  end

  def configure_non_members_destroy_params
    params.permit(non_members_destroy_attributes)
  end
end
