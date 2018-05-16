defmodule UserImporterWeb.UserController do
  use UserImporterWeb, :controller

  alias UserImporter.{Accounts, Repo}
  # alias UserImporter.Accounts.User

  action_fallback(UserImporterWeb.FallbackController)

  def index(conn, _params) do
    users = Accounts.list_users_with_roles()
    render(conn, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id) |> Repo.preload(:roles)
    render(conn, "show.json", user: user)
  end
end
