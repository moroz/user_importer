defmodule UserImporter.RoleHelper do
  alias UserImporter.Accounts.Role

  @client_ids Application.fetch_env!(:user_importer, :client_ids)
  @multi_app_roles ["admin", "storage", "storage_mgr"]
  @app_names [:buddy, :storage, :packing]

  def uuid(%Role{title: title}), do: uuid(title)

  def uuid(role_title) when role_title in @multi_app_roles do
    Enum.map(@app_names, fn app -> uuid(role_title, app) end)
  end

  def uuid(role_title), do: uuid(role_title, :buddy)

  defp uuid(role_title, app) do
    UUID.uuid5(:dns, client_id(app) <> "--" <> role_title)
  end

  def role_uuid_list(roles) do
    Enum.map(roles, &uuid/1)
    |> List.flatten()
  end

  def to_json({role_title, app}) do
    %{
      "_id" => uuid(role_title, app),
      "applicationType" => "client",
      "applicationId" => client_id(app),
      "name" => role_title,
      "description" => description_for(role_title, app)
    }
  end

  defp description_for(role_title, app) do
    readable_role_name(role_title) <>
      " role for the " <> readable_app_name(app) <> " application."
  end

  defp readable_role_name(role_title) do
    role_title
    |> String.replace("mgr", "manager")
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp readable_app_name(app) when is_atom(app) do
    Atom.to_string(app) |> String.capitalize()
  end

  def client_id(app) do
    @client_ids[app]
  end
end
