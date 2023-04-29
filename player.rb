class Player
  attr_reader :x, :y
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
    @edge_timer = Gosu.milliseconds
    @edge_forgivness = 80

    @image_xscale = 1

    @state = :moving # states are :moving, :dead

    @right_keys = [Gosu::KB_RIGHT, Gosu::KB_D, Gosu::GP_0_RIGHT, Gosu::GP_0_RIGHT_STICK_X_AXIS]
    @left_keys = [Gosu::KB_LEFT, Gosu::KB_A, Gosu::GP_0_LEFT, Gosu::GP_0_LEFT_STICK_X_AXIS]
    @jump_keys = [Gosu::KB_SPACE, Gosu::GP_0_BUTTON_0]
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

  def collision?(x, y, w, h)
    collision = @window.map.collision?(x, y, w, h)
    if collision == :death
      @state = :dead
    else
      return collision
    end
  end

  def move
    # collisions horizontales
    if (collision?(@x + @x_speed, @y, @width, @height))
      while (!collision?(@x + sign(@x_speed), @y, @width, @height))
        @x += sign(@x_speed)
      end
      @x_speed = 0
    end

    @x += @x_speed

    # collisions verticale
    if (collision?(@x, @y + @y_speed, @width, @height))
      while (!collision?(@x, @y + sign(@y_speed), @width, @height))
        @y += sign(@y_speed)
      end
      @y_speed = 0
    end

    @y += @y_speed
  end

  def jump
    @y_speed = @jump_height
    @new_jump = false
    @edge_timer = Gosu.milliseconds
  end

  def jump_keys_ok?
    space > 0 && @new_jump
  end

  def button_down(id)
    # SAUT pressé
    if @jump_keys.include?(id)
      # si au sol ou plus depuis très peu
      if can_jump?
        @new_jump = true
      end
    end
  end
  
  def button_up(id)

  end

  def right
    return @right_keys.any? {|key| Gosu.button_down?(key)} ? 1 : 0
  end

  def left
    return @left_keys.any? {|key| Gosu.button_down?(key)} ? 1 : 0
  end

  def space
    return @jump_keys.any? {|key| Gosu.button_down?(key)} ? 1 : 0
  end

  def can_jump?
    on_floor? || on_forgivness?
  end

  def on_floor?
    collision?(@x, @y + 1, @width, @height)
  end

  def on_forgivness?
    Gosu.milliseconds - @edge_timer < @edge_forgivness
  end

  def update
    case @state
    when :dead
      @x = -10
      @y = -10
    when :moving
      # le joueur est dans les airs
      if !(on_floor?)
        @y_speed += @gravity_acceleration

        # TODO : changer la frame

        # controler la hauteur du saut
        if (@y_speed < -6 && space == 0)
          @y_speed = -3
        end

        # code pour sauter (edge forgivness)
        if (can_jump? && jump_keys_ok?)
          jump
        end
      # le joueur est au sol
      else
        @y_speed = 0
        @edge_timer = Gosu.milliseconds # on stocke un timer 

        # code pour sauter
        if (jump_keys_ok?)
          jump
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

    @font ||= Gosu::Font.new(16)
    if (!@jump_buffer_timer.nil?)
      @font.draw_text("Jump buffer : #{Gosu.milliseconds - @jump_buffer_timer}", 5, 5, 2)
    end
  end
end