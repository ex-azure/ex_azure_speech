defmodule ExAzureSpeech.SpeechToText.Integration.BasicRecognitionTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias ExAzureSpeech.SpeechToText.Recognizer
  alias ExAzureSpeech.SpeechToText.SpeechContextConfig
  alias ExAzureSpeech.Common.BitUtils

  setup_all do
    children = [
      Recognizer
    ]

    Supervisor.start_link(children, strategy: :one_for_one)

    %{
      file_path: "priv/samples/myVoiceIsMyPassportVerifyMe01.wav",
      longform_file_path: "priv/samples/large_article.wav",
      expected_text: "My voice is my passport. Verify me."
    }
  end

  describe "recognize_once/3" do
    test "recognizes speech from audio file", %{file_path: file_path} do
      assert {:ok,
              %ExAzureSpeech.SpeechToText.Responses.SpeechPhrase{
                channel: 0,
                display_text: "By voice is my passport verify me.",
                duration: _,
                id: _,
                n_best: nil,
                offset: _,
                primary_language: nil,
                recognition_status: "Success",
                speaker_id: nil
              }} =
               Recognizer.recognize_once(:file, file_path)
    end

    test "recognize from audio bytelist", %{file_path: file_path} do
      {:ok, audio} = File.read(file_path)
      stream = BitUtils.chunks(audio, 32_768)

      assert {:ok,
              %ExAzureSpeech.SpeechToText.Responses.SpeechPhrase{
                channel: 0,
                display_text: "By voice is my passport verify me.",
                duration: _,
                id: _,
                n_best: nil,
                offset: _,
                primary_language: nil,
                recognition_status: "Success",
                speaker_id: nil
              }} =
               Recognizer.recognize_once(:stream, stream)
    end

    test "recognizes speech from audio file with pronunciation assessment", %{
      file_path: file_path,
      expected_text: expected_text
    } do
      {:ok, opts} = SpeechContextConfig.default(expected_text)

      assert {:ok,
              %ExAzureSpeech.SpeechToText.Responses.SpeechPhrase{
                channel: 0,
                display_text: "My voice is my passport. Verify me.",
                duration: _,
                id: _,
                n_best: [
                  %{
                    display: "My voice is my passport. Verify me.",
                    words: [
                      %{
                        offset: 6_800_000,
                        duration: 2_500_000,
                        word: "My",
                        pronunciation_assessment: %{error_type: "None", accuracy_score: 5.0},
                        syllables: [
                          %{
                            offset: 6_800_000,
                            duration: 2_500_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "may",
                            grapheme: "my"
                          }
                        ],
                        phonemes: [
                          %{
                            offset: 6_800_000,
                            duration: 1_700_000,
                            phoneme: "m",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 8_600_000,
                            duration: 700_000,
                            phoneme: "ay",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          }
                        ]
                      },
                      %{
                        offset: 9_400_000,
                        duration: 5_100_000,
                        word: "voice",
                        pronunciation_assessment: %{error_type: "None", accuracy_score: 5.0},
                        syllables: [
                          %{
                            offset: 9_400_000,
                            duration: 5_100_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "voys",
                            grapheme: "voice"
                          }
                        ],
                        phonemes: [
                          %{
                            offset: 9_400_000,
                            duration: 1_300_000,
                            phoneme: "v",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 10_800_000,
                            duration: 2_300_000,
                            phoneme: "oy",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 13_200_000,
                            duration: 1_300_000,
                            phoneme: "s",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          }
                        ]
                      },
                      %{
                        offset: 14_600_000,
                        duration: 1_900_000,
                        word: "is",
                        pronunciation_assessment: %{error_type: "None", accuracy_score: 5.0},
                        syllables: [
                          %{
                            offset: 14_600_000,
                            duration: 1_900_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "ihz",
                            grapheme: "is"
                          }
                        ],
                        phonemes: [
                          %{
                            offset: 14_600_000,
                            duration: 1_100_000,
                            phoneme: "ih",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 15_800_000,
                            duration: 700_000,
                            phoneme: "z",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          }
                        ]
                      },
                      %{
                        offset: 16_600_000,
                        duration: 1_500_000,
                        word: "my",
                        pronunciation_assessment: %{error_type: "None", accuracy_score: 5.0},
                        syllables: [
                          %{
                            offset: 16_600_000,
                            duration: 1_500_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "may",
                            grapheme: "my"
                          }
                        ],
                        phonemes: [
                          %{
                            offset: 16_600_000,
                            duration: 500_000,
                            phoneme: "m",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 17_200_000,
                            duration: 900_000,
                            phoneme: "ay",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          }
                        ]
                      },
                      %{
                        offset: 18_200_000,
                        duration: 7_800_000,
                        word: "passport",
                        pronunciation_assessment: %{error_type: "None", accuracy_score: 5.0},
                        syllables: [
                          %{
                            offset: 18_200_000,
                            duration: 1_700_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "pae",
                            grapheme: "pass"
                          },
                          %{
                            offset: 20_000_000,
                            duration: 6_000_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "spaort",
                            grapheme: "port"
                          }
                        ],
                        phonemes: [
                          %{
                            offset: 18_200_000,
                            duration: 800_000,
                            phoneme: "p",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 19_100_000,
                            duration: 800_000,
                            phoneme: "ae",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 20_000_000,
                            duration: 900_000,
                            phoneme: "s",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 21_000_000,
                            duration: 900_000,
                            phoneme: "p",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 22_000_000,
                            duration: 300_000,
                            phoneme: "ao",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 22_400_000,
                            duration: 700_000,
                            phoneme: "r",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 23_200_000,
                            duration: 2_800_000,
                            phoneme: "t",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          }
                        ]
                      },
                      %{
                        offset: 27_000_000,
                        duration: 5_500_000,
                        word: "Verify",
                        pronunciation_assessment: %{error_type: "None", accuracy_score: 5.0},
                        syllables: [
                          %{
                            offset: 27_000_000,
                            duration: 1_900_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "veh",
                            grapheme: "ver"
                          },
                          %{
                            offset: 29_000_000,
                            duration: 1_700_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "rih",
                            grapheme: "i"
                          },
                          %{
                            offset: 30_800_000,
                            duration: 1_700_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "fay",
                            grapheme: "fy"
                          }
                        ],
                        phonemes: [
                          %{
                            offset: 27_000_000,
                            duration: 1_300_000,
                            phoneme: "v",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 28_400_000,
                            duration: 500_000,
                            phoneme: "eh",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 29_000_000,
                            duration: 700_000,
                            phoneme: "r",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 29_800_000,
                            duration: 900_000,
                            phoneme: "ih",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 30_800_000,
                            duration: 900_000,
                            phoneme: "f",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 31_800_000,
                            duration: 700_000,
                            phoneme: "ay",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          }
                        ]
                      },
                      %{
                        offset: 32_600_000,
                        duration: 3_300_000,
                        word: "me",
                        pronunciation_assessment: %{error_type: "None", accuracy_score: 5.0},
                        syllables: [
                          %{
                            offset: 32_600_000,
                            duration: 3_300_000,
                            pronunciation_assessment: %{accuracy_score: 5.0},
                            syllable: "miy",
                            grapheme: "me"
                          }
                        ],
                        phonemes: [
                          %{
                            offset: 32_600_000,
                            duration: 900_000,
                            phoneme: "m",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          },
                          %{
                            offset: 33_600_000,
                            duration: 2_300_000,
                            phoneme: "iy",
                            pronunciation_assessment: %{accuracy_score: 5.0}
                          }
                        ]
                      }
                    ],
                    pronunciation_assessment: %{
                      accuracy_score: 5.0,
                      fluency_score: 5.0,
                      completeness_score: 5.0,
                      pron_score: 5.0
                    },
                    confidence: 0.9857913,
                    lexical: "My voice is my passport Verify me",
                    itn: "My voice is my passport Verify me",
                    masked_itn: "my voice is my passport verify me"
                  }
                ],
                offset: _,
                primary_language: nil,
                recognition_status: "Success",
                speaker_id: nil
              }} =
               Recognizer.recognize_once(:file, file_path, speech_context_opts: opts)
    end

    test "should parse longform content correctly", %{longform_file_path: file_path} do
      Recognizer.recognize_once(:file, file_path,
        speech_context_opts: [
          phrase_detection: [
            speech_segmentation_silence_ms: 1000
          ]
        ]
      )
    end
  end
end
