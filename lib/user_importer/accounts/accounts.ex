defmodule UserImporter.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias UserImporter.{Repo, Auth0Client}

  alias UserImporter.Accounts.{User, Role, Auth0User}
  require Elixir.Logger

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

  def list_unique_role_titles() do
    from(r in Role, select: r.title, distinct: true, order_by: [r.title]) |> Repo.all()
  end

  def get_role!(id), do: Repo.get!(Role, id)

  def delete_all_in_auth0 do
    Repo.all(Auth0User) |> delete_in_auth0
  end

  def delete_in_auth0(users) when is_list(users) do
    delete_in_auth0(users, %{failure: 0, success: 0})
  end

  def delete_in_auth0(%User{} = user) do
    case Auth0Client.delete_user("auth0|" <> user.user_id) do
      true ->
        Repo.delete(user)
        true

      false ->
        Elixir.Logger.log(:error, "Deleting user #{user.buddy_id} failed")
        false
    end
  end

  defp delete_in_auth0([user | rest], stats = %{failure: failure, success: success}) do
    case delete_in_auth0(user) do
      true ->
        delete_in_auth0(rest, %{stats | success: success + 1})

      false ->
        delete_in_auth0(rest, %{stats | failure: failure + 1})
    end
  end

  defp delete_in_auth0([], stats), do: stats

  def export_users(users) do
    users = Repo.preload(users, :roles)
    export_users(users, %{failure: 0, success: 0})
  end

  defp export_users([user | rest], stats = %{failure: failure, success: success}) do
    case export_user(user) do
      false ->
        export_users(rest, %{stats | failure: failure + 1})

      _ ->
        export_users(rest, %{stats | success: success + 1})
    end
  end

  defp export_users([], stats), do: stats

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

    case Auth0Client.create_user(req_body) do
      {:ok, _} ->
        create_auth0_user(%{
          "password" => password,
          "buddy_id" => user.id,
          "user_id" => User.user_id(user)
        })

      {:error, _} ->
        false
    end
  end
end
