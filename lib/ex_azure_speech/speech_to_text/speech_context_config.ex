defmodule ExAzureSpeech.SpeechToText.SpeechContextConfig do
  @moduledoc """
  Configures the Speech-to-Text context.--
  THe objective of the Speech Context is to provide more data to the Speech-to-Text service, so it can better understand the user's speech,
  it also provides configurations for speech assessment and detailed output analysis.
  """
  @moduledoc section: :speech_to_text
  @schema NimbleOptions.new!(
            phrase_detection: [
              type: :keyword_list,
              required: false,
              doc: """
              Specifies details about the phrase detection.
              """,
              keys: [
                recognition_mode: [
                  type: {:in, [:interactive, :conversation, :dictation]},
                  required: false,
                  doc: """
                  The recognition mode to be used. `:interactive` is optimized for short phrases, `:conversation` is optimized for conversational speech, and `:dictation` is optimized for long-form speech.
                  """
                ],
                speech_segmentation_silence_ms: [
                  type: :integer,
                  required: false,
                  doc: """
                  The minimum length of silence that indicates the end of a phrase.  
                  """
                ]
              ]
            ],
            speech_assessment: [
              type: :keyword_list,
              required: false,
              doc: """
              Configuration for the speech aassesment, if not informed, assessment will not be performed.  
              """,
              keys: [
                reference_text: [
                  type: :string,
                  required: false,
                  default: "",
                  doc: """
                  The reference text to be used to evaluate the user's speech.  
                  This is optional for unscripted assessment.
                  """
                ],
                grading_system: [
                  type: {:in, [:five_point, :hundred_mark]},
                  default: :five_point,
                  doc: """
                  The grading system to be used to evaluate the user's speech.  

                  Supported grading systems:  
                  - :five_point - The user's speech will be graded on a scale of 1 to 5.  
                  - :hundred_mark - The user's speech will be graded on a scale of 0 to 100.  
                  """
                ],
                granularity: [
                  type: {:in, [:phoneme, :word, :fulltext]},
                  default: :phoneme,
                  doc: """
                  The granularity to be used to evaluate the user's speech.  

                  Supported granularities:  
                  - :phoneme - The user's speech will be evaluated at the phoneme level.  
                  - :word - The user's speech will be evaluated at the word level.  
                  - :fulltext - The user's speech will be evaluated at the full text level.  
                  """
                ],
                dimension: [
                  type: {:in, [:comprehensive, :basic]},
                  default: :comprehensive,
                  doc: """
                  How many dimensions will be outputted for the user's speech.  

                  Supported dimensions:  
                  - :comprehensive - All dimensions will be outputted.  
                  - :basic - Only the basic dimensions will be outputted.  
                  """
                ],
                enable_prosody_assessment: [
                  type: :boolean,
                  default: false,
                  doc: """
                  If the prosody assessment should be enabled or not.  
                  """
                ],
                enable_miscue: [
                  type: :boolean,
                  default: false,
                  doc: """
                  If miscues should be validated in the prosody assessment.  
                  """
                ]
              ]
            ]
          )

  @typedoc """
  #{NimbleOptions.docs(@schema)}  
  ## Example Configuration  
    
      [
        phrase_detection: [
          speech_segmentation_silence_ms: 500
        ],
        speech_assessment: [
          reference_text: "The quick brown fox jumps over the lazy dog.",
          grading_system: :five_point,
          granularity: :phoneme,
          dimension: :comprehensive,
          enable_prosody_assessment: true,
          enable_miscue: true
        ]
      ]
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Returns a valid configuration for the Speech-to-Text context.
  """
  @spec new(Keyword.t()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(opts), do: NimbleOptions.validate(opts, @schema)
end
