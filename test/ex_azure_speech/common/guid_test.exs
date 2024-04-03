defmodule ExAzureSpeech.Common.GuidTest do
  use ExUnit.Case, async: true

  alias ExAzureSpeech.Common.Guid

  test "should generate a new GUID" do
    guid = Guid.create_no_dash_guid()
    assert String.length(guid) == 32
  end
end
