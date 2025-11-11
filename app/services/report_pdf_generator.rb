# Service object for generating PDF reports of Red Tape submissions
# Generates a professional formatted PDF with statistics and anonymized report details
class ReportPdfGenerator
  require "prawn"
  require "prawn/table"

  LA_NAVY_BLUE = "0b3d66"

  def initialize(reports:, stats:, start_date:, end_date:)
    @reports = reports
    @stats = stats
    @start_date = start_date
    @end_date = end_date
  end

  # Generates and returns a Prawn PDF document
  def generate
    Prawn::Document.new(page_size: "LETTER", margin: 50) do |pdf|
      render_title_page(pdf)
      render_executive_summary(pdf)
      render_statistics(pdf)
      render_individual_reports(pdf)
    end
  end

  private

  attr_reader :reports, :stats, :start_date, :end_date

  # Renders the title page with date range
  def render_title_page(pdf)
    pdf.font "Helvetica", size: 24, style: :bold
    pdf.text "Red Tape LA Report", align: :center, color: LA_NAVY_BLUE

    pdf.font "Helvetica", size: 12
    pdf.text date_range_text, align: :center
    pdf.move_down 30
  end

  # Renders the executive summary section
  def render_executive_summary(pdf)
    pdf.font "Helvetica", size: 16, style: :bold
    pdf.text "Executive Summary"
    pdf.move_down 10

    pdf.font "Helvetica", size: 11
    pdf.text summary_text
    pdf.move_down 20
  end

  # Renders all statistics sections
  def render_statistics(pdf)
    pdf.font "Helvetica", size: 14, style: :bold
    pdf.text "Key Statistics"
    pdf.move_down 10

    render_department_stats(pdf)
    render_issue_category_stats(pdf)
    render_timeline_impact_stats(pdf)
  end

  # Renders department statistics
  def render_department_stats(pdf)
    return unless stats[:departments].any?

    pdf.font "Helvetica", size: 12, style: :bold
    pdf.text "Most Frequently Mentioned Departments:"
    pdf.font "Helvetica", size: 10
    stats[:departments].first(5).each do |dept, count|
      pdf.text "• #{dept}: #{count} reports"
    end
    pdf.move_down 15
  end

  # Renders issue category statistics
  def render_issue_category_stats(pdf)
    return unless stats[:issue_categories].any?

    pdf.font "Helvetica", size: 12, style: :bold
    pdf.text "Most Common Issue Categories:"
    pdf.font "Helvetica", size: 10
    stats[:issue_categories].first(5).each do |issue, count|
      pdf.text "• #{issue}: #{count} reports"
    end
    pdf.move_down 15
  end

  # Renders timeline impact statistics
  def render_timeline_impact_stats(pdf)
    return unless stats[:timeline_impacts].any?

    pdf.font "Helvetica", size: 12, style: :bold
    pdf.text "Timeline Impacts:"
    pdf.font "Helvetica", size: 10
    stats[:timeline_impacts].each do |impact, count|
      pdf.text "• #{impact}: #{count} reports" if impact.present?
    end
    pdf.move_down 20
  end

  # Renders all individual report details
  def render_individual_reports(pdf)
    pdf.start_new_page
    pdf.font "Helvetica", size: 16, style: :bold
    pdf.text "Anonymized Reports"
    pdf.move_down 15

    reports.each_with_index do |report, index|
      render_single_report(pdf, report, index)
    end
  end

  # Renders a single report's details
  def render_single_report(pdf, report, index)
    # Start new page for each report after the first
    pdf.start_new_page if index > 0

    render_report_header(pdf, report)
    render_report_descriptions(pdf, report)
    render_report_impacts(pdf, report)
    render_report_metadata(pdf, report)
    render_report_solutions(pdf, report)
  end

  # Renders report header with ID and basic info
  def render_report_header(pdf, report)
    pdf.font "Helvetica", size: 12, style: :bold
    pdf.text "Report ##{report.id}: #{report.project_type} in #{report.location}"
    pdf.move_down 5

    pdf.font "Helvetica", size: 9
    pdf.text "Verified: #{report.verified_at&.strftime('%B %d, %Y')}"
    pdf.move_down 10
  end

  # Renders project and issue descriptions
  def render_report_descriptions(pdf, report)
    pdf.font "Helvetica", size: 11, style: :bold
    pdf.text "Project Description:"
    pdf.font "Helvetica", size: 10
    pdf.text report.project_description
    pdf.move_down 10

    pdf.font "Helvetica", size: 11, style: :bold
    pdf.text "Issue Description:"
    pdf.font "Helvetica", size: 10
    pdf.text report.issue_description
    pdf.move_down 10
  end

  # Renders timeline and financial impacts
  def render_report_impacts(pdf, report)
    if report.timeline_impact.present?
      pdf.font "Helvetica", size: 10, style: :bold
      pdf.text "Timeline Impact: ", inline: true
      pdf.font "Helvetica", size: 10
      pdf.text report.timeline_impact, inline: true
      pdf.move_down 5
    end

    if report.financial_impact.present?
      pdf.font "Helvetica", size: 10, style: :bold
      pdf.text "Financial Impact: ", inline: true
      pdf.font "Helvetica", size: 10
      pdf.text report.financial_impact, inline: true
      pdf.move_down 5
    end
  end

  # Renders departments and issue categories
  def render_report_metadata(pdf, report)
    if report.departments.any?
      pdf.font "Helvetica", size: 10, style: :bold
      pdf.text "Departments: ", inline: true
      pdf.font "Helvetica", size: 10
      pdf.text report.departments.join(", "), inline: true
      pdf.move_down 5
    end

    if report.issue_categories.any?
      pdf.font "Helvetica", size: 10, style: :bold
      pdf.text "Issue Categories: ", inline: true
      pdf.font "Helvetica", size: 10
      pdf.text report.issue_categories.join(", "), inline: true
      pdf.move_down 5
    end
  end

  # Renders solution ideas if present
  def render_report_solutions(pdf, report)
    return unless report.solution_ideas.present?

    pdf.move_down 5
    pdf.font "Helvetica", size: 11, style: :bold
    pdf.text "Solution Ideas from Submitter:"
    pdf.font "Helvetica", size: 10
    pdf.text report.solution_ideas
  end

  # Helper methods for text generation

  def date_range_text
    "#{start_date.strftime('%B %d, %Y')} - #{end_date.strftime('%B %d, %Y')}"
  end

  def summary_text
    "This report documents #{stats[:total_count]} verified reports of bureaucratic barriers " \
    "in LA's building process, collected between #{start_date.strftime('%B %d, %Y')} " \
    "and #{end_date.strftime('%B %d, %Y')}."
  end
end
