defmodule UserImporter.Exports.Users do
  alias UserImporter.{Repo, Accounts}
  alias UserImporter.Accounts.{Auth0User, User}
  import UserImporter.Exports.Helper
  require Elixir.Logger
  alias Elixir.Logger
  alias UserImporter.Auth0Client.Management

  @timeout 60000

  def list_users do
    Management.list_users()
  end

  def delete_all_in_auth0 do
    list_users()
    |> delete_all_in_auth0()
  end

  defp delete_all_in_auth0(auth0_users) when is_list(auth0_users) do
    case Enum.count(auth0_users) do
      c when c < 2 ->
        true

      _ ->
        auth0_users
        |> Enum.each(&delete_single/1)

        delete_all_in_auth0()
    end
  end

  defp delete_single(%{"email" => "jannik@webionate.de"}), do: true

  defp delete_single(%{"user_id" => user_id}) do
    Task.async(fn -> Management.delete_user(user_id) end)
  end

  def export_users(users) when is_list(users) do
    users
    |> Repo.preload(:roles)
    |> Enum.map(fn user -> Task.async(fn -> export_user(user) end) end)
    |> Enum.map(fn task -> Task.await(task, @timeout) end)
  end

  def export_user(%User{} = user) do
    req_body = User.to_auth0_request(user)

    case Management.create_user(req_body) do
      {:ok, _} ->
        Logger.info("User #{user.id} (#{user.email}) exported")

        Accounts.create_auth0_user(%{
          "password" => req_body["password"],
          "buddy_id" => user.id,
          "user_id" => User.user_id(user)
        })

        # Task.async(fn -> UserImporter.Exports.Roles.export_roles(user) end)

        true

      {:error, error} ->
        Logger.error("Export of user #{user.id} (#{user.email}) failed #{error_msg(error)}")
        false
    end
  end
end
