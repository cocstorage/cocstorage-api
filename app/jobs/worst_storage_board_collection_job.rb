class WorstStorageBoardCollectionJob < ApplicationJob
  queue_as :worst_storage_board_collection

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
      thumb_down = storage_board.thumb_down
      thumb_count = thumb_up + thumb_down
      thumb_down_percent = (thumb_down.to_f / thumb_count.to_f * 100).round(1)
      comment_total_count = storage_board.comment_count + storage_board.reply_count

      if thumb_down >= 1 && comment_total_count >= 10 && thumb_down_percent >= 55
        storage_board.update(is_worst: true)
      end
    end
  end
end
