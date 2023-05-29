class PopularStorageBoardCollectionJob < ApplicationJob
  queue_as :popular_storage_board_collection

  def perform(*args)
    today_storage_boards = StorageBoard.where(
      created_at: DateTime.current.beginning_of_day..DateTime.current.end_of_day,
      is_draft: false,
      is_active: true,
      is_popular: false,
      is_worst: false
    )

    today_storage_boards.map do |storage_board|
      thumb_up = storage_board.thumb_up
      # thumb_down = storage_board.thumb_down
      # thumb_count = thumb_up + thumb_down
      # thumb_up_percent = (thumb_up.to_f / thumb_count.to_f * 100).round(1)
      # comment_total_count = storage_board.comment_count + storage_board.reply_count

      # TODO 베스트 등재 조건 임시 완화, 추후 수정
      # if thumb_up >= 1 && comment_total_count >= 10 && thumb_up_percent >= 55
      if thumb_up >= 1
        storage_board.update(is_popular: true)
      end
    end
  end
end
