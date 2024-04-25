defmodule ExAzureSpeech.TextToSpeech.Responses.AudioMetadata do
  @moduledoc """
  Represents metadata responses from the Azure Text to Speech service.
  """
  @moduledoc section: :text_to_speech
  defstruct [:metadata]

  alias __MODULE__

  @type viseme() :: %{
          offset: integer(),
          viseme_id: integer(),
          is_last_animation: boolean()
        }

  @type word_boundary() :: %{
          offset: integer(),
          duration: integer(),
          text: %{
            text: String.t(),
            length: integer(),
            boundary_type: String.t()
          }
        }

  @type sentence_boundary() :: %{
          offset: integer(),
          duration: integer(),
          text: %{
            text: String.t(),
            length: integer(),
            boundary_type: String.t()
          }
        }

  @type session_end() :: %{
          offset: integer()
        }

  @type t() :: %AudioMetadata{
          metadata:
            list(%{
              type: String.t(),
              data: viseme() | word_boundary() | sentence_boundary() | session_end()
            })
        }
end
