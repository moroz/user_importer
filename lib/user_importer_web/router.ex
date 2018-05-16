defmodule UserImporterWeb.Router do
  use UserImporterWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", UserImporterWeb do
    pipe_through(:api)

    resources("/users", UserController, only: [:index])
    resources("/roles", RoleController, only: [:index])
  end

  scope "/", UserImporterWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
  end
end
