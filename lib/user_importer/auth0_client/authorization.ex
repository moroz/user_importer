defmodule UserImporter.Auth0Client.Authorization do
  use GenServer
  use UserImporter.Auth0Client.Base

  @endpoint Application.get_env(:user_importer, :authorization_base_url)

  ## OTP API

  def init(%{authorization_token: token}) when is_nil(token), do: {:stop, {:error, :no_token}}

  def init(%{authorization_token: token}) do
    {:ok, %WorkerState{token: token}}
  end

  ## HTTPoison.Base functions

  def process_url(url) do
    @endpoint <> "/users/auth0|#{url}/roles"
  end

  ## Callbacks

  def handle_call({:add_roles, _user, []}, _from, state) do
    {:reply, true, state}
  end

  def handle_call({:add_roles, user, roles}, _from, state = %{token: token}) do
    body = roles |> Enum.map(&Role.uuid_for(&1)) |> Poison.encode!()

    patch(user, body, token_header(token))
    |> handle_response(state)
  end

  def handle_call({:list_roles, user}, _from, state = %{token: token}) do
    get(user, token_header(token))
    |> handle_response(state)
  end
end
