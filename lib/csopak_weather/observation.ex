defmodule Observation do
  use Ecto.Schema

  schema "observation" do
    field(:datetime, :utc_datetime)
    field(:mslp, :float)
    field(:rh, :float)
    field(:temperature, :float)
    field(:water_temperature, :float)
    field(:wind_avg, :float)
    field(:wind_direction, :integer)
    field(:wind_max, :float)
    field(:location, :integer)
  end

  def changeset(observation, params \\ %{}) do
    observation
    |> Ecto.Changeset.cast(params, [
      :datetime,
      :mslp,
      :rh,
      :temperature,
      :water_temperature,
      :wind_avg,
      :wind_direction,
      :wind_max,
      :location
    ])
    |> Ecto.Changeset.validate_required([:datetime, :wind_avg, :wind_direction, :location])
  end
end
