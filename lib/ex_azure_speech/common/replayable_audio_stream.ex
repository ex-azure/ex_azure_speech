defmodule ExAzureSpeech.Common.ReplayableAudioStream do
  @moduledoc """
  Implements a way to read audio-streams with the capability to rewing and restart from a specific offset point.
  """
  @moduledoc section: :common

  defstruct stream: [],
            buffer: <<>>,
            buffer_offset: 0,
            last_read_offset: 0,
            bytes_per_second: 0,
            chunk_size: 32_768

  alias __MODULE__

  @typedoc """
  stream: Underlying stream of audio data.  
  buffer: The binary buffer to hold streammed data.  
  buffer_offset: The current offset in the buffer, each 1 increase in the offset represents 100ns of audio.  
  last_read_offset: The last offset reead from the source stream.  
  bytes_per_second: The number of bytes per second in the audio stream. Calculated as sample_rate * bits_per_sample * channels.  
  chunk_size: The size in bytes of the chunk to read from the buffer. Note that the chunk cannot be larger than 65535 bytes.  
  """
  @type t() :: %ReplayableAudioStream{
          stream: Enumerable.t(),
          buffer: binary(),
          buffer_offset: non_neg_integer(),
          last_read_offset: non_neg_integer(),
          bytes_per_second: non_neg_integer(),
          chunk_size: non_neg_integer()
        }

  @doc """
  Reads a chunk of audio from a streamable source, buffering it and returning the chunk. This approach allows rewinding
  the stream to a specific offset point, replay it and continue reading from the stream from point onwards.
  """
  @spec read(ReplayableAudioStream.t()) ::
          {:ok, {chunk :: binary() | :eof, ReplayableAudioStream.t()}}
  def read(
        %{
          buffer: buffer,
          buffer_offset: offset,
          last_read_offset: last_read_offset,
          bytes_per_second: bps,
          chunk_size: size
        } = state
      )
      when offset < last_read_offset do
    bytes_per_100ns = bps / 10_000_000

    byte_offset = round(bytes_per_100ns * offset)
    byte_offset = if rem(byte_offset, 2) != 0, do: byte_offset + 1, else: byte_offset

    actual_chunk_size = min(byte_size(buffer) - byte_offset, size)

    chunk = binary_part(buffer, byte_offset, actual_chunk_size)

    new_offset = offset + round(actual_chunk_size / bytes_per_100ns)
    new_state = %ReplayableAudioStream{state | buffer_offset: new_offset}

    {:ok, {chunk, new_state}}
  end

  def read(
        %{
          stream: stream,
          buffer: buffer,
          bytes_per_second: bps
        } = state
      ) do
    chunk =
      stream
      |> Stream.take(1)
      |> Enum.to_list()
      |> :binary.list_to_bin()

    if chunk == <<>> do
      {:ok, {:eof, state}}
    else
      duration = byte_size(chunk) / bps
      duration_in_100ns = duration * 1_000_000_000
      last_read_offset_size = round(duration_in_100ns / 100)
      last_read_offset = state.last_read_offset + last_read_offset_size

      new_state = %ReplayableAudioStream{
        state
        | buffer: <<buffer::binary, chunk::binary>>,
          buffer_offset: last_read_offset,
          last_read_offset: last_read_offset,
          stream: Stream.drop(stream, 1)
      }

      {:ok, {chunk, new_state}}
    end
  end

  @doc """
  Shrinks the buffer, discarding everything before the current offset.
  """
  @spec shrink(ReplayableAudioStream.t()) :: ReplayableAudioStream.t()
  def shrink(%{buffer: buffer, buffer_offset: offset, bytes_per_second: bps} = state) do
    bytes_per_100ns = bps / 10_000_000
    byte_offset = round(bytes_per_100ns * offset)

    new_buffer = binary_part(buffer, byte_offset, byte_size(buffer) - byte_offset)

    %ReplayableAudioStream{
      state
      | buffer_offset: 0,
        last_read_offset: state.last_read_offset - byte_offset,
        buffer: new_buffer
    }
  end
end
