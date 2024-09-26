defmodule Utilities do
  def remove_all(string, []), do: String.trim(string)

  def remove_all(string, [aSubstring | subStrings]),
    do: remove_all(String.replace(string, aSubstring, ""), subStrings)

  def kph_to_knots(v_in_kph), do: v_in_kph * 0.539957

  # strips of unnecessary measures and parantheses from strings like these
  # "24.7 °C", "21.1 °C", "804.6 mbar", "71.2 %", "0.36 km/h", "146  °", "(2022.05.20 17:20)"
  def nums_only({_, _, [text]}) do
    text |> remove_all(["°C", "mbar", "%", "km/h", "°", "(", ")"])
  end

  def to_numerical_with_conversions(map_with_string_values) do
    Enum.map(map_with_string_values, fn {k, v} ->
      case k do
        :wind_avg -> {k, kph_to_knots(Float.parse(v) |> elem(0))}
        :wind_direction -> {k, Integer.parse(v) |> elem(0)}
        _ -> {k, Float.parse(v) |> elem(0)}
      end
    end)
  end

  # helper to dump module::function names to log
  defmacro log_fn_start() do
    require Logger

    Logger.info("#{__CALLER__.module}::#{elem(__CALLER__.function, 0)} -> starting")
  end

  # TODO: This does not work, cannot resolve s if passed in as variable (not available at compile time)
  defmacro log_fn_start(s) do
    require Logger

    m = __CALLER__.module
    f = elem(__CALLER__.function, 0)

    Logger.info("#{m}::#{f} -> #{s}")
  end
end
