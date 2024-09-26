defmodule Balatonfured do
  import Utilities, only: [log_fn_start: 0]

  # WG related data for this station
  def uid(), do: System.fetch_env!("FURED_WEATHER_UID")
  def password(), do: System.fetch_env!("FURED_WEATHER_API_PASSWORD")

  # Source related data
  def url(), do: "https://m.met.hu/balaton/telepules/balatonfured"

  def parse(html) do
    log_fn_start()
    require Logger
    import Utilities, only: [remove_all: 2, kph_to_knots: 1]

    # idopont should look like this → "HungaroMet 2023.08.21. 17:35"
    idopont = Floki.find(html, ".idopont") |> hd |> elem(2) |> hd
    Logger.debug("idopont → #{idopont}")

    # drop "HungaroMet" string (used to be OMSZ), keep YYYY.MM.DD. and HH:MM and join them by a space
    idopont = String.split(idopont) |> Enum.drop(1) |> Enum.join(" ")
    Logger.debug("idopont → #{idopont}")

    {:ok, naive_date_time} = idopont |> Timex.parse("%Y.%m.%d. %H:%M", :strftime)
    Logger.debug("naive_date_time → #{naive_date_time}")

    date = naive_date_time |> Timex.to_datetime()
    Logger.debug("date → #{date}")

    # ["Széllökés:", "Beaufort fokozat:", "Irány:", "Átlagszél:", "Beaufort fokozat:", "Irány:"]
    bal = Enum.map(Floki.find(html, ".cella_bal"), fn x -> x |> elem(2) end)
    Logger.debug("bal → #{bal}")
    bal = Enum.map(bal, fn y -> List.to_string(y) end)
    bal = Enum.map(bal, fn x -> String.trim(x) end)

    # MET to WG terminology
    # [:wind_max, :na, :wind_direction, :wind_avg, :"Beaufort fokozat:", :wind_direction]
    bal =
      Enum.map(bal, fn x ->
        x
        |> String.replace("Irány:", "wind_direction")
        |> String.replace("Átlagszél:", "wind_avg")
        |> String.replace("Széllökés:", "wind_max")
        |> String.replace("Beaufort fokozat:", "na")
        |> String.to_atom()
      end)

    # ["5", "1", "180°", "4", "1", "181°"]
    jobb = Enum.map(Floki.find(html, ".cella_jobb"), fn x -> x |> elem(2) end)
    jobb = Enum.map(jobb, fn y -> List.to_string(y) end)
    jobb = Enum.map(jobb, fn x -> remove_all(x, ["\n", "km/h"]) end)

    # %{
    #  na: "1",
    #  wind_avg: "5",
    #  wind_direction: "248°",
    #  wind_max: "7"
    # }
    key_value_pairs = bal |> Enum.zip(jobb) |> Map.new()

    # %{wind_avg: "5", wind_direction: "248°", wind_max: "7"}
    key_value_pairs = Map.delete(key_value_pairs, :na)

    # %{wind_avg: 2.6997850000000003, wind_direction: 248, wind_max: 3.779699}
    {_, key_value_pairs} =
      Map.get_and_update(key_value_pairs, :wind_avg, fn x ->
        {x, kph_to_knots(Float.parse(x) |> elem(0))}
      end)

    {_, key_value_pairs} =
      Map.get_and_update(key_value_pairs, :wind_max, fn x ->
        {x, kph_to_knots(Float.parse(x) |> elem(0))}
      end)

    {_, key_value_pairs} =
      Map.get_and_update(key_value_pairs, :wind_direction, fn x ->
        {x, Integer.parse(x) |> elem(0)}
      end)

    # {
    #  ~U[2023-08-21 18:25:00Z],
    #  %{wind_avg: 2.6997850000000003, wind_direction: 248, wind_max: 3.779699}
    # }
    to_observation(date, key_value_pairs)
  end

  def to_map(observation) do
    log_fn_start()

    m = Map.from_struct(observation)
    date_time = m[:datetime]

    observation_map =
      Map.from_struct(observation)
      |> Map.delete(:id)
      |> Map.delete(:location)
      |> Map.delete(:mslp)
      |> Map.delete(:rh)
      |> Map.delete(:temperature)
      |> Map.delete(:water_temperature)
      |> Map.delete(:datetime)
      |> Map.delete(:__meta__)

    {date_time, observation_map}
  end

  defp to_observation(date, observation_map) do
    %Observation{
      datetime: date,
      wind_avg: observation_map.wind_avg,
      wind_direction: observation_map.wind_direction,
      wind_max: observation_map.wind_max,
      # location 2 is fured
      location: 2
    }
  end
end
