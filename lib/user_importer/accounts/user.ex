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

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([])
  end

  defimpl Poison.Encoder, for: User do
    def encode(user, options) do
      user
      |> User.encode_roles()
      |> Map.delete(:__meta__)
      |> Map.delete(:__struct__)
      |> Poison.Encoder.Map.encode(options)
    end
  end
end
