defmodule Podium do
  def contains?(haystack, needle) do
    check_words(haystack, needle, %{haystack_idx: 0, word_idx: 0, needle_idx: 0})
  end

  defp check_words(haystack, _needle, %{haystack_idx: haystack_idx})
       when length(haystack) <= haystack_idx do
    false
  end

  defp check_words(
         haystack,
         needle,
         %{
           haystack_idx: haystack_idx,
           word_idx: word_idx,
           needle_idx: needle_idx
         } = indexes
       ) do
    word = Enum.at(haystack, haystack_idx)

    case word_idx >= String.length(word) do
      # reached limit of current word, move to next in haystack
      true ->
        check_words(haystack, needle, %{
          haystack_idx: haystack_idx + 1,
          word_idx: 0,
          needle_idx: needle_idx
        })

      false ->
        # check if current word slice matches
        case check_word_slice(haystack, needle, indexes) do
          true ->
            true

          # increment a single letter in the word and recurse
          false ->
            check_words(haystack, needle, %{
              haystack_idx: haystack_idx,
              word_idx: word_idx + 1,
              needle_idx: 0
            })
        end
    end
  end

  defp check_word_slice(haystack, _needle, %{haystack_idx: haystack_idx})
       when length(haystack) <= haystack_idx,
       do: false

  defp check_word_slice(haystack, needle, %{
         haystack_idx: haystack_idx,
         needle_idx: needle_idx,
         word_idx: word_idx
       }) do
    word = Enum.at(haystack, haystack_idx)
    word_slice = String.slice(word, word_idx..String.length(word))

    result = check_word(word_slice, needle, needle_idx)

    case result do
      %{word_found: true} ->
        true

      %{needle_idx: 0} ->
        false

      # partial match, continue checking with next word
      %{needle_idx: needle_idx} ->
        check_word_slice(haystack, needle, %{
          haystack_idx: haystack_idx + 1,
          word_idx: 0,
          needle_idx: needle_idx
        })
    end
  end

  defp check_word(word, needle, needle_idx) do
    Enum.reduce(
      String.codepoints(word),
      %{needle_idx: needle_idx, word_found: false},
      fn char, acc ->
        cur_letter = String.at(needle, acc.needle_idx)

        case char do
          ^cur_letter ->
            acc
            |> Map.put(:needle_idx, acc.needle_idx + 1)
            |> Map.put(:word_found, check_word_found(needle, acc.needle_idx))

          _ ->
            Map.put(acc, :needle_idx, 0)
        end
      end
    )
  end

  defp check_word_found(needle, needle_idx) do
    case String.length(needle) - 1 do
      ^needle_idx -> true
      _ -> false
    end
  end
end

ExUnit.start()

defmodule ChallengeTest do
  use ExUnit.Case, async: true

  test "single node document" do
    document = ["text"]
    assert Podium.contains?(document, "ext")
    assert Podium.contains?(document, "text")
    refute Podium.contains?(document, "ed")
  end

  test "two_node_document" do
    document = ["te", "xt"]
    assert Podium.contains?(document, "ext")
    assert Podium.contains?(document, "text")
    refute Podium.contains?(document, "ed")
  end

  test "four_node_document" do
    document = ["t", "e", "x", "t"]
    assert Podium.contains?(document, "ext")
    assert Podium.contains?(document, "text")
    refute Podium.contains?(document, "ed")
  end

  test "four_node_document_with_typo" do
    document = ["t", "e", "x", "y"]
    refute Podium.contains?(document, "ext")
    refute Podium.contains?(document, "text")
    refute Podium.contains?(document, "ed")
  end

  test "complicated_document" do
    document = ["t", "ex", "dt", "ext"]
    assert Podium.contains?(document, "ext")
    assert Podium.contains?(document, "text")
    refute Podium.contains?(document, "ed")
  end

  test "single-node backtracking" do
    document = ["aaab"]
    assert Podium.contains?(document, "aab")
    refute Podium.contains?(document, "aaaaaab")
  end

  test "two-node backtracking" do
    document = ["aa", "ab"]
    assert Podium.contains?(document, "aab")
    refute Podium.contains?(document, "aaaaaab")
  end

  test "three-node backtracking" do
    document = ["aaa", "aaa", "aab"]
    assert Podium.contains?(document, "aab")
    assert Podium.contains?(document, "aaaaaab")
  end
end
