require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'date'
require 'cgi'

# Initialize the logger
logger = Logger.new(STDOUT)

# Define the URL of the page
url = 'https://www.meander.tas.gov.au/advertised-approved-planning-applications/'

# Step 1: Fetch the page content
begin
  logger.info("Fetching page content from: #{url}")
  page_html = open(url).read
  logger.info("Successfully fetched page content.")
rescue => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end

# Step 2: Parse the page content using Nokogiri
doc = Nokogiri::HTML(page_html)

# Open a new SQLite database (or connect to existing one)
db = SQLite3::Database.new 'meander_valley_council.db'

# Create table if not exists
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS meander_valley_council (
id INTEGER PRIMARY KEY,
    description TEXT,
    date_scraped TEXT,
    date_received TEXT,
    on_notice_to TEXT,
    address TEXT,
    council_reference TEXT,
    applicant TEXT,
    owner TEXT,
    stage_description TEXT,
    stage_status TEXT,
    document_description TEXT,
    title_reference TEXT
  );
SQL

# Define variables for storing extracted data for each entry
address = ''  
description = ''
on_notice_to = ''
title_reference = ''
date_received = ''
council_reference = ''
applicant = ''
owner = ''
stage_description = ''
stage_status = ''
document_description = ''
date_scraped = ''

# Extract data for each row
doc.css('table tbody tr').each_with_index do |row, index|
  council_reference = row.at_css('a').text.strip
  applicant = row.at_css('strong:contains("Applicant:")').next.text.strip
  address = row.at_css('strong:contains("Property:")').next.text.strip
  stage_description = row.at_css('strong:contains("Proposal:")').next.text.strip
  on_notice_to = row.at_css('strong:contains("Closes:")').next.text.strip

  date_scraped = Date.today.to_s

  # Format the date in ISO 8601 format
  date_received = Date.strptime(on_notice_to, "%A %d %B %Y").to_s

  # Extract the document description from href links
  document_description = row.at_css('a')['href'] || ''

  # Save data to the database
  db.execute("INSERT INTO meander_valley_council 
    (description, date_scraped, date_received, on_notice_to, address, council_reference, applicant, owner, stage_description, stage_status, document_description, title_reference)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
    [document_description, date_scraped, date_received, on_notice_to, address, council_reference, applicant, nil, stage_description, nil, document_description, nil])

  puts "Extracted Data for Application ##{index+1}: #{council_reference} - #{applicant}"
end
