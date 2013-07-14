require 'open-uri'
require 'csv'

class StocksController < ApplicationController
  def index
  end

  def query
    @symbol = params[:symbol]
    @symbol += '.SI' unless @symbol =~ /.+\..+/
    today = Date.today
    url = "http://ichart.finance.yahoo.com/table.csv?s=#{@symbol}&d=#{today.month - 1}&e=#{today.day}&f=#{today.year}&g=m&ignore=.csv"
    csv = CSV.new(open(url), headers: :first_row, converters: [:date, :numeric])
    @stock_data = csv.read
    @tabular_stock_data = @stock_data.to_a
    @tabular_stock_data.slice! 0
    @tabular_stock_data = @tabular_stock_data.group_by { |d| d[0].strftime('%B') }
  rescue OpenURI::HTTPError
    flash[:error] = "cannot retrieve data for stock #{@symbol}"
    render :index
  end
end
