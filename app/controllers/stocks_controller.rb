require 'open-uri'
require 'csv'

class StocksController < ApplicationController

  ADJ_CLOSE_INDEX = 6
  ADJ_CLOSE_CHG_INDEX = 7

  # TODO move into initializer
  Array.class_eval do
    def mean
      sum * 1.0 / size
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
      change_mean_row = []
      (ADJ_CLOSE_CHG_INDEX - 1).times { change_mean_row << "" }
      change_mean_row << "Mean:"
      change_mean_row << rows.map{ |r| r[ADJ_CLOSE_CHG_INDEX] }.compact.mean.round(2)
      rows << change_mean_row

      reliability_row = []
      (ADJ_CLOSE_CHG_INDEX - 1).times { reliability_row << "" }
      reliability_row << "Reliability:"
      reliability_row << calc_reliability(rows)
      rows << reliability_row
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

  def calc_reliability monthly_data
    last_index = monthly_data.length - 1
    mean = monthly_data[last_index][-1]
    cmp = if mean > 0
            :>
          elsif mean < 0
            :<
          else
            :==
          end
    reliable_count = 0
    all_count = 0
    monthly_data.each_with_index do |row, i|
      break if i == last_index
      next if row[ADJ_CLOSE_CHG_INDEX].blank?
      all_count += 1
      reliable_count += 1 if row[ADJ_CLOSE_CHG_INDEX].send(cmp, 0)
    end
    (reliable_count * 1.0) / all_count * 100
  rescue ZeroDivisionError
    0
  end
end
