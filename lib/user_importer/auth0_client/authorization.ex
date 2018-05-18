defmodule UserImporter.Auth0Client.Authorization do
  use GenServer
  use UserImporter.Auth0Client.Base

  alias UserImporter.Accounts.Role

  @endpoint Application.get_env(:user_importer, :authorization_base_url)

  ## OTP API

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    %{authorization_token: token} = UserImporter.Auth0Client.get_config()
    {:ok, %WorkerState{token: token}}
  end

  ## Public API

  def list_roles(pid, user) do
    GenServer.call(pid, {:list_roles, user})
  end

  def add_roles(pid, user, role_ids) do
    GenServer.call(pid, {:add_roles, user, role_ids})
  end

  ## HTTPoison.Base functions

  def process_url(url) do
    @endpoint <> "/users/auth0|#{url}/roles"
  end

  ## Callbacks

  def handle_call({:add_roles, _user, []}, _from, state) do
    {:reply, true, state}
  end

  def handle_call({:add_roles, user, role_ids}, _from, state = %{token: token}) do
    patch(user, role_ids, token)
    |> handle_response(state)
  end

  def handle_call({:list_roles, user}, _from, state = %{token: token}) do
    get(user, token)
    |> handle_response(state)
  end
end
