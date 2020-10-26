require 'watir'

class Scraper
    
    def openBrowser # use chrome browser
      @browser = Watir::Browser.new(:chrome)
    end

    def accessAccountsPage
        url = "https://demo.bendigobank.com.au/banking/sign_in"
        @browser.goto(url)
        sleep 5
        @browser.button(:class, "input_submit").click
        @browser.li("data-semantic" => "account-item").wait_until_present
    end
end

scraper = Scraper.new
scraper.openBrowser
scraper.accessAccountsPage
