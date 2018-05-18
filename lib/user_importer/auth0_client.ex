defmodule UserImporter.Auth0Client do
  use GenServer
  require Elixir.Logger
  alias Elixir.Logger

  alias HTTPoison.Response

  alias UserImporter.Accounts.{User, Auth0User, Role}

  defmodule State do
    defstruct management_token: nil, authorization_token: nil
  end

  defmodule WorkerState do
    defstruct token: nil, sup_pid: nil
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_authorization_client do
    GenServer.call(__MODULE__, :start_authorization_client)
  end

  def start_management_client do
    GenServer.call(__MODULE__, :start_management_client)
  end

  def init([]) do
    {:ok, fetch_tokens(Application.get_env(:user_importer, :api_credentials))}
  end

  def get_config do
    GenServer.call(__MODULE__, :status)
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  defp fetch_tokens(
         credentials = %{
           management_audience: management_audience,
           authorization_audience: authorization_audience
         }
       ) do
    %State{
      management_token: fetch_token(management_audience, credentials),
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

    case HTTPoison.post(url, req_body, [{"Content-type", "application/json"}]) do
      {:ok, %Response{status_code: 200, body: body}} ->
        body |> Poison.decode!() |> Map.fetch!("access_token")

      _ ->
        raise "Fetching API token failed miserably"
    end
  end
end
