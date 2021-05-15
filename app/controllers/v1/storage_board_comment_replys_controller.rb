class V1::StorageBoardCommentReplysController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[non_members_create non_members_destroy]

  def create
    namespace = "storages-#{params[:storage_id]}-boards-#{params[:storage_board_id]}-comments"

    Rails.cache.clear(namespace: namespace)

    redis_key = "storages-#{params[:storage_id]}-boards-#{params[:storage_board_id]}"
    namespace = "storages-#{params[:storage_id]}-boards-detail"

    Rails.cache.delete(redis_key, namespace: namespace)
    render json: StorageBoardCommentReply.create_with_options(create_params), each_serializer: StorageBoardCommentReplySerializer
  end

  def non_members_create
    namespace = "storages-#{params[:storage_id]}-boards-#{params[:storage_board_id]}-comments"

    Rails.cache.clear(namespace: namespace)

    redis_key = "storages-#{params[:storage_id]}-boards-#{params[:storage_board_id]}"
    namespace = "storages-#{params[:storage_id]}-boards-detail"

    Rails.cache.delete(redis_key, namespace: namespace)
    render json: StorageBoardCommentReply.create_with_options(non_members_create_params), each_serializer: StorageBoardCommentReplySerializer
  end

  def destroy
    namespace = "storages-#{params[:storage_id]}-boards-#{params[:storage_board_id]}-comments"

    Rails.cache.clear(namespace: namespace)

    redis_key = "storages-#{params[:storage_id]}-boards-#{params[:storage_board_id]}"
    namespace = "storages-#{params[:storage_id]}-boards-detail"

    Rails.cache.delete(redis_key, namespace: namespace)
    render json: StorageBoardCommentReply.destroy_for_member(destroy_params), each_serializer: StorageBoardCommentReplySerializer
  end

  def non_members_destroy
    namespace = "storages-#{params[:storage_id]}-boards-#{params[:storage_board_id]}-comments"

    Rails.cache.clear(namespace: namespace)

    redis_key = "storages-#{params[:storage_id]}-boards-#{params[:storage_board_id]}"
    namespace = "storages-#{params[:storage_id]}-boards-detail"

    Rails.cache.delete(redis_key, namespace: namespace)
    render json: StorageBoardCommentReply.destroy_for_non_member(non_members_destroy_params), each_serializer: StorageBoardCommentReplySerializer
  end

  private

  def create_attributes
    %w[storage_board_comment_id content]
  end

  def non_members_create_attributes
    %w[storage_board_comment_id nickname password content]
  end

  def destroy_attributes
    %w[storage_board_comment_id id]
  end

  def non_members_destroy_attributes
    %w[storage_board_comment_id id password]
  end

  def create_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'content is required') if params[:content].blank?

    params.permit(create_attributes).merge(
      user: current_v1_user,
      created_ip: request.headers['CF-Connecting-IP'] || request.remote_ip,
      created_user_agent: request.user_agent
    )
  end

  def non_members_create_params
    non_members_create_attributes.each do |key|
      raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required") if params[key].blank?
    end

    params.permit(non_members_create_attributes).merge(
      created_ip: request.headers['CF-Connecting-IP'] || request.remote_ip,
      created_user_agent: request.user_agent
    )
  end

  def destroy_params
    params.permit(destroy_attributes).merge(user: current_v1_user)
  end

  def non_members_destroy_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'password is required') if params[:password].blank?

    params.permit(non_members_destroy_attributes)
  end
end
