defmodule UserImporter.Auth0Client.Management do
  use GenServer
  use UserImporter.Auth0Client.Base

  alias HTTPoison.Response

  @endpoint Application.get_env(:user_importer, :management_base_url)

  ## OTP API

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    %{management_token: token} = UserImporter.Auth0Client.get_config()
    {:ok, %WorkerState{token: token}}
  end

  def create_user(pid, req_body), do: GenServer.call(pid, {:create_user, req_body})

  ## HTTPoison.Base functions

  def process_url(url) do
    @endpoint <> url
  end

  ## Callbacks

  def handle_call(:list_users, _from, state) do
    list_users(state)
  end

  def handle_call({:create_user, body}, _from, state = %{token: token}) do
    post("/users", body, token)
    |> handle_response(state)
  end

  def handle_call(:delete_users, _from, state) do
    list_users(state)
    |> IO.inspect()
    |> Enum.map(fn user -> Map.get(user, "user_id") end)
    |> Enum.reject(&is_nil(&1))
    |> IO.inspect()
    |> Enum.each(&delete_user(&1, state))

    {:reply, :ok, state}
  end

  def handle_call({:delete_user, user_id}, _from, state) do
    delete_user(user_id, state)
  end

  ## Private functions

  defp list_users(%{token: token}) do
    {:ok, %Response{body: body}} = get("/users?per_page=100", token)
    Poison.decode!(body)
  end

  defp delete_user(user_id, state = %{token: token}) do
    delete("/users/#{user_id}", token)
    |> handle_response(state)
  end
end