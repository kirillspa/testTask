require 'watir'
require 'active_support/time'
require_relative 'account'
require_relative 'transaction'
require 'nokogiri'

class Scraper
    attr_accessor :accounts, :browser, :transactions
  
    def openBrowser # use chrome browser
      @browser = Watir::Browser.new(:chrome)
    end

    def accessAccountsPage
      url = "https://demo.bendigobank.com.au/banking/sign_in"
      @browser.goto(url)
      @browser.driver.manage.window.maximize
      @browser.button(class: "input_submit", text: "Launch Business Demo").wait_until(&:present?)
      @browser.button(class: "input_submit", text: "Launch Business Demo").click
      @browser.li("data-semantic" => "account-item").wait_until(&:present?)
    end

    def extractAccountsData
     parsed_page = Nokogiri::HTML.parse(browser.html)
     @accounts = parsed_page.css("li[data-semantic='account-item']").map do |item|
        currency = get_currency(item.css("span[data-semantic='available-balance']").text)
        nature = get_nature(item.css("div[class='css-aralps']").text)
        Account.new(
          item.css("div[class='css-aralps']").text,
          currency,
          item.css("span[data-semantic='available-balance']").text.each_char.map { |char| char[/\d|[.]/] }.join.to_f,
          nature
        )
      end   
    end

      def accessTransactionsPage
        @transactions = []
        @accounts.each do |account|
          @browser.div(class: "css-aralps", text: account.name).parent.parent.parent.parent.click
          @browser.link(class: "segmented-control__item", text: "Activity").wait_until(&:present?)
          @browser.link(class: "segmented-control__item", text: "Activity").click
          @browser.link(class: "_1hzCXGy_Ye", text: "Filter").wait_until(&:present?)
          @browser.link(class: "_1hzCXGy_Ye", text: "Filter").click
          @browser.link(class: "panel--bordered__item", text: "All time").wait_until(&:present?)
          @browser.link(class: "panel--bordered__item", text: "All time").click
          @browser.span("data-semantic" => "name", text: "Custom Date Range").parent.parent.parent.parent.parent.parent.click
          @browser.text_field("data-semantic" => "filter-from-date-input").set((Time.now - 2.month).strftime("%d/%m/%Y"))
          @browser.text_field("data-semantic" => "filter-to-date-input").set((Time.now).strftime("%d/%m/%Y"))
          @browser.button(class: "button--primary", text: "Apply Filter").click
          @browser.button(class: "button--primary", text: "Apply Filters").click
          sleep 3
          parsed_page = Nokogiri::HTML.parse(browser.html)

          parsed_page.css("li[class='grouped-list__group']").each do |dates|
            #puts dates.text
            dates.css("li[data-semantic='activity-item']").each do |item|
              currency = get_currency(item.css("span[data-semantic='amount']").text)
              @transactions << Transaction.new(
                  dates.css("h3[class='grouped-list__group__heading']").text, #date
                  item.css("span[class='overflow-ellipsis']").text, #description
                  item.css("span[data-semantic='amount']").text.each_char.map { |char| char[/\d|[.]|[-]|[+]/] }.join.to_f, #amount
                  currency,
                  account.name
                )
            end
          end
        end 
      end
    
      def printAccountsJson
        accountsJson = {:accounts => @accounts.map { |account| account.to_hash},
      }
        puts JSON.pretty_generate(accountsJson)
      end

      def printLastTwoMonthsTransactionsJson
        transactionsJson = {:transactions => @transactions.map { |transaction| transaction.to_hash},
      }
        puts JSON.pretty_generate(transactionsJson)
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

      def assigneaccountwithtransactions
        @accounts.each do |account|
          account.transactions = @transactions.select {|transaction| transaction.account_name == account.name}
        end
      end

      def closeBrowser
        @browser.close
      end

    end

    
    
    scraper = Scraper.new
    scraper.openBrowser
    scraper.accessAccountsPage
    scraper.extractAccountsData
    scraper.accessTransactionsPage
    scraper.printAccountsJson
    scraper.printLastTwoMonthsTransactionsJson
    scraper.assigneaccountwithtransactions
    scraper.printAccountsJson
    scraper.closeBrowser