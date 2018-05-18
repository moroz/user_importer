defmodule UserImporter.Accounts.Auth0User do
  use Ecto.Schema
  import Ecto.Changeset
  alias UserImporter.Accounts.{Role, User}

  schema "auth0_users" do
    field(:buddy_id, :integer)
    field(:password, :string)
    field(:user_id, :string)
    has_many(:roles, Role, foreign_key: :user_id, references: :buddy_id)
    belongs_to(:user, User, foreign_key: :buddy_id, define_field: false)

    timestamps()
  end

  @doc false
  def changeset(auth0_user, attrs) do
    auth0_user
    |> cast(attrs, [:user_id, :buddy_id, :password])
    |> validate_required([:user_id, :buddy_id, :password])
  end
end

defimpl String.Chars, for: UserImporter.Accounts.Auth0User do
  def to_string(%UserImporter.Accounts.Auth0User{user_id: user_id}), do: user_id
end
