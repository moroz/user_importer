defmodule UserImporter.Auth0Client.WorkerHelper do
  alias HTTPoison.Response
  def handle_response({:ok, %Response{status_code: 204}}, state), do: {:reply, :ok, state}

  def handle_response({:ok, %Response{body: body, status_code: status}}, state)
      when status >= 200 and status <= 304,
      do: {:reply, {:ok, body}, state}

  def handle_response({:ok, %{body: body}}, state), do: {:reply, {:error, body}, state}

  def handle_response({:error, _}, state), do: {:reply, {:error, :unknown}, state}

  def handle_response(other, _state), do: IO.inspect(other)

  def token_header(token) do
    [{"Authorization", "Bearer #{token}"}]
  end
end
