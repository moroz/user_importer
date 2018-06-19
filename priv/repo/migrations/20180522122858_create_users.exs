defmodule UserImporter.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string)
      add(:display_name, :string)
      add(:city, :string)
      add(:country, :string)
      add(:phone, :string)

      timestamps()
    end
  end
end
