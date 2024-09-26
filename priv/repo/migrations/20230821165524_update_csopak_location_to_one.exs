defmodule Repo.Migrations.UpdateCsopakLocationToOne do
  use Ecto.Migration
  import Ecto.Query

  def change do
    query = from("observations", where: is_nil(:location))
    update(query, set: [location: 1])
  end
end
