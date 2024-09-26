defmodule WeatherWebApiMock do
  require Logger

  def raw_html(url) do
    Logger.debug("Starting WeatherWebApiMock.raw_html for #{url}")

    file =
      case url do
        "https://m.met.hu/balaton/telepules/balatonfured" ->
          "test/data/balatonfured_api_response.2024.05.21.html"

        "https://csopak.hu/weatherinfo/forecast" ->
          "test/data/csopak_api_response.2024.05.21.html"

        _ ->
          "N/A"
      end

    Logger.debug("Target file → #{file}")

    respponse_type = System.get_env("TEST_HTTP_RESPONSE_TYPE")
    IO.puts("respponse_type → #{respponse_type}")

    case respponse_type do
      "success" ->
        {:ok, file_contents} = File.read(file)
        file_contents

      "timex_parse_error" ->
        "<html><head></head><body><div class='idopont'>invalid format</div></body></html>"

      "floki_parse_error" ->
        "<html><head></head><body></body>"

      "http_error" ->
        {:error, %HTTPoison.Error{reason: :closed}}

      _ ->
        Logger.error(
          "You need to set the TEST_HTTP_RESPONSE_TYPE to success|timex_parse_error|floki_parse_error|http_error"
        )

        exit(:shutdown)
    end
  end
end
