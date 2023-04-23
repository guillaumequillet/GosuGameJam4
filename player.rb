class Player
  def initialize(window, x = 0, y = 0)
    @window = window 
    @width = 16
    @height = 16
    
    @x = x
    @y = y
    @z = 1
    @max_speed = 2.0
    @x_speed = 0
    @y_speed = 0
    @acceleration = 0.8
    @gravity_acceleration = 0.4
    @jump_height = -7
    @grab_width = 18

    @image_xscale = 1

    @states = [:moving] # sera complété plus tard
    @state = @states[0]
  end

  def sign(value)
    if value < 0
      return -1
    elsif value > 0
      return 1
    else
      return 0
    end
  end

  def clamp(value, min_value, max_value)
    return min_value if value < min_value
    return max_value if value > max_value
    return value
  end

  def apply_friction(amount)
    # si on se déplace
    if (@x_speed != 0)
      if (@x_speed.abs - amount > 0)
        @x_speed -= amount * @image_xscale
      else
        @x_speed = 0
      end
    end
  end

  def move
    # collisions horizontales
    if (@window.collision?(@x + @x_speed, @y, @width, @height))
      while (!@window.collision?(@x + sign(@x_speed), @y, @width, @height))
        @x += sign(@x_speed)
      end
      @x_speed = 0
    end

    @x += @x_speed

    # collisions verticale
    if (@window.collision?(@x, @y + @y_speed, @width, @height))
      while (!@window.collision?(@x, @y + sign(@y_speed), @width, @height))
        @y += sign(@y_speed)
      end
      @y_speed = 0
    end

    @y += @y_speed
  end

  def button_down(id)
    if on_floor? && (id == Gosu::KB_SPACE || id == Gosu::GP_0_BUTTON_0)
      @new_jump = true
    end
  end
  
  def button_up(id)

  end

  def right; return (Gosu.button_down?(Gosu::KB_RIGHT) || Gosu.button_down?(Gosu::GP_0_RIGHT) || Gosu.button_down?(Gosu::GP_0_RIGHT_STICK_X_AXIS)) ? 1 : 0; end
  def left; return (Gosu.button_down?(Gosu::KB_LEFT) || Gosu.button_down?(Gosu::GP_0_LEFT) || Gosu.button_down?(Gosu::GP_0_LEFT_STICK_X_AXIS)) ? 1 : 0; end
  def up; return Gosu.button_down?(Gosu::KB_UP) ? 1 : 0; end
  def down; return Gosu.button_down?(Gosu::KB_DOWN) ? 1 : 0; end
  def space; return (Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::GP_0_BUTTON_0)) ? 1 : 0; end

  def on_floor?
    @window.collision?(@x, @y + 1, @width, @height)
  end

  def update
    case @state
    when :moving
      # vérifier si le perso est au sol, sinon appliquer la gravité
      if !(on_floor?)
        @y_speed += @gravity_acceleration

        # le joueur est dans les airs
        # TODO : changer la frame

        # controler la hauteur du saut
        if (@y_speed < -6 && space == 0)
          @y_speed = -3
        end
      else # le joueur est au sol
        @y_speed = 0

        # code pour sauter
        if (space > 0 && @new_jump)
          @y_speed = @jump_height
          @new_jump = false
        end
      end

      # changer la direction du sprite
      if (@x_speed != 0)
        @image_xscale = sign(@x_speed)
      end

      # vérifier si gauche ou droite
      if (right > 0 or left > 0)
        @x_speed += (right - left) * @acceleration
        @x_speed = clamp(@x_speed, -@max_speed, @max_speed)
      else
        apply_friction(@acceleration)
      end

      move
    end
  end

  def draw
    # @sprite ||= Gosu.render(@width, @height) {Gosu.draw_rect(0, 0, @width, @height, Gosu::Color.new(255, 255, 0 ,255))}
    @sprite ||= Gosu::Image.new('./gfx/player.png', retro: true)
    @sprite.draw_rot(@x, @y, @z, 0, 0.5, 0.5, @image_xscale)
  end
end