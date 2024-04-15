defmodule ExAzureSpeech.Common.ReplayableAudioStreamTest do
  use ExUnit.Case

  alias ExAzureSpeech.Common.ReplayableAudioStream

  @bytes_per_second 16_000 * 16 / 8
  @riff_header_size 44

  describe "read/1" do
    test "should be able to read from the buffer starting from an offset" do
      {:ok, binary} = File.read("priv/samples/myVoiceIsMyPassportVerifyMe01.wav")

      assert {:ok, {chunk, %{buffer_offset: buffer_offset}}} =
               ReplayableAudioStream.read(%ReplayableAudioStream{
                 buffer: binary,
                 buffer_offset: 0,
                 last_read_offset: 38_675_000,
                 bytes_per_second: @bytes_per_second,
                 chunk_size: @riff_header_size
               })

      assert buffer_offset == 13_750
      assert "RIFF" == binary_part(chunk, 0, 4)
      assert "WAVE" == binary_part(chunk, 8, 4)
      assert <<1, 0>> = binary_part(chunk, 20, 2)
      assert <<1, 0>> = binary_part(chunk, 22, 2)
      assert 16_000 = binary_part(chunk, 24, 4) |> :binary.decode_unsigned(:little)
      assert 32_000 = binary_part(chunk, 28, 4) |> :binary.decode_unsigned(:little)
      assert 44 = byte_size(chunk)
    end

    test "should stream from a file to the buffer, returning the chunk" do
      stream = File.stream!("priv/samples/myVoiceIsMyPassportVerifyMe01.wav", [], 1024)

      assert {:ok,
              {chunk,
               %{
                 buffer_offset: buffer_offset,
                 buffer: buffer,
                 last_read_offset: last_read_offset
               }}} =
               ReplayableAudioStream.read(%ReplayableAudioStream{
                 stream: stream,
                 buffer: <<>>,
                 buffer_offset: 0,
                 last_read_offset: 0,
                 bytes_per_second: @bytes_per_second,
                 chunk_size: @riff_header_size
               })

      assert chunk == buffer
      assert buffer_offset == 320_000
      assert last_read_offset == 320_000
    end

    test "should be able to read chunk-by-chunk" do
      stream = File.stream!("priv/samples/myVoiceIsMyPassportVerifyMe01.wav", [], 1024)

      assert {:ok, {_chunk, state}} =
               ReplayableAudioStream.read(%ReplayableAudioStream{
                 stream: stream,
                 buffer: <<>>,
                 buffer_offset: 0,
                 last_read_offset: 0,
                 bytes_per_second: @bytes_per_second,
                 chunk_size: @riff_header_size
               })

      assert {:ok,
              {
                chunk,
                %{
                  buffer_offset: buffer_offset,
                  buffer: buffer,
                  last_read_offset: last_read_offset
                }
              }} =
               ReplayableAudioStream.read(state)

      assert byte_size(chunk) == 1024
      assert byte_size(chunk) <= byte_size(buffer)
      assert buffer_offset == 640_000
      assert last_read_offset == 640_000
    end

    test "should be able to replay starting from an earlier offset" do
      {:ok, binary} = File.read("priv/samples/myVoiceIsMyPassportVerifyMe01.wav")

      assert {:ok, {chunk, state}} =
               ReplayableAudioStream.read(%ReplayableAudioStream{
                 stream: [binary],
                 buffer: <<>>,
                 buffer_offset: 0,
                 last_read_offset: 0,
                 bytes_per_second: @bytes_per_second,
                 chunk_size: 1024
               })

      assert {:ok, {chunk, state}} =
               ReplayableAudioStream.read(%ReplayableAudioStream{state | buffer_offset: 640_000})

      assert byte_size(chunk) == 1024
      assert state.buffer_offset == 960_000
      assert state.last_read_offset == 38_675_000
    end

    test "should last_read_offset be the end-of-file, should return a eof" do
      {:ok, binary} = File.read("priv/samples/myVoiceIsMyPassportVerifyMe01.wav")

      assert {:ok, {chunk, state}} =
               ReplayableAudioStream.read(%ReplayableAudioStream{
                 stream: [binary],
                 buffer: <<>>,
                 buffer_offset: 0,
                 last_read_offset: 0,
                 bytes_per_second: @bytes_per_second,
                 chunk_size: @riff_header_size
               })

      assert {:ok, {:eof, ^state}} = ReplayableAudioStream.read(state)
    end
  end

  describe "shrink/1" do
    test "Should be able to shrink the buffer, discarding everything before the current offset" do
      {:ok, binary} = File.read("priv/samples/myVoiceIsMyPassportVerifyMe01.wav")

      assert {:ok,
              %{buffer_offset: 0, buffer: buffer} =
                ReplayableAudioStream.shrink(%ReplayableAudioStream{
                  buffer: binary,
                  buffer_offset: 13_750,
                  bytes_per_second: @bytes_per_second,
                  chunk_size: @riff_header_size
                })}

      assert byte_size(buffer) == byte_size(binary) - 44
    end
  end
end
