defmodule UserImporter.Accounts.Auth0User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "auth0_users" do
    field(:buddy_id, :integer)
    field(:password, :string)
    field(:user_id, :string)

    timestamps()
  end

  @doc false
  def changeset(auth0_user, attrs) do
    auth0_user
    |> cast(attrs, [:user_id, :buddy_id, :password])
    |> validate_required([:user_id, :buddy_id, :password])
  end
end
