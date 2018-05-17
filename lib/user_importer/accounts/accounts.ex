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
    users
    |> each_with_stats(&delete_in_auth0/1)
  end

  def delete_in_auth0(%Auth0User{} = user) do
    case GenServer.call(Auth0Client, {:delete_user, "auth0|#{user.user_id}"}) do
      :ok ->
        Repo.delete(user)
        true

      {:error, error} ->
        Elixir.Logger.log(:error, "Deleting user #{user.buddy_id} failed #{error_msg(error)}")
        false
    end
  end

  defp delete_in_auth0([], stats), do: stats

  def export_users(users) when is_list(users) do
    users
    |> each_with_stats(&export_user/1)
  end

  def each_with_stats(list, fun), do: each_with_stats(list, fun, %{success: 0, failure: 0})

  defp each_with_stats([elem | rest], fun, stats = %{success: success, failure: failure}) do
    case fun.(elem) do
      val when val in [true, :ok] ->
        each_with_stats(rest, fun, %{stats | success: success + 1})

      val when val in [false, nil] ->
        each_with_stats(rest, fun, %{stats | failure: failure + 1})
    end
  end

  defp each_with_stats([], fun, stats), do: stats

  def export_roles(users) when is_list(users) do
    users |> Repo.preload(:roles) |> each_with_stats(&export_roles/1)
  end

  def export_roles(user) do
    user = Repo.preload(user, :roles)
    GenServer.call(Auth0Client, {:add_roles, user, user.roles})
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
    req_body = user |> User.to_auth0_request()

    case Auth0Client.create_user(Poison.encode!(req_body)) do
      {:ok, _} ->
        create_auth0_user(%{
          "password" => req_body["password"],
          "buddy_id" => user.id,
          "user_id" => User.user_id(user)
        })

        true

      {:error, error} ->
        Elixir.Logger.log(:error, "Export of user #{user.email} failed #{error_msg(error)}")
        false
    end
  end

  defp error_msg(%{"error" => error, "message" => msg, "statusCode" => status}) do
    "(#{status}): #{error}, #{msg}"
  end

  defp error_msg(%{"error" => error, "statusCode" => status}) do
    "(#{status}): #{error}"
  end
end
