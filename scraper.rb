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

# Step 3: Find the targeted section that contains the table
section = doc.at_css('.copy-block.px-5')
if section
  logger.info("Section with table found.")
else
  logger.error("Section with class 'copy-block px-5' not found.")
  exit
end

# Step 4: Skip the first two <p> tags
paragraphs = section.css('p')
if paragraphs.count >= 2
  logger.info("Skipping first two <p> tags.")
  # Remove the first two <p> tags to avoid logging them
  paragraphs[0..1].each(&:remove)
end

# Step 5: Find the table
table = section.at_css('table')
if table
  logger.info("Table found inside the section.")
else
  logger.error("Table inside the section not found.")
  exit
end

# Log the full HTML of the table for verification
logger.info("Table HTML: #{table.to_html}")

# Step 6: Log the rows inside the table
rows = table.css('tr')
logger.info("Found #{rows.count} rows in the table.")

# Step 7: Initialize the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create the table if it doesn't exist
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS meander_valley (
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

# Extract data for each row inside the table
rows.each_with_index do |row, index|
  # Log each row for inspection
  logger.info("Extracting data for row #{index + 1}")
  logger.info("Row HTML: #{row.to_html}")

  # Extract the relevant data from each row
  council_reference = row.at_css('a') ? row.at_css('a').text.strip : "No reference"
  applicant = row.at_css('strong:contains("Applicant:")') ? row.at_css('strong:contains("Applicant:")').next.text.strip : "No applicant"
  address = row.at_css('strong:contains("Property:")') ? row.at_css('strong:contains("Property:")').next.text.strip : "No address"
  stage_description = row.at_css('strong:contains("Proposal:")') ? row.at_css('strong:contains("Proposal:")').next.text.strip : "No description"
  on_notice_to = row.at_css('strong:contains("Closes:")') ? row.at_css('strong:contains("Closes:")').next.text.strip : "No closing date"

  logger.info("Council Reference: #{council_reference}")
  logger.info("Applicant: #{applicant}")
  logger.info("Address: #{address}")
  logger.info("Stage Description: #{stage_description}")
  logger.info("On Notice To: #{on_notice_to}")

  date_scraped = Date.today.to_s

  # Format the date in ISO 8601 format
  date_received = Date.strptime(on_notice_to, "%A %d %B %Y").to_s rescue "Invalid date"

  # Extract the document description from href links
  document_description = row.at_css('a') ? row.at_css('a')['href'] : ''

  # Log the extracted data for debugging purposes
  logger.info("Extracted Data: #{council_reference}, #{address}, #{stage_description}, #{on_notice_to}, #{date_received}, #{document_description}")

  # Step 6: Ensure the entry does not already exist before inserting
  existing_entry = db.execute("SELECT * FROM meander_valley WHERE council_reference = ?", council_reference )

  if existing_entry.empty? # Only insert if the entry doesn't already exist
    # Save data to the database
    db.execute("INSERT INTO meander_valley 
      (description, date_scraped, date_received, on_notice_to, address, council_reference, applicant, owner, stage_description, stage_status, document_description, title_reference)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
      [document_description, date_scraped, date_received, on_notice_to, address, council_reference, applicant, nil, stage_description, nil, document_description, nil])

    logger.info("Data for #{council_reference} saved to database.")
  else
    logger.info("Duplicate entry for application #{council_reference} found. Skipping insertion.")
  end
end

# Finish
logger.info("Data has been successfully inserted into the database.")
