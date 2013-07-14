module StocksHelper
  def format_field cell
    case cell
    when Float
      sprintf "%.2f", cell
    else
      cell
    end
  end
end
