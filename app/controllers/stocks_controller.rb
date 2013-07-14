require 'open-uri'
require 'csv'

class StocksController < ApplicationController

  ADJ_CLOSE_INDEX = 6
  ADJ_CLOSE_CHG_INDEX = 7

  # TODO move into initializer
  Array.class_eval do
    def mean
      a = compact
      a.sum * 1.0 / a.size
    end
  end

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

    @tabular_stock_data.each_with_index do |e, i|
      next_e = @tabular_stock_data[i+1]
      e << calc_adj_close_changes_pct(e, next_e)
    end

    @tabular_stock_data = @tabular_stock_data.group_by { |d| d[0].strftime('%B') }

    @tabular_stock_data.each do |month, rows|
      rows.unshift [rows.map{ |r| r[ADJ_CLOSE_CHG_INDEX] }.mean.round(2)]
    end

  rescue OpenURI::HTTPError
    flash[:error] = "cannot retrieve data for stock #{@symbol}"
    render :index
  end

  private

  def calc_adj_close_changes_pct current_row, prev_row
    if current_row.blank? || prev_row.blank?
      nil
    else
      ((current_row[ADJ_CLOSE_INDEX] - prev_row[ADJ_CLOSE_INDEX]) / prev_row[ADJ_CLOSE_INDEX] * 100).round(2)
    end
  end
end
