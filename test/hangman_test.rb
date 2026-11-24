
require "minitest/autorun"
require "tmpdir"
require_relative "../hangman"

class HangmanTest < Minitest::Test
  def setup
    @game = Hangman.new(secret_word: "programming")
  end

  def test_secret_word_is_stored
    assert_equal "programming", @game.secret_word
  end

  def test_random_word_is_selected_from_dictionary
    game = Hangman.new(dictionary_path: "dictionary.txt")

    assert_operator game.secret_word.length, :>=, 5
    assert_operator game.secret_word.length, :<=, 12
    assert_match(/\A[a-z]+\z/, game.secret_word)
  end

  def test_correct_guess
    assert_equal :correct, @game.guess("p")
    assert_includes @game.guessed_letters, "p"
  end

  def test_incorrect_guess
    assert_equal :incorrect, @game.guess("z")
    assert_equal 1, @game.incorrect_guesses
  end

  def test_guesses_are_case_insensitive
    assert_equal :correct, @game.guess("P")
    assert_includes @game.guessed_letters, "p"
  end

  def test_repeated_guess_is_rejected
    @game.guess("p")

    assert_equal :already_guessed, @game.guess("p")
  end

  def test_invalid_guess_is_rejected
    assert_equal :invalid, @game.guess("12")
    assert_equal :invalid, @game.guess("ab")
    assert_equal :invalid, @game.guess("")
  end

  def test_display_word
    @game.guess("p")
    @game.guess("r")

    assert_equal "p r _ _ r _ _ _ _ _ _", @game.display_word
  end

  def test_incorrect_letters
    @game.guess("z")
    @game.guess("x")

    assert_equal %w[z x], @game.incorrect_letters
  end

  def test_remaining_guesses
    @game.guess("z")
    @game.guess("x")

    assert_equal 4, @game.remaining_guesses
  end

  def test_player_wins
    "programing".chars.uniq.each do |letter|
      @game.guess(letter)
    end

    assert @game.won?
    assert @game.finished?
  end

  def test_player_loses
    %w[x y z b c d].each do |letter|
      @game.guess(letter)
    end

    assert @game.lost?
    assert @game.finished?
    assert_equal 0, @game.remaining_guesses
  end

  def test_guesses_are_rejected_after_game_finishes
    %w[x y z b c d].each do |letter|
      @game.guess(letter)
    end

    assert_equal :finished, @game.guess("p")
  end

  def test_game_can_be_saved_and_loaded
    @game.guess("p")
    @game.guess("z")
    @game.guess("r")

    Dir.mktmpdir do |directory|
      path = File.join(directory, "saved_game.json")

      @game.save_game(path)
      loaded_game = Hangman.load_game(path)

      assert_equal @game.secret_word, loaded_game.secret_word
      assert_equal @game.guessed_letters, loaded_game.guessed_letters
      assert_equal @game.incorrect_guesses, loaded_game.incorrect_guesses
      assert_equal @game.display_word, loaded_game.display_word
      assert_equal @game.remaining_guesses, loaded_game.remaining_guesses
    end
  end

  def test_invalid_saved_game_is_rejected
    Dir.mktmpdir do |directory|
      path = File.join(directory, "invalid.json")
      File.write(path, "{invalid json")

      assert_raises(ArgumentError) do
        Hangman.load_game(path)
      end
    end
  end

  def test_invalid_saved_game_data_is_rejected
    Dir.mktmpdir do |directory|
      path = File.join(directory, "invalid.json")

      File.write(
        path,
        '{"version":1,"secret_word":"programming","guessed_letters":["p"],"incorrect_guesses":5}'
      )

      assert_raises(ArgumentError) do
        Hangman.load_game(path)
      end
    end
  end
end
