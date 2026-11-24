
require_relative "hangman"

SAVE_DIRECTORY = "saved_games"

class HangmanCLI
  def initialize
    Dir.mkdir(SAVE_DIRECTORY) unless Dir.exist?(SAVE_DIRECTORY)
  end

  def start
    loop do
      puts "\n========== HANGMAN =========="
      puts "1. Start a new game"
      puts "2. Load a saved game"
      puts "3. Exit"
      puts "============================="

      print "Choose an option: "
      choice = gets&.strip

      case choice
      when "1"
        play(Hangman.new)
      when "2"
        load_saved_game
      when "3"
        puts "\nThanks for playing Hangman!"
        break
      else
        puts "\nInvalid choice. Please choose 1, 2, or 3."
      end
    end
  end

  private

  def play(game)
    until game.finished?
      display_game(game)

      print "\nEnter a letter or type 'save' to save: "
      input = gets&.strip&.downcase

      break if input.nil?

      if input == "save"
        save_game(game)
        return
      end

      result = game.guess(input)

      case result
      when :correct
        puts "Correct guess!"
      when :incorrect
        puts "Incorrect guess!"
      when :already_guessed
        puts "You have already guessed that letter."
      when :invalid
        puts "Please enter a single letter from A to Z."
      when :finished
        puts "This game has already finished."
      end
    end

    display_game(game)
    puts game.won? ? "\nCongratulations! You won!" : "\nGame over! The word was: #{game.secret_word}"
  end

  def display_game(game)
    puts "\nWord: #{game.display_word}"
    puts "Incorrect letters: #{game.incorrect_letters.join(', ')}"
    puts "Incorrect guesses remaining: #{game.remaining_guesses}"
  end

  def save_game(game)
    filename = "hangman_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
    path = File.join(SAVE_DIRECTORY, filename)

    game.save_game(path)

    puts "\nGame saved successfully!"
    puts "Saved as: #{filename}"
  rescue SystemCallError => e
    puts "\nUnable to save the game: #{e.message}"
  end

  def load_saved_game
    files = Dir.glob(File.join(SAVE_DIRECTORY, "*.json")).sort

    if files.empty?
      puts "\nNo saved games found."
      return
    end

    puts "\n========== SAVED GAMES =========="

    files.each_with_index do |file, index|
      puts "#{index + 1}. #{File.basename(file)}"
    end

    print "Choose a saved game (or 0 to cancel): "
    choice = gets&.strip

    return if choice == "0"

    index = Integer(choice, exception: false)

    unless index && index.between?(1, files.length)
      puts "\nInvalid selection."
      return
    end

    game = Hangman.load_game(files[index - 1])
    puts "\nSaved game loaded successfully!"

    play(game)
  rescue ArgumentError, SystemCallError => e
    puts "\nUnable to load saved game: #{e.message}"
  end
end

HangmanCLI.new.start
