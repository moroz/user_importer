defmodule UserImporter.Auth0Client.Management do
  use GenServer
  use UserImporter.Auth0Client.Base

  alias HTTPoison.Response

  @endpoint Application.get_env(:user_importer, :management_base_url)
  @timeout 60000

  ## OTP API

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    %{management_token: token} = UserImporter.Auth0Client.get_config()
    {:ok, %WorkerState{token: token}}
  end

  ## Public API

  def list_users, do: transaction(fn pid -> GenServer.call(pid, :list_users) end)

  def create_user(req_body),
    do: transaction(fn pid -> GenServer.call(pid, {:create_user, req_body}) end)

  def delete_user(user_id),
    do: transaction(fn pid -> GenServer.call(pid, {:delete_user, user_id}) end)

  ## HTTPoison.Base functions

  def process_url(url) do
    @endpoint <> url
  end

  ## Callbacks

  def handle_call(:list_users, _from, state = %{token: token}) do
    {:ok, %Response{body: body}} = get("/users?per_page=100", token)
    {:reply, body, state}
  end

  def handle_call({:create_user, body}, _from, state = %{token: token}) do
    post("/users", body, token)
    |> handle_response(state)
  end

  def handle_call({:delete_user, user_id}, _from, state = %{token: token}) do
    delete(delete_endpoint(user_id), token)
    |> handle_response(state)
  end

  ## Private functions

  defp delete_endpoint("auth0|" <> user_id), do: delete_endpoint(user_id)
  defp delete_endpoint(user_id), do: "/users/auth0|#{user_id}"

  defp transaction(fun) when is_function(fun),
    do: :poolboy.transaction(:management, fun, @timeout)
end
