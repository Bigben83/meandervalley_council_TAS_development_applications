require 'selenium-webdriver'

# Set up the WebDriver for Chrome (Morph.io supports it)
driver = Selenium::WebDriver.for :chrome

# Navigate to the target page
driver.get "https://www.meander.tas.gov.au/advertised-approved-planning-applications/"

# Wait for the page to load (you might need to adjust the waiting time)
driver.manage.timeouts.implicit_wait = 10 # waits for 10 seconds

# You can now extract the page source
html_source = driver.page_source

# Load the HTML source into Nokogiri to parse it
require 'nokogiri'
doc = Nokogiri::HTML(html_source)

# Example of extracting data from the table
doc.css('table tbody tr').each_with_index do |row, index|
  council_reference = row.at_css('a').text.strip
  address = row.at_css('strong:contains("Property:")').next.text.strip
  date_received = row.at_css('strong:contains("Closes:")').next.text.strip

  puts "Council Reference: #{council_reference}"
  puts "Address: #{address}"
  puts "Date Received: #{date_received}"
  puts "----------------------"
end

# Close the browser when done
driver.quit
