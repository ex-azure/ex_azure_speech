defmodule ExAzureSpeech.SpeechToText.Responses.EndDetected do
  @moduledoc """
  Represents the end of a speech recognition session.
  """
  defstruct [:offset]

  alias __MODULE__

  @type t() :: %EndDetected{
          offset: non_neg_integer()
        }
end
