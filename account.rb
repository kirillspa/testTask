require 'json'

class Account
  attr_accessor :name, :currency, :balance, :nature, :transactions

  def initialize(name, currency, balance, nature, transactions = [])
    @name = name
    @currency = currency
    @balance = balance
    @nature = nature
    @transactions = transactions
  end

  def to_hash
    {
      :name => @name,
      :currency => @currency,
      :balance => @balance,
      :nature => @nature,
      :transactions => @transactions.map { |transaction| transaction.to_hash}
    }
  end
end