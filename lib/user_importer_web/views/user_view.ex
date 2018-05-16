defmodule UserImporterWeb.UserView do
  use UserImporterWeb, :view
  alias UserImporterWeb.UserView
  alias UserImporter.Accounts.User

  def render("index.json", %{users: users}) do
    render_many(users, UserView, "user.json")
  end

  def render("show.json", %{user: user}) do
    render_one(user, UserView, "user.json")
  end

  def render("user.json", %{user: user}) do
    %{
      "email" => user.email,
      "email_verified" => true,
      "username" => User.username(user),
      "name" => user.display_name,
      "user_id" => User.user_id(user),
      "app_metadata" => %{
        "buddy_id" => user.id,
        "roles" => User.role_names(user)
      },
      "user_metadata" => %{}
    }
  end
end
