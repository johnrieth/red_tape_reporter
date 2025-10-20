# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Only seed development data in non-production environments
unless Rails.env.production?
  puts "Seeding development data..."

  # Create verified reports for testing the story counter
  sample_reports = [
    {
      email: "sarah.builder@example.com",
      project_type: "Accessory dwelling unit (ADU)",
      project_description: "Building a 600 sq ft ADU in my backyard for my aging mother",
      location: "Echo Park, 90026",
      issue_description: "Applied for ADU permit in January 2024. It's now October and still waiting. LADBS asked for the same drainage plan THREE times. Each time I paid my architect $800 to resubmit the exact same document. No one can tell me when I'll get approved or why they keep asking for the same thing.",
      timeline_impact: "6-12 months",
      financial_impact: "$2,400 in duplicate architect fees, $12,000 in holding costs on construction loan",
      issue_categories: ["Permits", "Plan review", "Fees"],
      departments: ["Building & Safety"],
      anonymous: true,
      verified_at: 2.weeks.ago
    },
    {
      email: "mike.developer@example.com",
      project_type: "New construction",
      project_description: "Small 4-unit apartment building on vacant lot",
      location: "South LA, 90003",
      issue_description: "Zoning department said my project was compliant. Started permit process and Building & Safety said zoning was wrong. Went back to zoning, they insisted they were right. Been ping-ponging between departments for 8 months. Each department blames the other. $40k spent on plans that may be worthless.",
      timeline_impact: "6-12 months",
      financial_impact: "$40,000 in architectural plans, $6,000/month property taxes on vacant lot",
      issue_categories: ["Permits", "Zoning", "Plan review"],
      departments: ["Building & Safety", "Planning"],
      anonymous: true,
      verified_at: 1.week.ago
    },
    {
      email: "lisa.homeowner@example.com",
      project_type: "Renovation / Remodel",
      project_description: "Converting garage to office space",
      location: "Silver Lake",
      issue_description: "Simple garage conversion. Inspector came out, failed us for 'improper ventilation.' We fixed it exactly as he specified. Different inspector came next time, failed us for 'excessive ventilation.' Third inspector told us the first guy was wrong. Now we're scheduled for a fourth inspection next month. Been unable to use the space for 5 months.",
      timeline_impact: "3-6 months",
      financial_impact: "$3,000 in additional contractor fees for multiple fixes",
      issue_categories: ["Inspections"],
      departments: ["Building & Safety"],
      anonymous: true,
      verified_at: 3.days.ago
    },
    {
      email: "james.contractor@example.com",
      project_type: "Accessory dwelling unit (ADU)",
      project_description: "Pre-approved ADU design from city's approved plans list",
      location: "Mar Vista, 90066",
      issue_description: "Used one of the city's own pre-approved ADU plans. LADBS plan checker said it doesn't meet setback requirements. Showed them it's literally their approved design. They said 'things have changed' but couldn't tell me what. Now being told I need to hire an architect to modify the city's own approved plan.",
      timeline_impact: "3-6 months",
      financial_impact: "$5,000 for architect to modify pre-approved plans",
      issue_categories: ["Permits", "Plan review"],
      departments: ["Building & Safety"],
      anonymous: true,
      verified_at: 5.days.ago
    },
    {
      email: "rachel.landlord@example.com",
      project_type: "Renovation / Remodel",
      project_description: "Upgrading 1940s apartment building electrical system",
      location: "Koreatown, 90020",
      issue_description: "Required electrical upgrade for tenant safety. Permit application has been 'under review' for 7 months. Called every week for 4 months - told different things each time. Finally got through to supervisor who said our application was lost. Had to resubmit everything. Now they say we need additional permits we were never told about initially.",
      timeline_impact: "6-12 months",
      financial_impact: "$15,000 in delayed construction costs, tenants at risk with outdated wiring",
      issue_categories: ["Permits", "Plan review"],
      departments: ["Building & Safety", "Fire Department"],
      anonymous: true,
      verified_at: 1.day.ago
    },
    {
      email: "david.architect@example.com",
      project_type: "New construction",
      project_description: "Single-family home on vacant lot",
      location: "Highland Park, 90042",
      issue_description: "Plan check comments are often contradictory. One reviewer says add more detail to plans, next reviewer says too much detail, simplify. Submitted plans 4 times now. Each review takes 6-8 weeks. Same issues keep coming up that we've already addressed. No way to speak directly to the person reviewing.",
      timeline_impact: "More than 12 months",
      financial_impact: "$12,000 in plan revision costs, client threatening to abandon project",
      issue_categories: ["Permits", "Plan review"],
      departments: ["Building & Safety", "Planning"],
      anonymous: true,
      verified_at: 2.days.ago
    },
    {
      email: "carmen.homeowner@example.com",
      project_type: "Accessory dwelling unit (ADU)",
      project_description: "Converting existing permitted structure to ADU",
      location: "West Adams",
      issue_description: "Structure has been permitted as a 'recreation room' for 30 years. Want to convert to ADU. Planning says it should be easy. Building & Safety says the original 1990s permits are incomplete and I need to re-permit the entire structure before converting to ADU. Would cost $25k+ to re-permit a legal building that's been standing for 30 years.",
      timeline_impact: "6-12 months",
      financial_impact: "$25,000+ estimated to re-permit existing legal structure",
      issue_categories: ["Permits", "Zoning"],
      departments: ["Building & Safety", "Planning"],
      anonymous: true,
      verified_at: 4.days.ago
    },
    {
      email: "tony.builder@example.com",
      project_type: "Renovation / Remodel",
      project_description: "Kitchen and bathroom remodel",
      location: "Valley Village, 91607",
      issue_description: "Straightforward kitchen/bath remodel. Everything permitted and inspected. Final inspection scheduled 3 times - inspector no-showed all three times. Office says 'inspectors are busy.' Been waiting 2 months for final. Can't get certificate of occupancy. Can't close out contractor. Contractor threatening to put lien on property.",
      timeline_impact: "3-6 months",
      financial_impact: "$8,000 holding final contractor payment, risk of property lien",
      issue_categories: ["Inspections"],
      departments: ["Building & Safety"],
      anonymous: true,
      verified_at: 6.days.ago
    }
  ]

  sample_reports.each do |report_data|
    # Use find_or_create_by to make this idempotent
    report = Report.find_or_initialize_by(email: report_data[:email], project_description: report_data[:project_description])

    if report.new_record?
      report.assign_attributes(report_data)
      report.status = "new"
      report.verification_token = SecureRandom.urlsafe_base64(32)

      if report.save
        puts "✓ Created verified report: #{report.project_type} in #{report.location}"
      else
        puts "✗ Failed to create report: #{report.errors.full_messages.join(', ')}"
      end
    else
      puts "- Report already exists: #{report.project_type} in #{report.location}"
    end
  end

  puts "\nSeeding complete!"
  puts "Total reports: #{Report.count}"
  puts "Verified reports: #{Report.verified.count}"
else
  puts "Production environment detected - skipping seed data"
end
