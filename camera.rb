class Camera
  def initialize(window, target = nil)
    @window = window
    @x = 0
    @y = 0
    set_target(target) unless target.nil?
  end

  def set_target(target)
    @target = target
  end

  def update
    if !@target.nil?
      wanted_x = -(@target.x - @window.width / 2)
      @x = lerp(@x, wanted_x, 0.05)

      # lerp vers hauteur du personnage si le perso est au sol
      if @target.on_floor?
        wanted_height = -(@target.y - @window.height / 2)
        @y = lerp(@y, wanted_height, 0.05)
      else
        wanted_height = -(@target.y - @window.height / 2)
        @y = lerp(@y, wanted_height, 0.2)
      end
    end
  end

  def lerp(a, b, t)
    a + (b - a) * t
  end

  def look
    Gosu.translate(@x, @y) do
      yield
    end
  end
end