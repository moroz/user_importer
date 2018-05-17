defmodule UserImporter.Auth0Client do
  use GenServer
  import HTTPoison
  require Elixir.Logger
  alias Elixir.Logger

  alias HTTPoison.Response

  alias UserImporter.Accounts.{User, Auth0User, Role}

  defmodule State do
    defstruct auth0_token: nil, authorization_token: nil
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, fetch_tokens(Application.get_env(:user_importer, :api_credentials))}
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def list_users do
    GenServer.call(__MODULE__, :list_users)
  end

  def delete_users do
    GenServer.call(__MODULE__, :delete_users)
  end

  def create_user(json_request) do
    GenServer.call(__MODULE__, {:create_user, json_request})
  end

  def list_roles(user) do
    GenServer.call(__MODULE__, {:list_roles, user})
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:create_user, body}, _from, state) do
    post(endpoint("/users"), body, headers(state))
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

  def handle_call(:list_users, _from, state) do
    list_users(state)
  end

  def handle_call({:delete_user, user_id}, _from, state) do
    delete_user(user_id, state)
  end

  def handle_call({:add_roles, user, []}, _from, state) do
    {:reply, true, state}
  end

  def handle_call({:add_roles, user, roles}, _from, state) do
    body = roles |> Enum.map(&Role.uuid_for(&1)) |> Poison.encode!()

    patch(role_endpoint(user), body, headers(:authorization, state))
    |> handle_response(state)
  end

  def handle_call({:list_roles, user}, _from, state) do
    get(role_endpoint(user), headers(:authorization, state))
    |> handle_response(state)
  end

  defp delete_user(user_id, state) do
    delete(endpoint("/users/#{user_id}"), headers(state))
    |> handle_response(state)
  end

  defp handle_response({:ok, %Response{status_code: 204}}, state), do: {:reply, :ok, state}

  defp handle_response({:ok, %Response{body: body, status_code: status}}, state)
       when status >= 200 and status <= 304,
       do: {:reply, {:ok, Poison.decode!(body)}, state}

  defp handle_response({_, %{body: body}}, state),
    do: {:reply, {:error, Poison.decode!(body)}, state}

  defp role_endpoint(%Auth0User{user_id: user_id}), do: role_endpoint(user_id)

  defp role_endpoint(user = %User{}) do
    User.user_id(user) |> role_endpoint()
  end

  defp role_endpoint(user_id), do: endpoint(:authorization, "/users/auth0|#{user_id}/roles")

  defp list_users(state) do
    {:ok, %Response{body: body}} = get(endpoint("/users?per_page=100"), headers(state))
    Poison.decode!(body)
  end

  defp endpoint(:authorization, path) do
    Application.get_env(:user_importer, :authorization_base_url) <> path
  end

  defp endpoint(path) do
    Application.get_env(:user_importer, :auth0_base_url) <> "/api/v2" <> path
  end

  defp content_type_header, do: [{"Content-type", "application/json"}]

  defp headers(:authorization, %State{authorization_token: token}) do
    [token_header(token) | content_type_header()]
  end

  defp headers(%State{auth0_token: token}) do
    [token_header(token) | content_type_header()]
  end

  defp token_header(token) do
    {"Authorization", "Bearer #{token}"}
  end

  defp fetch_tokens(
         credentials = %{
           auth0_audience: auth0_audience,
           authorization_audience: authorization_audience
         }
       ) do
    %State{
      auth0_token: fetch_token(auth0_audience, credentials),
      authorization_token: fetch_token(authorization_audience, credentials)
    }
  end

  defp fetch_token(audience, %{client_id: id, client_secret: secret, token_endpoint: url}) do
    req_body =
      %{
        "grant_type" => "client_credentials",
        "client_id" => id,
        "client_secret" => secret,
        "audience" => audience
      }
      |> Poison.encode!()

    case post(url, req_body, content_type_header()) do
      {:ok, %Response{status_code: 200, body: body}} ->
        body |> Poison.decode!() |> Map.fetch!("access_token")

      _ ->
        raise "Fetching API token failed miserably"
    end
  end
end
