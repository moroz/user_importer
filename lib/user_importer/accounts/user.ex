defmodule UserImporter.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Poison.Encoder, except: [:__meta__]}

  schema "users" do
    field(:email, :string)
    field(:display_name, :string)
    field(:city, :string)
    field(:country, :string)
    field(:phone, :string)

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
