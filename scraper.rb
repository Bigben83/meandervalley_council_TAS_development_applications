const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  await page.goto('https://www.meander.tas.gov.au/advertised-approved-planning-applications/');
  
  const data = await page.evaluate(() => {
    const rows = [];
    document.querySelectorAll('table tbody tr').forEach(row => {
      const councilReference = row.querySelector('a').innerText;
      const address = row.querySelector('strong:contains("Property:")').nextElementSibling.textContent;
      const dateReceived = row.querySelector('strong:contains("Closes:")').nextElementSibling.textContent;
      
      rows.push({ councilReference, address, dateReceived });
    });
    return rows;
  });
  
  console.log(data);
  await browser.close();
})();
