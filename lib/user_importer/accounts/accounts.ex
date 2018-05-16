defmodule UserImporter.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias UserImporter.Repo

  alias UserImporter.Accounts.{User, Role, Auth0User}

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

  def export_users(users) do
    export_users(users, 0, 0)
  end

  defp export_users([user | rest], success_count, failure_count) do
    case export_user(user) do
      false ->
        export_users(rest, success_count, failure_count + 1)

      _ ->
        export_users(rest, success_count + 1, failure_count)
    end
  end

  defp export_users([], success_count, failure_count) do
    %{success: success_count, failure: failure_count}
  end

  def create_auth0_user(attrs = %{}) do
    changeset = Auth0User.changeset(%Auth0User{}, attrs)

    case Repo.insert(changeset) do
      {:ok, auth0_user} ->
        auth0_user

      {:error, _} ->
        false
    end
  end

  def export_user(user) do
    password = NotQwerty123.RandomPassword.gen_password(length: 10)

    req_body =
      user |> User.to_auth0_request() |> Map.put("password", password) |> Poison.encode!()

    case UserImporter.Auth0Client.create_user(req_body) do
      true ->
        create_auth0_user(%{
          "password" => password,
          "buddy_id" => user.id,
          "user_id" => User.user_id(user)
        })

      _ ->
        false
    end
  end
end
