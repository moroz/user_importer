defmodule UserImporter.Auth0Client do
  use GenServer
  import HTTPoison
  require Elixir.Logger
  alias Elixir.Logger

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

  def delete_user(user_id) do
    GenServer.call(__MODULE__, {:delete_user, user_id})
  end

  def delete_users do
    GenServer.call(__MODULE__, :delete_users)
  end

  def create_user(json_request) do
    GenServer.call(__MODULE__, {:create_user, json_request})
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:create_user, body}, _from, state) do
    case post(resolve_url("/users"), body, headers(state)) do
      {:ok, %HTTPoison.Response{body: _body, status_code: status_code}}
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
      response when is_list(response) ->
        {:reply, response, state}

      error ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:delete_user, user_id}, _from, state) do
    {:ok, %HTTPoison.Response{status_code: status_code}} =
      delete(resolve_url("/users/#{user_id}"), headers(state))

    case status_code do
      status when status >= 200 and status <= 304 ->
        {:reply, true, state}

      _ ->
        {:reply, false, state}
    end
  end

  defp list_users(state) do
    case get(resolve_url("/users?per_page=100"), headers(state)) do
      {:ok, %HTTPoison.Response{body: body}} ->
        Poison.decode!(body)

      error ->
        {:error, error}
    end
  end

  defp resolve_url(endpoint) when is_bitstring(endpoint) do
    api_url() <> endpoint
  end

  defp api_url do
    base_url() <> "/api/v2"
  end

  defp base_url, do: Application.get_env(:user_importer, :auth0_base_url)

  defp content_type_header, do: [{"Content-type", "application/json"}]

  defp headers(%State{auth0_token: token}) do
    [{"Authorization", "Bearer #{token}"} | content_type_header()]
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
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body |> Poison.decode!() |> Map.fetch!("access_token")

      _ ->
        raise "Fetching API token failed miserably"
    end
  end
end
