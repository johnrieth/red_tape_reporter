# config/sitemap.rb
require "rubygems"
require "sitemap_generator"

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://redtape.la"

# Create a sitemap index if more than one sitemap is generated
SitemapGenerator::Sitemap.create_index = true

# Compress the sitemap files for better performance
SitemapGenerator::Sitemap.compress = true

# Set a public path for sitemaps
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"

# Create both compressed and uncompressed versions for easier debugging
[ true, false ].each do |compress_value|
  SitemapGenerator::Sitemap.compress = compress_value

  SitemapGenerator::Sitemap.create do
    # Add your static pages with appropriate priorities and change frequencies
    add root_path, changefreq: "weekly", priority: 1.0
    add about_path, changefreq: "monthly", priority: 0.9
    add new_report_path, changefreq: "monthly", priority: 0.8
    add success_reports_path, changefreq: "monthly", priority: 0.6

    # Note: We're excluding admin pages, session, password, and verification pages
    # as they either contain sensitive information or have limited SEO value

    # If you have individual report pages that should be indexed in the future:
    # Report.find_each do |report|
    #   add report_path(report), lastmod: report.updated_at, changefreq: 'weekly', priority: 0.7
    # end
  end
end
