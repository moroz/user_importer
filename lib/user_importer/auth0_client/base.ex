defmodule UserImporter.Auth0Client.Base do
  defmacro __using__(_opts) do
    quote do
      use HTTPoison.Base
      require Elixir.Logger
      alias Elixir.Logger
      import UserImporter.Auth0Client.WorkerHelper
      alias UserImporter.Auth0Client.WorkerState

      def process_request_headers(headers) do
        headers
        |> Keyword.put(:"Content-type", "application/json")
      end

      def process_response_body(body) when body in [nil, ""], do: nil
      def process_response_body(body), do: Poison.decode!(body)

      def request(method, url, headers, body, opts) do
        {time, res} =
          :timer.tc(fn ->
            super(method, url, headers, body, opts)
          end)

        {_, %{status_code: status}} = res

        Elixir.Logger.info(
          "[http] #{String.upcase(to_string(method))} #{url} #{status} in #{time} us"
        )

        res
      end
    end
  end
end
