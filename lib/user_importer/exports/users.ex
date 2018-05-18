defmodule UserImporter.Exports.Users do
  alias UserImporter.{Repo, Accounts}
  alias UserImporter.Accounts.{Auth0User, User}
  import UserImporter.Exports.Helper
  require Elixir.Logger
  alias UserImporter.Auth0Client.Management

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

  def export_users(users) when is_list(users) do
    users
    |> each_with_stats(&export_user/1)
  end

  def export_user(user) do
    req_body = user |> User.to_auth0_request()

    case Management.create_user(req_body) do
      {:ok, _} ->
        Accounts.create_auth0_user(%{
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
end
