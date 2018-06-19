defmodule UserImporter.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias UserImporter.Accounts.{Role, Auth0User}

  schema "users" do
    field(:email, :string)
    field(:display_name, :string)
    field(:city, :string)
    field(:country, :string)
    field(:phone, :string)
    has_many(:roles, Role)
    has_one(:auth0_user, Auth0User, foreign_key: :buddy_id)

    timestamps()
  end

  def encode_roles(user) do
    role_names = user.roles |> Enum.map(fn role -> role.title end)
    %{user | roles: role_names}
  end

  def user_id(user) do
    base = "https://buddy.buddyandselly.com" <> Integer.to_string(user.id)

    :crypto.hash(:sha, base)
    |> Base.encode16(case: :lower)
    |> String.slice(0, 23)
  end

  def to_auth0_request(user) do
    user = user |> UserImporter.Repo.preload(:roles)

    %{
      "user_id" => user_id(user),
      "connection" => "Username-Password-Authentication",
      "password" => gen_password(),
      "email" => user.email,
      "verify_email" => false,
      "user_metadata" => %{
        "name" => user.display_name
      },
      "app_metadata" => %{
        "buddy_id" => user.id,
        "roles" => role_names(user)
      }
    }
  end

  defp gen_password do
    password = NotQwerty123.RandomPassword.gen_password(length: 12)

    if password =~ ~r/\d/ && password =~ ~r/[A-Z]/ && password =~ ~r/[a-z]/ do
      password
    else
      gen_password()
    end
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

defimpl String.Chars, for: UserImporter.Accounts.User do
  def to_string(user), do: UserImporter.Accounts.User.user_id(user)
end
