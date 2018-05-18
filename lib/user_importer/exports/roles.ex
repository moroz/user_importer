defmodule UserImporter.Exports.Roles do
  alias UserImporter.Repo
  alias UserImporter.Accounts.Role
  import UserImporter.Exports.Helper
  require Elixir.Logger
  alias UserImporter.Auth0Client.Authorization

  @timeout 60000

  def list_roles(user) do
    :poolboy.transaction(
      :authorization,
      fn pid -> Authorization.list_roles(pid, user) end,
      @timeout
    )
  end

  def export_roles(users) when is_list(users) do
    measure_time(fn ->
      users
      |> Repo.preload(:roles)
      |> Enum.map(fn user -> Task.async(fn -> export_roles(user, user.roles) end) end)
      |> Enum.map(&Task.await/1)
    end)
  end

  def export_roles(user) do
    user = Repo.preload(user, :roles)
    export_roles(user, user.roles)
  end

  defp export_roles(_user, []), do: true

  defp export_roles(user, roles) do
    role_ids = Enum.map(roles, &Role.uuid_for(&1))

    :poolboy.transaction(
      :authorization,
      fn pid ->
        Authorization.add_roles(pid, user, role_ids)
      end,
      @timeout
    )
  end
end
