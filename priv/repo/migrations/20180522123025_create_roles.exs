defmodule UserImporter.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add(:title, :string)
      add(:user_id, references(:users), null: false)

      timestamps()
    end
  end
end
