class RssController < ApplicationController
  skip_before_action :validation_x_api_key

  def index
    storage_boards = StorageBoard.where(is_draft: false, is_active: true).order(id: :desc).limit(10)

    xml = "<?xml version='1.0' encoding='UTF-8'?>
    <rss version='2.0'>
      <channel>
        <title>개념글 저장소</title>
        <link>https://www.cocstorage.com</link>
        <description>내가 만들어 운영하는 커뮤니티 저장소</description>
        #{storage_boards.map do |storage_board|
           storage = Storage.find(storage_board.storage_id)
            "<item>
              <title>#{CGI.escapeHTML(storage_board.subject)}</title>
              <link>https://www.cocstorage.com/storages/#{storage.path}/#{storage_board.id}</link>
              <description>#{CGI.escapeHTML(storage_board.description)}</description>
              <pubDate>#{storage_board.created_at.rfc822}</pubDate>
              <guid>https://www.cocstorage.com/storages/#{storage.path}/#{storage_board.id}</guid>
            </item>"
           end.join('')}
      </channel>
    </rss>"

    render xml: xml
  end
end
