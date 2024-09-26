defmodule Repo.Migrations.CreateObservation do
  use Ecto.Migration

  def change do
    create table(:observation) do
      add :datetime, :utc_datetime, null: false
      add :mslp, :float
      add :rh, :float
      add :temperature, :float
      add :water_temperature, :float
      add :wind_avg, :float
      add :wind_direction, :integer
    end

    create index(:observation, [:datetime])
  end

end
