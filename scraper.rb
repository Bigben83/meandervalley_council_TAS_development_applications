require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'date'

logger = Logger.new(STDOUT)

url = 'https://www.meander.tas.gov.au/advertised-approved-planning-applications/'

begin
  logger.info("Fetching page content from: #{url}")
  page_html = open(url, "User-Agent" => "Mozilla/5.0").read
  logger.info("Successfully fetched page content.")
rescue => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end

doc = Nokogiri::HTML(page_html)

# Initialize SQLite DB
db = SQLite3::Database.new "data.sqlite"

db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS meander (
    id INTEGER PRIMARY KEY,
    council_reference TEXT,
    applicant TEXT,
    address TEXT,
    description TEXT,
    on_notice_to TEXT,
    document_url TEXT,
    date_scraped TEXT
  );
SQL

base_url = "https://www.meander.tas.gov.au"
date_scraped = Date.today.to_s

doc.css('table tbody tr').each do |row|
  # Council Reference & Document URL
  app_link = row.at_css('a')
  council_reference = app_link ? app_link.text.strip.gsub('\\', '/') : 'Reference not found'
  document_url = app_link ? base_url + app_link['href'] : 'URL not found'

  # Applicant
  applicant_node = row.at_css('strong:contains("Applicant:")')
  applicant = applicant_node ? applicant_node.next.text.strip : 'Applicant not found'

  # Address (Property)
  property_node = row.at_css('strong:contains("Property:")')
  address = property_node ? property_node.next.text.strip : 'Address not found'

  # Proposal (Description)
  proposal_node = row.at_css('strong:contains("Proposal:")')
  description = proposal_node ? proposal_node.next.text.strip : 'Description not found'

  # On Notice To (Closes Date)
  closes_match = row.to_s.match(/Closes:<\/strong>\s*(.+?)<\/p>/)
  on_notice_to = closes_match ? closes_match[1].strip : 'Closing Date not found'

  # Logging extracted info
  logger.info("Council Reference: #{council_reference}")
  logger.info("Applicant: #{applicant}")
  logger.info("Address: #{address}")
  logger.info("Description: #{description}")
  logger.info("On Notice To: #{on_notice_to}")
  logger.info("Document URL: #{document_url}")
  logger.info("-----------------------------------")

  # Check if entry exists
  existing_entry = db.execute("SELECT * FROM meander WHERE council_reference = ?", council_reference)
  if existing_entry.empty?
    db.execute("INSERT INTO meander (council_reference, applicant, address, description, on_notice_to, document_url, date_scraped)
                VALUES (?, ?, ?, ?, ?, ?, ?)",
                [council_reference, applicant, address, description, on_notice_to, document_url, date_scraped])
    logger.info("Data for #{council_reference} saved to database.")
  else
    logger.info("Duplicate entry for #{council_reference} found. Skipping.")
  end
end

logger.info("Scraping completed.")
