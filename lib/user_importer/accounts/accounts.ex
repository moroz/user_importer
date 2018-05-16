defmodule UserImporter.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias UserImporter.Repo

  alias UserImporter.Accounts.{User, Role}

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_users_with_roles do
    from(u in User, order_by: [desc: :id], limit: 25)
    |> Repo.all()
    |> Repo.preload(:roles)
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

  def list_unique_role_titles() do
    from(r in Role, select: r.title, distinct: true, order_by: [r.title]) |> Repo.all()
  end

  def get_role!(id), do: Repo.get!(Role, id)
end
