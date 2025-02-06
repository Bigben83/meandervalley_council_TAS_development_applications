# Require library
require "capybara"
require "selenium-webdriver"

Capybara.register_driver :selenium_chrome_headless_morph do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.args << '--headless'
    opts.args << '--disable-gpu' if Gem.win_platform?
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.args << '--disable-site-isolation-trials'
    opts.args << '--no-sandbox'
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

# Open a Capybara session with the Selenium web driver for Chromium headless
driver = Capybara::Session.new(:selenium_chrome_headless_morph)

driver.visit("https://www.meander.tas.gov.au/advertised-approved-planning-applications/")

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
