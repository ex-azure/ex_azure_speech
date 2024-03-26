defmodule ExAzureCognitiveServicesSpeechSdkTest do
  use ExUnit.Case
  doctest ExAzureCognitiveServicesSpeechSdk

  test "greets the world" do
    assert ExAzureCognitiveServicesSpeechSdk.hello() == :world
  end
end
