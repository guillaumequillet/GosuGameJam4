require 'gosu'
require_relative './player.rb'
require_relative './camera.rb'
require_relative './enemy.rb'
require_relative './pickup.rb'
require_relative './map.rb'

class Window < Gosu::Window
  attr_reader :font, :map, :player
  def initialize
    super(320, 240, true)
    self.caption = 'Gosu Game Jam 4 - Platformer'
    @validate_keys = [Gosu::KB_SPACE, Gosu::GP_0_BUTTON_0]
    @state = :title
    @backgrounds = {
      title: Gosu::Image.new('./gfx/title_screen.png', retro: true),
      game_over: Gosu::Image.new('./gfx/game_over_screen.png', retro: true),
      finished: Gosu::Image.new('./gfx/finished_screen.png', retro: true)
    }
    @font = Gosu::Font.new(16, {
      name: './gfx/rainyhearts.ttf',
      retro: true
    })

    @song = Gosu::Song.new('./sfx/Jungle Groove Grove.ogg')
    @song.volume = 0.3
    @song.play

    @validate_sound = Gosu::Sample.new('./sfx/vgmenuselect.wav')
  end
  
  def button_down(id)
    super
    close! if id == Gosu::KB_ESCAPE

    if defined?(@player)
      @player.button_down(id)
    end

    if @validate_keys.any? {|key| key == id}
      case @state
      when :title
        @validate_sound.play
        reset_game
      when :game_over
        @validate_sound.play
        @state = :title
      when :finished
        @validate_sound.play
        reset_game
        @state = :title
      end
    end
  end

  def next_level
    @current_level += 1
    if (File.exists?("maps/map_#@current_level.tmj"))
      @last_score = @score # save if life is lost
      reset
    else
      # game is finished
      @score += @lives * 10000 # 10000 for each remaining life
      @state = :finished
    end
  end

  def lose_life
    @lives -= 1
    if @lives < 0
      @state = :game_over
    end
  end
  
  def reset
    @score = @last_score
    @map = Map.new(self, "map_#@current_level.tmj")
    @player = Player.new(self, @map.start_x, @map.start_y)
    @camera = Camera.new(self)
    @camera.set_target(@player)
  end

  def reset_game
    @current_level = 0
    @score = 0
    @last_score = @score
    @lives = 3
    @state = :game
    reset
  end

  def validate_pickup(pickup)
    @score += pickup.reward
  end

  def update
    case @state
    when :game
      @player.update
      @map.update
      @camera.update
    end
  end

  def draw
    case @state
    when :title
      @backgrounds[:title].draw(0, 0, 0)
      text = 'Press action button or space to start'
      @font.draw_text(text, (self.width - @font.text_width(text)) / 2, (self.height - @font.height) / 2, 2)
      @font.draw_text(text, (self.width - @font.text_width(text)) / 2 + 1, (self.height - @font.height) / 2 + 1, 1, 1, 1, Gosu::Color::BLACK)
    when :game
      @map.draw_background
      @camera.look do
        @player.draw
        @map.draw
      end

      @font.draw_text("Score : #@score", 10, 10, 2)
      @font.draw_text("Score : #@score", 10 + 1, 10 + 1, 1, 1, 1, Gosu::Color::BLACK)

      remaining_lives = "Lives : #@lives"
      @font.draw_text(remaining_lives, self.width - @font.text_width(remaining_lives) - 10, self.height - @font.height, 2)
      @font.draw_text(remaining_lives, self.width - @font.text_width(remaining_lives) - 10 + 1, self.height - @font.height + 1, 1, 1, 1, Gosu::Color::BLACK)
      
      @map.draw_hud
    when :game_over
      @backgrounds[:game_over].draw(0, 0, 0)
    when :finished
      @backgrounds[:finished].draw(0, 0, 0)
      @font.draw_text("Score : #@score", 13, 183, 2, 3, 3, Gosu::Color::BLACK)
      @font.draw_text("Score : #@score", 10, 180, 2, 3, 3)
    end
  end
end

Window.new.show