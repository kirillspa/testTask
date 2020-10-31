require 'watir'
require_relative 'account'

class Scraper
  attr_accessor :accounts, :browser

  def openBrowser # use chrome browser
    @browser = Watir::Browser.new(:chrome)
  end

  def accessAccountsPage
    url = "https://demo.bendigobank.com.au/banking/sign_in"
    @browser.goto(url)
    @browser.button(class: "input_submit", text: "Launch Business Demo").wait_until_present
    @browser.button(class: "input_submit", text: "Launch Business Demo").click
    @browser.li("data-semantic" => "account-item").wait_until_present
  end

  def extractAccountsData

    @accounts = browser.lis("data-semantic" => "account-item").map do |item|
      currency = get_currency( item.span("data-semantic" => "available-balance").text)
      nature = get_nature(item.div("data-semantic" => "account-name").text)
      Account.new(
        item.div("data-semantic" => "account-name").text,
        currency,
        item.span("data-semantic" => "available-balance").text.each_char.map { |char| char[/\d|[.]/] }.join.to_f,
        nature
      )
    end
  end   

  def accessTransactionsPage
    @accounts.each do |account|
    @browser.div(class: "css-aralps", text: account.name).parent.parent.parent.parent.click
    sleep 5
    end
  end

  def printAccountsJson
    accountsJson = {:accounts => @accounts.map { |account| account.to_hash},
  }
    puts JSON.pretty_generate(accountsJson)
  end

  def get_currency(text)
    case text
    when /$/ then "AUD"
    when /eur/ then "EUR"
    else "USD"
    end
  end

  def get_nature(text)
    case text
    when /card/i then "Card"
    when /loan/i then "Loan" 
    when /deposit/i then "Deposit"
    else "Account"
    end
  end

end

    scraper = Scraper.new
    scraper.openBrowser
    scraper.accessAccountsPage
    scraper.extractAccountsData
    scraper.accessTransactionsPage
    scraper.printAccountsJson
