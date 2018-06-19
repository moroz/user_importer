defmodule UserImporterWeb.RoleView do
  use UserImporterWeb, :view
  alias UserImporterWeb.RoleView

  @application_id Application.fetch_env!(
                    :user_importer,
                    :api_credentials
                  )[:authorization_application_id]

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

  def render("role.json", %{role: role_title}) do
    %{
      "_id" => UserImporter.Accounts.Role.uuid_for(role_title),
      "applicationType" => "client",
      "applicationId" => @application_id,
      "name" => role_title,
      "description" => description_for(role_title)
    }
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

  defp configuration_header do
    [
      %{
        "_id" => "v1",
        "rolesInToken" => true
      }
    ]
  end
end
