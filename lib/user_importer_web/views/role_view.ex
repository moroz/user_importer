defmodule UserImporterWeb.RoleView do
  use UserImporterWeb, :view
  alias UserImporterWeb.RoleView

  @application_id Application.fetch_env!(
                    :user_importer,
                    :api_credentials
                  )[:authorization_application_id]

  @multi_app_roles ["admin", "storage", "storage_mgr"]

  def render("index.json", %{roles: roles}) do
    %{
      "configuration" => configuration_header(),
      "roles" => render_many(roles, RoleView, "role.json"),
      "permissions" => [],
      "groups" => []
    }
  end

  def render("show.json", %{role: role}) do
    render_one(role, RoleView, "role.json")
  end

  def render("role.json", %{role: role}) do
    UserImporter.RoleHelper.to_json(role)
  end

  defp description_for(role_title) do
    readable_name =
      role_title
      |> String.replace("mgr", "manager")
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    readable_name <> " role."
  end

  defp client_id(app) do
    Application.fetch_env!(:user_importer, :client_ids)[app]
  end

  defp configuration_header do
    [
      %{
        "_id" => "v1",
        "rolesInToken" => true
      }
    ]
  end
end
