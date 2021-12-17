class RssController < ApplicationController

  def index
    base_url = 'https://www.cocstorage.com'

    storage_boards = StorageBoard.where(is_draft: false, is_active: true).order(id: :desc).limit(100)

    xml = "<?xml version='1.0' encoding='UTF-8'?>
    <rss version='2.0'>
      <channel>
        <title>개념글 저장소</title>
        <link>#{base_url}</link>
        <description>내가 만들어 운영하는 커뮤니티 저장소</description>
        #{storage_boards.map do |storage_board|
           storage = Storage.find(storage_board.storage_id)
            "<item>
              <title>#{CGI.escapeHTML(storage_board.subject)}</title>
              <link>#{base_url}/storages/#{storage.path}/#{storage_board.id}</link>
              <description><![CDATA[#{CGI.escapeHTML(storage_board.description || '')[0..159]}]]></description>
              <pubDate>#{storage_board.created_at.rfc822}</pubDate>
              <guid>#{base_url}/storages/#{storage.path}/#{storage_board.id}</guid>
            </item>"
           end.join('')}
      </channel>
    </rss>"

    render xml: xml
  end

  def root
    base_url = 'https://cocstorage.com'

    storage_boards = StorageBoard.where(is_draft: false, is_active: true).order(id: :desc).limit(100)

    xml = "<?xml version='1.0' encoding='UTF-8'?>
    <rss version='2.0'>
      <channel>
        <title>개념글 저장소</title>
        <link>#{base_url}</link>
        <description>내가 만들어 운영하는 커뮤니티 저장소</description>
        #{storage_boards.map do |storage_board|
      storage = Storage.find(storage_board.storage_id)
      "<item>
              <title>#{CGI.escapeHTML(storage_board.subject)}</title>
              <link>#{base_url}/storages/#{storage.path}/#{storage_board.id}</link>
              <description><![CDATA[#{CGI.escapeHTML(storage_board.description || '')[0..159]}]]></description>
              <pubDate>#{storage_board.created_at.rfc822}</pubDate>
              <guid>#{base_url}/storages/#{storage.path}/#{storage_board.id}</guid>
            </item>"
    end.join('')}
      </channel>
    </rss>"

    render xml: xml
  end

  def mobile
    base_url = 'https://m.cocstorage.com'

    storage_boards = StorageBoard.where(is_draft: false, is_active: true).order(id: :desc).limit(100)

    xml = "<?xml version='1.0' encoding='UTF-8'?>
    <rss version='2.0'>
      <channel>
        <title>개념글 저장소</title>
        <link>#{base_url}</link>
        <description>내가 만들어 운영하는 커뮤니티 저장소</description>
        #{storage_boards.map do |storage_board|
      storage = Storage.find(storage_board.storage_id)
      "<item>
              <title>#{CGI.escapeHTML(storage_board.subject)}</title>
              <link>#{base_url}/storages/#{storage.path}/#{storage_board.id}</link>
              <description><![CDATA[#{CGI.escapeHTML(storage_board.description || '')[0..159]}]]></description>
              <pubDate>#{storage_board.created_at.rfc822}</pubDate>
              <guid>#{base_url}/storages/#{storage.path}/#{storage_board.id}</guid>
            </item>"
    end.join('')}
      </channel>
    </rss>"

    render xml: xml
  end
end
