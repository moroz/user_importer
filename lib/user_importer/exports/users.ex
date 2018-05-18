defmodule UserImporter.Exports.Users do
  alias UserImporter.{Repo, Accounts}
  alias UserImporter.Accounts.{Auth0User, User}
  import UserImporter.Exports.Helper
  require Elixir.Logger
  alias Elixir.Logger
  alias UserImporter.Auth0Client.Management

  @timeout 60000

  def list_users do
    :poolboy.transaction(:management, fn pid -> Management.list_users(pid) end, @timeout)
  end

  def delete_all_in_auth0 do
    Repo.all(Auth0User)
    |> delete_in_auth0
  end

  def delete_in_auth0(auth0_users) when is_list(auth0_users) do
    measure_time(fn ->
      auth0_users
      |> Enum.each(fn auth0_user -> Task.async(fn -> delete_in_auth0(auth0_user) end) end)
    end)
  end

  def delete_in_auth0(%Auth0User{} = auth0_user) do
    :poolboy.transaction(:management, fn pid -> delete_in_auth0(pid, auth0_user) end, @timeout)
  end

  defp delete_in_auth0(pid, auth0_user) do
    case Management.delete_user(pid, auth0_user.user_id) do
      :ok ->
        Logger.info("User ##{auth0_user.buddy_id} has been deleted.")
        Repo.delete(auth0_user)
        true

      {:error, error} ->
        Logger.error("Deleting user #{auth0_user.buddy_id} failed #{error_msg(error)}")
        false
    end
  end

  def export_users(users) when is_list(users) do
    measure_time(fn ->
      users
      |> Repo.preload(:roles)
      |> Enum.map(fn user -> Task.async(fn -> export_user(user) end) end)
      |> Enum.map(&Task.await/1)
    end)
  end

  def export_user(user = %User{}) do
    :poolboy.transaction(:management, fn pid -> export_user(pid, user) end, @timeout)
  end

  def export_user(pid, user) do
    req_body = User.to_auth0_request(user)

    case Management.create_user(pid, req_body) do
      {:ok, _} ->
        Logger.info("User #{user.id} (#{user.email}) exported")

        Accounts.create_auth0_user(%{
          "password" => req_body["password"],
          "buddy_id" => user.id,
          "user_id" => User.user_id(user)
        })

        true

      {:error, error} ->
        Logger.error("Export of user #{user.id} (#{user.email}) failed #{error_msg(error)}")
        false
    end
  end
end
