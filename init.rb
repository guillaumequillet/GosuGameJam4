require 'gosu'
require_relative './player.rb'
require_relative './map.rb'

class Window < Gosu::Window
  def initialize
    super(320, 240, true)
    self.caption = 'Gosu Game Jam 4 - Platformer'
    reset
  end
  
  def collision?(x, y, w, h)
    @map.collision?(x, y, w, h)
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
  end

  def update
    @player.update
    @map.update
  end

  def draw
    @player.draw
    @map.draw
  end
end

Window.new.show