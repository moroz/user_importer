defmodule UserImporter.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias UserImporter.Accounts.{Role, User}

  schema "users" do
    field(:email, :string)
    field(:display_name, :string)
    field(:city, :string)
    field(:country, :string)
    field(:phone, :string)
    has_many(:roles, Role)

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def encode_roles(user) do
    role_names = user.roles |> Enum.map(fn role -> role.title end)
    %{user | roles: role_names}
  end

  def user_id(user) do
    base = "https://buddy.buddyandselly.com" <> Integer.to_string(user.id)

    digest =
      :crypto.hash(:sha, base)
      |> Base.encode16(case: :lower)
      |> String.slice(0, 23)

    "buddy|" <> digest
  end

  def username(user) do
    user.email |> String.split("@") |> List.first()
  end

  def role_names(user) do
    user.roles |> Enum.map(fn role -> role.title end)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
