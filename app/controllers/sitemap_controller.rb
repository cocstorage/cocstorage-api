class SitemapController < ApplicationController

  def index
    storages = Storage.where(is_active: true).order(id: :desc)
    storage_boards = StorageBoard.where(is_draft: false, is_active: true).order(id: :desc).limit(100)

    xml = "<?xml version='1.0' encoding='UTF-8'?>
    <urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>
      <url>
        <loc>https://www.cocstorage.com</loc>
        <lastmod>#{DateTime.current.xmlschema}</lastmod>
        <changefreq>hourly</changefreq>
        <priority>1.0</priority>
      </url>
      #{storages.map do |storage|
        "<url>
          <loc>https://www.cocstorage.com/storages/#{storage.path}</loc>
          <lastmod>#{storage.created_at.xmlschema}</lastmod>
          <changefreq>hourly</changefreq>
          <priority>0.6</priority>
        </url>"
      end.join('')}
      #{storage_boards.map do |storage_board|
        storage = Storage.find(storage_board.storage_id)
        "<url>
          <loc>https://www.cocstorage.com/storages/#{storage.path}/#{storage_board.id}</loc>
          <lastmod>#{storage_board.created_at.xmlschema}</lastmod>
          <changefreq>daily</changefreq>
          <priority>1.0</priority>
        </url>"
      end.join('')}
    </urlset>"

    render xml: xml
  end
end
