defmodule UserImporterWeb.RoleController do
  use UserImporterWeb, :controller

  alias UserImporter.Accounts

  action_fallback(UserImporterWeb.FallbackController)

  def index(conn, _params) do
    roles = Accounts.list_unique_role_titles()
    render(conn, "index.json", roles: roles)
  end

  def show(conn, %{"id" => id}) do
    role = Accounts.get_role!(id)
    render(conn, "show.json", role: role)
  end
end
