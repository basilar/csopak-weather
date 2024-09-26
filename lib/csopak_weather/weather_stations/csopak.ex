defmodule Csopak do
  import Utilities, only: [log_fn_start: 0]

  # WG related data for this station
  def uid(), do: System.fetch_env!("CSOPAK_WEATHER_UID")
  def password(), do: System.fetch_env!("CSOPAK_WEATHER_API_PASSWORD")

  # Source related data
  def url(), do: "https://csopak.hu/weatherinfo/forecast"

  def parse(html) do
    log_fn_start()
    import Utilities, only: [nums_only: 1, to_numerical_with_conversions: 1]

    hungarian_data_with_trailing_date =
      Enum.chunk_every(
        Enum.map(Floki.find(html, ".localinfo_td_text"), fn x -> nums_only(x) end),
        2
      )

    hungarian_key_value_pairs = Enum.drop(hungarian_data_with_trailing_date, -1)
    # if there are N/A values, then the station misbehaves, indicate failure to collect
    no_n_per_a_values = nil == Enum.find(hungarian_key_value_pairs, fn [_, v] -> v == "N/A" end)

    if no_n_per_a_values do
      # convert returned date (string) to a real date
      require Logger
      Logger.debug("date is → #{hungarian_data_with_trailing_date}")
      date_str = hungarian_data_with_trailing_date |> List.last() |> hd

      {:ok, naive_date_time} = date_str |> Timex.parse("%Y.%m.%d %H:%M", :strftime)
      date = naive_date_time |> Timex.to_datetime()

      # remap hungarian phrases to WG terms and take single element embedded in array returned
      english_key_value_pairs =
        Enum.map(hungarian_key_value_pairs, fn x -> translate_keys(x) end)
        |> Enum.map(fn [a, b] -> {a, b} end)
        |> Map.new()

      converted_map = to_numerical_with_conversions(english_key_value_pairs) |> Enum.into(%{})

      # {~U[2023-08-08 04:30:00Z],
      #  %{
      #    mslp: 804.6,
      #    rh: 64.3,
      #    temperature: 15.1,
      #    water_temperature: 18.8,
      #    wind_avg: 3.11015232,
      #    wind_direction: 282
      #  }}
      to_observation(date, converted_map)
    else
      nil
    end
  end

  def to_map(observation) do
    log_fn_start()

    m = Map.from_struct(observation)
    date_time = m[:datetime]

    observation_map =
      Map.from_struct(observation)
      |> Map.delete(:id)
      |> Map.delete(:location)
      |> Map.delete(:datetime)
      |> Map.delete(:wind_max)
      |> Map.delete(:__meta__)

    {date_time, observation_map}
  end

  # private helper functions
  defp translate_keys([key, value]) do
    [
      key
      # Csopak webstation only terminology
      |> String.replace("Levegő hőmérséklete:", "temperature")
      |> String.replace("Víz hőmérséklete:", "water_temperature")
      |> String.replace("Légnyomás:", "mslp")
      |> String.replace("Páratartalom:", "rh")
      |> String.replace("Szél:", "wind_avg")
      |> String.replace("Szélirány:", "wind_direction")
      |> String.to_atom(),
      value
    ]
  end

  defp to_observation(date, observation_map) do
    %Observation{
      datetime: date,
      mslp: observation_map.mslp,
      rh: observation_map.rh,
      temperature: observation_map.temperature,
      water_temperature: observation_map.water_temperature,
      wind_avg: observation_map.wind_avg,
      wind_direction: observation_map.wind_direction,
      # location 1 is csopak
      location: 1
    }
  end
end
