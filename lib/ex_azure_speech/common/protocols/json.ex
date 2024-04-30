defprotocol ExAzureSpeech.Common.Protocols.Json do
  @moduledoc """
  Protocol for deserialize JSON responses into valid message structs.
  """
  @moduledoc section: :common
  alias ExAzureSpeech.Common.Errors.InvalidResponse

  @doc """
  Serializes the informed JSON string and coerces it into the informed struct.
  """
  @spec from_json(String.t(), module()) :: {:ok, struct()} | {:error, InvalidResponse.t()}
  def from_json(json, struct)
end

defimpl ExAzureSpeech.Common.Protocols.Json, for: BitString do
  alias ExAzureSpeech.Common.Errors.InvalidResponse

  # TODO: Coerce nested into structs
  def from_json(json, struct) do
    case Jason.decode(json, keys: &to_snake_atom/1) do
      {:ok, response} -> {:ok, struct(struct, response)}
      {:error, _} -> {:error, InvalidResponse.exception()}
    end
  end

  defp to_snake_atom(key),
    do:
      Macro.underscore(key)
      |> String.to_atom()
end
