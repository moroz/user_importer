defmodule UserImporter.Auth0Client.Base do
  defmacro __using__(_opts) do
    quote do
      use HTTPoison.Base
      require Elixir.Logger
      alias Elixir.Logger
      import UserImporter.Auth0Client.WorkerHelper
      alias UserImporter.Auth0Client.WorkerState

      def process_request_headers(headers) do
        set_headers(headers)
        |> Keyword.put(:"Content-type", "application/json")
      end

      def process_response_body(body) when body in [nil, ""], do: nil
      def process_response_body(body), do: Poison.decode!(body)

      def request(method, url, headers, body, opts) do
        {time, res} =
          :timer.tc(fn ->
            super(method, url, headers, encode_body(body), opts)
          end)

        {_, %{status_code: status}} = res

        Elixir.Logger.info(
          "[http] #{String.upcase(to_string(method))} #{url} #{status} in #{time} us"
        )

        res
      end

      defp set_headers(val) when is_bitstring(val) do
        [{"Authorization", "Bearer #{val}"}]
      end

      defp set_headers(val), do: val

      defp encode_body(body) when is_bitstring(body), do: body
      defp encode_body(body), do: Poison.encode!(body)
    end
  end
end
