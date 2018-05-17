defmodule UserImporter.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias UserImporter.Accounts.User

  schema "roles" do
    field(:title, :string)
    belongs_to(:user, User)

    timestamps(inserted_at: :created_at)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [])
    |> validate_required([])
  end

  def uuid_for(role_title) when is_bitstring(role_title) do
    UUID.uuid5(:dns, "https://buddy.buddyandselly.com" <> role_title)
  end

  def uuid_for(%__MODULE__{title: title}) do
    uuid_for(title)
  end
end
