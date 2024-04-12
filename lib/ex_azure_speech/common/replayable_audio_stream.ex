defmodule ExAzureSpeech.Common.ReplayableAudioStream do
  @moduledoc """
  Implements a way to read audio-streams with the capability to rewing and restart from a specific offset point.
  """

  @typedoc """
  buffer: The binary buffer to read from.  
  current_offset: The current offset in the buffer, each 1 increase in the offset represents 100ns of audio.  
  bytes_per_second: The number of bytes per second in the audio stream. Calculated as sample_rate * bits_per_sample * channels.  
  chunk_size: The size in bytes of the chunk to read from the buffer.  
  """
  @moduledoc section: :common

  @type t() :: %{
          buffer: binary(),
          current_offset: integer(),
          bytes_per_second: integer(),
          chunk_size: integer()
        }

  alias __MODULE__

  @doc """
  Reads a chunk of bytes from the buffer and advances the current offset.
  """
  @spec read(ReplayableAudioStream.t()) ::
          {:ok, {chunk :: binary(), ReplayableAudioStream.t()}}
          | {:eof, ReplayableAudioStream.t()}
  def read(
        %{buffer: buffer, current_offset: offset, bytes_per_second: bps, chunk_size: size} = state
      ) do
    bytes_per_100ns = bps / 10_000_000

    byte_offset = round(bytes_per_100ns * offset)
    byte_offset = if rem(byte_offset, 2) != 0, do: byte_offset + 1, else: byte_offset

    if byte_offset < byte_size(buffer) do
      actual_chunk_size = min(byte_size(buffer) - byte_offset, size)

      chunk = binary_part(buffer, byte_offset, actual_chunk_size)

      new_offset = offset + round(actual_chunk_size / bytes_per_100ns)
      new_state = Map.put(state, :current_offset, new_offset)

      {:ok, {chunk, new_state}}
    else
      {:eof, state}
    end
  end

  @doc """
  Shrinks the buffer, discarding everything before the current offset.
  """
  @spec shrink(ReplayableAudioStream.t()) :: ReplayableAudioStream.t()
  def shrink(%{buffer: buffer, current_offset: offset, bytes_per_second: bps} = state) do
    bytes_per_100ns = bps / 10_000_000
    byte_offset = round(bytes_per_100ns * offset)

    new_buffer = binary_part(buffer, byte_offset, byte_size(buffer) - byte_offset)

    %{
      state
      | current_offset: 0,
        buffer: new_buffer
    }
  end
end
