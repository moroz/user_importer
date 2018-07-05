defmodule UserImporter.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias UserImporter.Repo
  alias UserImporter.Accounts.{User, Role, Auth0User}

  @multi_app_roles ["admin", "storage", "storage_mgr"]
  @other_apps [:packing, :storage]

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def list_roles() do
    Repo.all(Role)
  end

  def roles_as_tuples() do
    buddy_roles =
      Repo.all(from(r in Role, select: r.title, distinct: true, order_by: [r.title]))
      |> role_tuples(:buddy)

    other_roles =
      @other_apps
      |> Enum.map(fn app_name -> role_tuples(@multi_app_roles, app_name) end)
      |> List.flatten()

    buddy_roles ++ other_roles
  end

  defp role_tuples(list, app_name) do
    Enum.map(list, fn el -> {el, app_name} end)
  end

  def get_role!(id), do: Repo.get!(Role, id)

  def create_auth0_user(attrs = %{}) do
    changeset = Auth0User.changeset(%Auth0User{}, attrs)

    case Repo.insert(changeset) do
      {:ok, auth0_user} ->
        auth0_user

      {:error, _} ->
        false
    end
  end
end
