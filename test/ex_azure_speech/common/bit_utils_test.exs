defmodule ExAzureSpeech.Common.BitUtilsTest do
  use ExUnit.Case, async: true

  alias ExAzureSpeech.Common.BitUtils

  describe "chunks/2" do
    test "splits a binary into chunks of size `n`" do
      assert [
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<1::size(2)>>,
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<2::size(2)>>,
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<3::size(2)>>,
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<1::size(2)>>,
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<0::size(2)>>,
               <<1::size(2)>>,
               <<1::size(2)>>
             ] == BitUtils.chunks(<<1, 2, 3, 4, 5>>, 2)
    end
  end
end
