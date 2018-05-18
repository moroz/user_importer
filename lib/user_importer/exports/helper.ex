defmodule UserImporter.Exports.Helper do
  require Elixir.Logger
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

  def measure_time(fun) when is_function(fun) do
    {time, results} = :timer.tc(fun)
    Elixir.Logger.info("Task finished in #{readable_interval(time)}")
    results
  end

  def readable_interval(us) when us < 1000, do: "#{us}μs"

  def readable_interval(us) when us < 1_000_000 do
    "#{Float.round(us / 1000, 1)}ms"
  end

  def readable_interval(us), do: "#{Float.round(us / 1_000_000)}s"

  def error_msg(%{"error" => error, "message" => msg, "statusCode" => status}) do
    "(#{status}): #{error}, #{msg}"
  end

  def error_msg(%{"error" => error, "statusCode" => status}) do
    "(#{status}): #{error}"
  end
end
