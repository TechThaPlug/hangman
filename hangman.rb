
require "json"

class Hangman
  MAX_INCORRECT_GUESSES = 6
  MIN_WORD_LENGTH = 5
  MAX_WORD_LENGTH = 12

  attr_reader :secret_word, :guessed_letters, :incorrect_guesses

  def initialize(dictionary_path: "dictionary.txt", secret_word: nil)
    @secret_word = secret_word || select_secret_word(dictionary_path)
    @secret_word = @secret_word.downcase

    validate_secret_word!

    @guessed_letters = []
    @incorrect_guesses = 0
  end

  def guess(letter)
    letter = letter.to_s.downcase

    return :invalid unless letter.match?(/\A[a-z]\z/)
    return :finished if finished?
    return :already_guessed if @guessed_letters.include?(letter)

    @guessed_letters << letter

    if @secret_word.include?(letter)
      :correct
    else
      @incorrect_guesses += 1
      :incorrect
    end
  end

  def display_word
    @secret_word.chars.map do |letter|
      @guessed_letters.include?(letter) ? letter : "_"
    end.join(" ")
  end

  def incorrect_letters
    @guessed_letters.reject do |letter|
      @secret_word.include?(letter)
    end
  end

  def remaining_guesses
    MAX_INCORRECT_GUESSES - @incorrect_guesses
  end

  def won?
    @secret_word.chars.all? do |letter|
      @guessed_letters.include?(letter)
    end
  end

  def lost?
    @incorrect_guesses >= MAX_INCORRECT_GUESSES
  end

  def finished?
    won? || lost?
  end

  def save_game(path)
    save_data = {
      version: 1,
      secret_word: @secret_word,
      guessed_letters: @guessed_letters,
      incorrect_guesses: @incorrect_guesses
    }

    File.open(path, "w", 0o600) do |file|
      file.write(JSON.pretty_generate(save_data))
    end

    path
  end

  def self.load_game(path)
    data = JSON.parse(File.read(path))

    unless data.is_a?(Hash) &&
           data["version"] == 1 &&
           data["secret_word"].is_a?(String) &&
           data["guessed_letters"].is_a?(Array) &&
           data["incorrect_guesses"].is_a?(Integer)
      raise ArgumentError, "Invalid saved game data."
    end

    game = new(secret_word: data["secret_word"])
    guessed_letters = data["guessed_letters"]

    valid_guesses = guessed_letters.all? do |letter|
      letter.is_a?(String) && letter.match?(/\A[a-z]\z/)
    end

    unless valid_guesses &&
           guessed_letters.uniq == guessed_letters &&
           data["incorrect_guesses"].between?(0, MAX_INCORRECT_GUESSES)
      raise ArgumentError, "Invalid saved game progress."
    end

    actual_incorrect = guessed_letters.count do |letter|
      !game.secret_word.include?(letter)
    end

    unless actual_incorrect == data["incorrect_guesses"]
      raise ArgumentError, "Saved game progress is inconsistent."
    end

    game.instance_variable_set(:@guessed_letters, guessed_letters)
    game.instance_variable_set(
      :@incorrect_guesses,
      data["incorrect_guesses"]
    )

    game
  rescue JSON::ParserError
    raise ArgumentError, "Saved game file contains invalid JSON."
  end

  private

  def select_secret_word(dictionary_path)
    unless File.file?(dictionary_path)
      raise Errno::ENOENT, "Dictionary file not found: #{dictionary_path}"
    end

    words = File.readlines(dictionary_path, chomp: true).map(&:strip).select do |word|
      word.match?(/\A[a-zA-Z]{#{MIN_WORD_LENGTH},#{MAX_WORD_LENGTH}}\z/)
    end

    raise "Dictionary contains no suitable words." if words.empty?

    words.sample
  end

  def validate_secret_word!
    valid = @secret_word.match?(
      /\A[a-z]{#{MIN_WORD_LENGTH},#{MAX_WORD_LENGTH}}\z/
    )

    return if valid

    raise ArgumentError, "Secret word must contain 5 to 12 letters."
  end
end
