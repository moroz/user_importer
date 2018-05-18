defmodule UserImporter.Exports.Helper do
  def each_with_stats(list, fun), do: each_with_stats(list, fun, %{success: 0, failure: 0})

  defp each_with_stats([elem | rest], fun, stats = %{success: success, failure: failure}) do
    case fun.(elem) do
      val when val in [true, :ok] ->
        each_with_stats(rest, fun, %{stats | success: success + 1})

      val when val in [false, nil] ->
        each_with_stats(rest, fun, %{stats | failure: failure + 1})
    end
  end

  defp each_with_stats([], _fun, stats), do: stats

  def error_msg(%{"error" => error, "message" => msg, "statusCode" => status}) do
    "(#{status}): #{error}, #{msg}"
  end

  def error_msg(%{"error" => error, "statusCode" => status}) do
    "(#{status}): #{error}"
  end
end
