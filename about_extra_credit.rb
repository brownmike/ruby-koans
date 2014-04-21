# EXTRA CREDIT:
#
# Create a program that will play the Greed Game.
# Rules for the game are in GREED_RULES.TXT.
#
# You already have a DiceSet class and score function you can use.
# Write a player class and a Game class to complete the project.  This
# is a free form assignment, so approach it however you desire.

class Game
  def initialize(*player_names)
    @players = []
    player_names.each do |name|
      @players << Player.new(name)
    end
    print_welcome_message
    game_loop
  end

  def self.score(dice)
    return 0 if dice.empty?

    side_counts = []

    (1..6).each do |number|
      side_counts << dice.select { |d| d == number }.count
    end

    def self.total(side_counts, side=1, running_total=0)
      return running_total if side_counts.empty?

      count = side_counts.shift

      case side
      when 1
        running_total += ((count / 3) * 1000) + ((count % 3) * 100)
      when 5
        running_total += ((count / 3) * 100 * 5) + ((count % 3) * 50)
      when 2, 3, 4, 6
        running_total += ((count / 3) * 100 * side)
      end

      total(side_counts, side += 1, running_total)
    end

    total(side_counts)
  end

  private
    def player_over_3k?
      @players.any? { |player| player.score > 3000 }
    end

    def game_loop(options={})
      @players.each do |player|
        play_turn(player, 5)
      end

      if options[:last_round?]
        puts ""
        puts "GAME OVER DUDE"
      elsif player_over_3k?
        game_loop(last_round?: true)
      else
        game_loop
      end
    end

    def play_turn(player, number_of_dice, turn_score=0, options={})
      system('clear')
      puts "Player #{player.name.capitalize}"
      puts "=== Score: #{player.score} ==="
      puts "=== Turn Score: #{turn_score} ==="

      roll_total = player.roll!(number_of_dice)

      if player.rolls.empty?
        print_roll(player.pre_game_rolls.last)
      else
        print_roll(player.rolls.last)
      end

      puts ""
      puts "Your roll is worth #{roll_total} points."

      if options[:reroll] and roll_total == 0
        puts ""
        puts "Whoops. You didn't score any points on your reroll."
        puts "You lose all points from this turn. Tough luck!"
        player.score -= turn_score
        print_end_turn(player)
        return
      end

      dead_dice = player.non_scoring_dice
      if dead_dice and player.in_the_game? and roll_total > 0
        if prompt_for_roll(non_scoring_dice: dead_dice) == "y"
          play_turn(player, (dead_dice == 0 ? 5 : dead_dice), turn_score += roll_total, reroll: true)
        else
          print_end_turn(player)
        end
      else
        print_end_turn(player)
      end
    end

    def prompt_for_roll(options={})
      answer = nil
      dead_dice = options[:non_scoring_dice]
      puts ""

      if dead_dice
        if dead_dice == 0
          puts "All of your dice scored."
          print "Would you like to roll again? (y/n): "
        elsif dead_dice > 0
          puts "You have #{dead_dice} non-scoring dice."
          print "Would you like to re-roll them? (y/n): "
        end
      else
        print "Ready to roll? (y): "
      end

      while !%w[y n].include?(answer)
        answer = gets.chomp.downcase
      end
      answer
    end

    def print_end_turn(player)
      puts ""
      puts "=== #{player.name.capitalize}'s turn ended with a score of #{player.score} ==="
      puts ""
      puts "Press any key to continue..."
      gets
    end

    def print_roll(roll)
      sleep 1
      puts ""
      puts "Your Roll:"
      puts "=> " + roll.sort.join(", ")
    end

    def print_welcome_message
      system('clear')
      puts "Welcome to Greed"
      puts "================"
      puts ""
    end
end

class Player
  attr_reader :name, :rolls, :pre_game_rolls
  attr_accessor :score

  def initialize(name)
    @name = name
    @rolls = []
    @pre_game_rolls = []
    @score = 0
    @dice = DiceSet.new
  end

  def in_the_game?
    @score >= 300
  end

  def non_scoring_dice
    roll = @rolls.last
    return nil if roll.nil?

    side_counts = []

    # find out how many 2s, 3s, 4s, & 6s were rolled
    [2,3,4,6].each do |side|
      side_counts << roll.select { |d| d == side }.count
    end

    # return the number of them that were not part of a set of 3
    side_counts.select { |count| count % 3 > 0 }.count
  end

  def roll!(number_of_dice)
    @dice.roll(number_of_dice)
    total = Game.score(@dice.values)
    if @rolls.empty? and total >= 300
      @rolls << @dice.values
      @score += total
    elsif @rolls.count > 0
      @rolls << @dice.values
      @score += total
    elsif @rolls.empty? and total < 300
      @pre_game_rolls << @dice.values
    end
    total
  end
end

class DiceSet
  attr_reader :values

  def roll(number_of_dice)
    @values = []
    number_of_dice.times do
      @values << Random.new.rand(1..6)
    end
    @values
  end
end
