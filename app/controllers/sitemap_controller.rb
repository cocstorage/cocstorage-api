class SitemapController < ApplicationController

  def index
    storages = Storage.where(is_active: true).order(id: :desc)

    xml = "<?xml version='1.0' encoding='UTF-8'?>
    <urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>
      <url>
        <loc>https://www.cocstorage.com</loc>
        <lastmod>#{DateTime.current.xmlschema}</lastmod>
        <changefreq>hourly</changefreq>
        <priority>1.0</priority>
      </url>
      <url>
        <loc>https://www.cocstorage.com/storages</loc>
        <lastmod>#{DateTime.current.xmlschema}</lastmod>
        <changefreq>hourly</changefreq>
        <priority>0.6</priority>
      </url>
      #{storages.map do |storage|
        "<url>
          <loc>https://www.cocstorage.com/storages/#{storage.path}</loc>
          <lastmod>#{storage.created_at.xmlschema}</lastmod>
          <changefreq>hourly</changefreq>
          <priority>0.8</priority>
        </url>"
      end.join('')}
    </urlset>"

    render xml: xml
  end

  def root
    storages = Storage.where(is_active: true).order(id: :desc)

    xml = "<?xml version='1.0' encoding='UTF-8'?>
    <urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>
      <url>
        <loc>https://cocstorage.com</loc>
        <lastmod>#{DateTime.current.xmlschema}</lastmod>
        <changefreq>hourly</changefreq>
        <priority>1.0</priority>
      </url>
      <url>
        <loc>https://cocstorage.com/storages</loc>
        <lastmod>#{DateTime.current.xmlschema}</lastmod>
        <changefreq>hourly</changefreq>
        <priority>0.6</priority>
      </url>
      #{storages.map do |storage|
      "<url>
          <loc>https://cocstorage.com/storages/#{storage.path}</loc>
          <lastmod>#{storage.created_at.xmlschema}</lastmod>
          <changefreq>hourly</changefreq>
          <priority>1.0</priority>
        </url>"
    end.join('')}
    </urlset>"

    render xml: xml
  end

  def mobile
    storages = Storage.where(is_active: true).order(id: :desc)

    xml = "<?xml version='1.0' encoding='UTF-8'?>
    <urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>
      <url>
        <loc>https://m.cocstorage.com</loc>
        <lastmod>#{DateTime.current.xmlschema}</lastmod>
        <changefreq>hourly</changefreq>
        <priority>1.0</priority>
      </url>
      <url>
        <loc>https://m.cocstorage.com/storages</loc>
        <lastmod>#{DateTime.current.xmlschema}</lastmod>
        <changefreq>hourly</changefreq>
        <priority>0.6</priority>
      </url>
      #{storages.map do |storage|
      "<url>
          <loc>https://m.cocstorage.com/storages/#{storage.path}</loc>
          <lastmod>#{storage.created_at.xmlschema}</lastmod>
          <changefreq>hourly</changefreq>
          <priority>1.0</priority>
        </url>"
    end.join('')}
    </urlset>"

    render xml: xml
  end
end
