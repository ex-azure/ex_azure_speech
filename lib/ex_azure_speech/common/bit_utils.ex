defmodule ExAzureSpeech.Common.BitUtils do
  @moduledoc """
  Provides utility functions for working with binary data.
  """
  @moduledoc section: :common

  @doc """
  Split a binary into chunks of size `n`.
  """
  @spec chunks(binary(), non_neg_integer()) :: [binary()]
  def chunks(binary, n) do
    do_chunks(binary, n, [])
  end

  defp do_chunks(binary, n, acc) when bit_size(binary) <= n do
    Enum.reverse([binary | acc])
  end

  defp do_chunks(binary, n, acc) do
    <<chunk::size(n), rest::bitstring>> = binary
    do_chunks(rest, n, [<<chunk::size(n)>> | acc])
  end
end
