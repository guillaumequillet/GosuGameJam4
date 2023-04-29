require 'gosu'
require_relative './player.rb'
require_relative './camera.rb'
require_relative './map.rb'

class Window < Gosu::Window
  attr_reader :map
  def initialize
    super(320, 240, true)
    self.caption = 'Gosu Game Jam 4 - Platformer'
    reset
  end
  
  def button_down(id)
    super
    close! if id == Gosu::KB_ESCAPE
    @player.button_down(id)
    
    reset if id == Gosu::KB_F5
  end

  def button_up(id)
    @player.button_up(id)
  end
  
  def reset
    @map = Map.new('test.tmj')
    @player = Player.new(self, 64, 96)
    @camera = Camera.new(self)
    @camera.set_target(@player)
  end

  def update
    @player.update
    @map.update
    @camera.update
  end

  def draw
    @camera.look do
      @player.draw
      @map.draw
    end
  end
end

Window.new.show