defmodule CollectorTest do
  use ExUnit.Case

  test "Csopak returns correct data" do
    observation = Processor.retrieve(Csopak)

    {expected_date, expected_weather_map} = {
      ~U[2024-05-21 02:40:00Z],
      %{wind_avg: 0.77753808, wind_direction: 86, mslp: 804.6, rh: 93.1, temperature: 17.7, water_temperature: 22.0}
    }

    {d, w} = Csopak.to_map(observation)

    assert {expected_date, expected_weather_map} == {d, w}
  end

  test "Balatonfured returns correct data" do
    observation = Processor.retrieve(Balatonfured)

    {expected_date, expected_weather_map} = {
      ~U[2024-05-21 07:55:00Z],
      %{wind_avg: 10.259183, wind_direction: 39, wind_max: 15.118796}
    }

    {d, w} = Balatonfured.to_map(observation)

    assert {expected_date, expected_weather_map} == {d, w}
  end

end
