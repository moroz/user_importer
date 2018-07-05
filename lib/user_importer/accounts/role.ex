defmodule UserImporter.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias UserImporter.Accounts.User

  @client_ids Application.fetch_env!(:user_importer, :client_ids)

  schema "roles" do
    field(:title, :string)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [])
    |> validate_required([])
  end

  def uuid_for(role_title, client_id \\ @client_ids[:buddy]) when is_bitstring(role_title) do
    UUID.uuid5(:dns, "" <> role_title)
  end
end
