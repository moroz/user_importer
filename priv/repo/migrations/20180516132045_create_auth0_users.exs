defmodule UserImporter.Repo.Migrations.CreateAuth0Users do
  use Ecto.Migration

  def change do
    create table(:auth0_users) do
      add(:user_id, :string)
      add(:buddy_id, :integer)
      add(:password, :string)

      timestamps()
    end

    create(index("auth0_users", [:buddy_id]))
  end
end
