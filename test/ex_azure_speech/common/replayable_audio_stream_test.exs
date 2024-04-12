defmodule ExAzureSpeech.Common.ReplayableAudioStreamTest do
  use ExUnit.Case

  alias ExAzureSpeech.Common.ReplayableAudioStream

  @bytes_per_second 16_000 * 16
  @riff_header_size 44

  describe "read/1" do
    test "should be able to read starting from an offset" do
      {:ok, binary} = File.read("priv/samples/myVoiceIsMyPassportVerifyMe01.wav")

      assert {:ok, {chunk, %{current_offset: current_offset}}} =
               ReplayableAudioStream.read(%{
                 buffer: binary,
                 current_offset: 0,
                 bytes_per_second: @bytes_per_second,
                 chunk_size: @riff_header_size
               })

      assert current_offset == 1719
      assert "RIFF" == binary_part(chunk, 0, 4)
      assert "WAVE" == binary_part(chunk, 8, 4)
      assert <<1, 0>> = binary_part(chunk, 20, 2)
      assert <<1, 0>> = binary_part(chunk, 22, 2)
      assert 16_000 = binary_part(chunk, 24, 4) |> :binary.decode_unsigned(:little)
      assert 32_000 = binary_part(chunk, 28, 4) |> :binary.decode_unsigned(:little)
      assert 44 = byte_size(chunk)
    end

    test "should the offset be equal to the buffer size, it should return an eof" do
      {:ok, binary} = File.read("priv/samples/myVoiceIsMyPassportVerifyMe01.wav")

      assert {:eof, %{current_offset: 38_675_000}} =
               ReplayableAudioStream.read(%{
                 buffer: binary,
                 current_offset: 38_675_000,
                 bytes_per_second: @bytes_per_second,
                 chunk_size: @riff_header_size
               })
    end
  end

  describe "shrink/1" do
    test "Should be able to shrink the buffer, discarding everything before the current offset" do
      {:ok, binary} = File.read("priv/samples/myVoiceIsMyPassportVerifyMe01.wav")

      assert {:ok,
              %{current_offset: 0, buffer: buffer} =
                ReplayableAudioStream.shrink(%{
                  buffer: binary,
                  current_offset: 1719,
                  bytes_per_second: @bytes_per_second,
                  chunk_size: @riff_header_size
                })}

      assert byte_size(buffer) == byte_size(binary) - 44
    end
  end
end
