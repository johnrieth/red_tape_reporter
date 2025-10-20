module ApplicationHelper
  def meta_title
    content_for?(:meta_title) ? content_for(:meta_title) : "Report LA Building Issues | Red Tape LA"
  end

  def meta_description
    content_for?(:meta_description) ? content_for(:meta_description) : "Report problems with LA's building process—permits, inspections, zoning, fees, and more. Help us document bureaucratic delays and advocate for policy reforms."
  end

  def meta_image
    content_for?(:meta_image) ? content_for(:meta_image) : asset_url("la-banner.jpg")
  end

  def page_url
    request.original_url
  end
end
