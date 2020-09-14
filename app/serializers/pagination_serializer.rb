class PaginationSerializer < ActiveModel::Serializer
  attributes :total_pages,
             :current_page,
             :prev_page,
             :next_page,
             :per_page,
             :is_last_page

  def total_pages
    object.total_pages
  end

  def current_page
    object.current_page
  end

  def prev_page
    object.prev_page
  end

  def next_page
    object.next_page
  end

  def per_page
    object.limit_value
  end

  def is_last_page
    object.last_page?
  end
end
