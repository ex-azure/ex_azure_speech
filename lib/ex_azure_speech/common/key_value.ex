defmodule ExAzureSpeech.Common.KeyValue do
  @moduledoc """
  Provides a macro for defining a module with a set of key-value pairs.
  """
  defmacro __using__(options) do
    quote bind_quoted: [options: options] do
      @type t() :: unquote(options |> Keyword.keys() |> Enum.reduce(&{:|, [], [&1, &2]}))

      defmacro values() do
        Enum.map(unquote(options), fn {_function_name, value} ->
          value
        end)
      end

      for {function_name, value} <- options do
        @doc false
        @spec unquote(function_name)() :: String.t()
        def unquote(function_name)(), do: unquote(value)
      end
    end
  end
end
