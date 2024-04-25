defmodule ExAzureSpeech.TextToSpeech.SpeechSynthesisConfig do
  @moduledoc """
  Configures the Text-to-Speech Synthesis context.
  """
  @moduledoc section: :text_to_speech

  require ExAzureSpeech.Common.OutputFormats

  @schema NimbleOptions.new!(
            audio: [
              type: :keyword_list,
              default: [],
              keys: [
                metadata_options: [
                  type: :keyword_list,
                  default: [],
                  keys: [
                    bookmark_enabled: [
                      type: :boolean,
                      required: false,
                      default: false
                    ],
                    punctuation_boundary_enabled: [
                      type: :boolean,
                      required: false,
                      default: true,
                      doc: """
                      Specifies whether punctuation boundary data should be included in the output.
                      """
                    ],
                    sentence_boundary_enabled: [
                      type: :boolean,
                      required: false,
                      default: true,
                      doc: """
                      Specifies whether sentence boundary data should be included in the output.
                      """
                    ],
                    word_boundary_enabled: [
                      type: :boolean,
                      required: false,
                      default: false,
                      doc: """
                      Specifies whether word boundary data should be included in the output.
                      """
                    ],
                    session_end_enabled: [
                      type: :boolean,
                      required: false,
                      default: false,
                      doc: """
                      Specifies whether session end data should be included in the output.
                      """
                    ],
                    viseme_enabled: [
                      type: :boolean,
                      default: false,
                      required: false,
                      doc: """
                      Specifies whether viseme data should be included in the output.
                      """
                    ]
                  ]
                ],
                output_format: [
                  type: {:in, ExAzureSpeech.Common.OutputFormats.formats()},
                  type_doc: "`ExAzureSpeech.Common.OutputFormats.t()`",
                  required: false,
                  default: "riff-24khz-16bit-mono-pcm",
                  doc: """
                  Specifies the output format for the audio.
                  """
                ]
              ]
            ],
            language: [
              type: :keyword_list,
              default: [],
              keys: [
                auto_detection: [
                  type: :boolean,
                  default: false,
                  required: false,
                  doc: """
                  Specifies whether the language should be automatically detected.
                  """
                ]
              ]
            ]
          )

  @typedoc """
  #{NimbleOptions.docs(@schema)}  
  ## Example Configuration  
    
      [
        audio: [
          metadata_options: [
            bookmark_enabled: false,
            punctuation_boundary_enabled: true,
            sentence_boundary_enabled: true,
            word_boundary_enabled: false,
            session_end_enabled: false,
            viseme_enabled: false
          ],
          output_format: "riff-24khz-16bit-mono-pcm"
        ],
        language: [
          auto_detection: false
        ]
      ]
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Returns a valid configuration for the Text-to-Speech context.
  """
  @spec new(Keyword.t()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(opts), do: NimbleOptions.validate(opts, @schema)
end
