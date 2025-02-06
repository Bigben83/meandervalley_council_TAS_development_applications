require 'selenium-webdriver'
require 'sqlite3'
require 'logger'
require 'date'

# Initialize the logger
logger = Logger.new(STDOUT)

# Define the URL
url = 'https://www.meander.tas.gov.au/advertised-approved-planning-applications/'

# Step 1: Set up Selenium WebDriver (use ChromeDriver or FirefoxDriver)
driver = Selenium::WebDriver.for :chrome  # You can also use :firefox
driver.get(url)

# Step 2: Wait for the page to load (this can be adjusted based on the page load speed)
wait = Selenium::WebDriver::Wait.new(timeout: 10)  # Wait up to 10 seconds
wait.until { driver.find_element(css: 'table') }  # Wait for the table element

# Step 3: Extract page content
page_html = driver.page_source

# Step 4: Parse the HTML with Nokogiri
doc = Nokogiri::HTML(page_html)

# Continue with your scraping logic as you did with Nokogiri
# For example, extracting the table and rows
table = doc.at_css('.copy-block.px-5 table')

if table
  logger.info("Table found inside the section.")
else
  logger.error("Table inside the section not found.")
end
