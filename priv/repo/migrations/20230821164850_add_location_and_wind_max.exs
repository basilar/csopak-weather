defmodule Repo.Migrations.AddLocationAndWindMax do
  use Ecto.Migration

  def change do
    alter table("observation") do
      add :wind_max, :float
      add :location, :integer
    end
  end
end
