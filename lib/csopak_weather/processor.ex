defmodule Processor do
  import Utilities, only: [log_fn_start: 0]
  require Logger

  def event_loop() do
    log_fn_start()
    weather_stations = [Csopak, Balatonfured, Balatonalmadi]

    stream =
      Task.async_stream(weather_stations, Processor, :process_weather_station, [],
        max_concurrency: 2
      )

    Stream.run(stream)
  end

  def process_weather_station(weather_station) do
    log_fn_start()

    {observation, failure?, error, stacktrace} = try do
      {Processor.retrieve(weather_station), false, nil, nil}
    rescue
      e -> {nil, true, e, __STACKTRACE__}
    end  

    if not failure? do
      # save to DB if new data or return nil if already present in DB
      nil_for_noop = Processor.persist(observation)

      # post to wg if needed (i.e. if returned non nil)
      case nil_for_noop do
        # nothing to do here, already posted
        nil -> nil
        _ -> Processor.upload(weather_station, observation)
      end
    else
        # we shall never give up, even if all stations are failing, as they might come back up
        # TODO: differentiate various error types (if parsing or network) as from second we can recover
        # TODO: send a message that a certain station fails in retrieve/parse to operations
        Logger.error("weather station data retrieval failed." <> "\n\n" <> Exception.format(:error, error, stacktrace))
    end
  end

  def retrieve(weather_station) do
    log_fn_start()

    api = Application.get_env(:csopak_weather, :weather_web_api)
    html = api.raw_html(weather_station.url)
    weather_station.parse(html)
  end

  def persist(observation) do
    log_fn_start()

    import Ecto.Query, only: [from: 2]

    query =
      from(o in "observation",
        where: o.datetime == ^observation.datetime and o.location == ^observation.location,
        select: o.id
      )

    case Repo.one(query) do
      nil ->
        # entry with given date not in database yet, let us persist it
        Observation.changeset(observation, %{}) |> Repo.insert()
        :ok

      _result ->
        # if entry with given date already in database let us not recreate it
        nil
    end
  end

  defp md5(s), do: :crypto.hash(:md5, s) |> Base.encode16() |> String.downcase()

  # turn a map into HTTP URL parameters
  defp urlise(m), do: Enum.map_join(m, "&", fn {key, val} -> ~s{#{key}=#{val}} end)

  # This sends the data to WG
  def upload(weather_station, observation) do
    log_fn_start()

    uid = weather_station.uid()
    api_password = weather_station.password()

    # Authorization variables
    # ------------------------
    # salt - (required)	any random string, should change with every upload request (you can use current timestamp for example...)
    salt = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string() |> md5

    # hash - (required)	MD5 hash of a string that consists of <salt, uid, weather_station_password> concatenated together (in this order, see example below)
    hash = (salt <> uid <> api_password) |> md5

    base_url = "http://www.windguru.cz/upload/api.php?"

    wg_parameters = %{uid: uid, salt: salt, hash: hash} |> urlise

    {_datetime, observation_map} = weather_station.to_map(observation)

    # data available at some sources, but unavailable at WG
    #  1. "Víz hőmérséklete:", "water_temperature" (celsius)
    wg_compatible_observation_parameters =
      observation_map
      |> Map.delete(:water_temperature)
      |> urlise

    # "post" data
    (base_url <> wg_parameters <> "&" <> wg_compatible_observation_parameters) |> HTTPoison.get!()
  end
end
