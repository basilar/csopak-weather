defmodule WeatherWebApi do
  import Utilities, only: [log_fn_start: 0]

  def raw_html(url) do
    log_fn_start()

    response = HTTPoison.get!(url)
    {:ok, html} = Floki.parse_document(response.body)
    html
  end
end
