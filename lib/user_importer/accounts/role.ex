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
end
