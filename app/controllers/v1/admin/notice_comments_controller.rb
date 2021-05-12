class V1::Admin::NoticeCommentsController < V1::Admin::BaseController
  skip_before_action :authenticate_v1_admin!
  before_action :authenticate_v1_user!, only: %i[create destroy]

  def index
    data = NoticeComment.fetch_by_cached_with_options(configure_index_params)

    render json: data
  end

  def create
    Rails.cache.clear("notices-#{configure_create_params[:notice_id]}", namespace: 'notices-detail')
    Rails.cache.clear(namespace: "notices-#{configure_create_params[:notice_id]}-comments")
    render json: NoticeComment.create_with_options(configure_create_params), each_serializer: NoticeCommentSerializer
  end

  def non_members_create
    Rails.cache.clear("notices-#{configure_create_params[:notice_id]}", namespace: 'notices-detail')
    Rails.cache.clear(namespace: "notices-#{configure_create_params[:notice_id]}-comments")
    render json: NoticeComment.create_with_options(configure_non_members_create_params), each_serializer: NoticeCommentSerializer
  end

  def destroy
    Rails.cache.clear("notices-#{configure_create_params[:notice_id]}", namespace: 'notices-detail')
    Rails.cache.clear(namespace: "notices-#{configure_create_params[:notice_id]}-comments")
    render json: NoticeComment.destroy_for_member(configure_destroy_params), each_serializer: NoticeCommentSerializer
  end

  def non_members_destroy
    Rails.cache.clear("notices-#{configure_create_params[:notice_id]}", namespace: 'notices-detail')
    Rails.cache.clear(namespace: "notices-#{configure_create_params[:notice_id]}-comments")
    render json: NoticeComment.destroy_for_non_member(configure_non_member_destroy_params), each_serializer: NoticeCommentSerializer
  end

  private

  def index_attributes
    %w[notice_id page per orderBy]
  end

  def create_attributes
    %w[notice_id content]
  end

  def non_members_create_attributes
    %w[notice_id nickname password content]
  end

  def destroy_attributes
    %w[notice_id id]
  end

  def non_members_destroy_attributes
    %w[notice_id id password]
  end

  def configure_index_params
    index_attributes.each do |key|
      if params.key? key.to_sym
        raise Errors::BadRequest.new(code: 'COC013', message: "#{key} is empty") if params[key.to_sym].blank?
      end
    end

    params.permit(index_attributes)
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

  def configure_non_member_destroy_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'password is required') if params[:password].blank?

    params.permit(non_members_destroy_attributes)
  end
end
