defmodule UserImporter.Exports.Roles do
  alias UserImporter.{Repo, Accounts}
  alias UserImporter.Accounts.{Auth0User, Role}
  import UserImporter.Exports.Helper
  require Elixir.Logger
  alias UserImporter.Auth0Client.Authorization

  @timeout 60000

  def export_roles(users) when is_list(users) do
    users |> Repo.preload(:roles) |> each_with_stats(&export_roles/1)
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
