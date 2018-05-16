defmodule UserImporter.Auth0Client do
  use GenServer
  import HTTPoison
  require Elixir.Logger
  alias Elixir.Logger
  alias UserImporter.Accounts.User

  defmodule State do
    defstruct token: nil
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %State{token: load_token()}}
  end

  def list_users do
    GenServer.call(__MODULE__, :list_users)
  end

  def delete_user(user_id) do
    GenServer.cast(__MODULE__, {:delete_user, user_id})
  end

  def delete_users do
    GenServer.call(__MODULE__, :delete_users)
  end

  def create_user(json_request) do
    GenServer.call(__MODULE__, {:create_user, json_request})
  end

  def handle_call({:create_user, body}, _from, state) do
    case post(resolve_url("/users"), body, headers(state)) do
      {:ok, res = %HTTPoison.Response{body: _body, status_code: status_code}}
      when status_code >= 200 and status_code < 400 ->
        {:reply, true, state}

      {:ok, response} ->
        {:reply, {:error, response}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call(:delete_users, _from, state) do
    list_users(state)
    |> Enum.map(fn user -> Map.get(user, "user_id") end)
    |> Enum.reject(&is_nil(&1))
    |> Enum.each(&delete_user/1)

    {:reply, :ok, state}
  end

  def handle_call(:list_users, _from, state) do
    case list_users(state) do
      response when is_map(response) ->
        {:reply, response, state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_cast({:delete_user, user_id}, state) do
    Logger.log(:info, "Deleting user #{user_id}...")

    {:ok, %HTTPoison.Response{status_code: status_code}} =
      delete(resolve_url("/users/#{user_id}"), headers(state))

    case status_code do
      204 ->
        Logger.log(:info, "Deleted user #{user_id}")

      429 ->
        Logger.log(:error, "Request limit exceeded!")

      _ ->
        Logger.log(:error, "Deleting user #{user_id} failed!")
    end

    {:noreply, state}
  end

  defp list_users(state) do
    case get(resolve_url("/users?per_page=100"), headers(state)) do
      {:ok, %HTTPoison.Response{body: body}} ->
        Poison.decode!(body)

      _ ->
        :error
    end
  end

  defp resolve_url(endpoint) when is_bitstring(endpoint) do
    base_url() <> endpoint
  end

  defp base_url, do: "https://buddy-test.eu.auth0.com/api/v2"

  defp headers(%State{token: token}) do
    [{"Authorization", "Bearer #{token}"}, {"Content-type", "application/json"}]
  end

  defp load_token do
    Path.expand("../token.txt", File.cwd!())
    |> File.read!()
  end
end
