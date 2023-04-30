class Player
  attr_reader :x, :y, :state
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
    @running_multiplier = 1
    @running_speed = 1.5
    @gravity_acceleration = 0.4
    @jump_height = -7
    @edge_timer = Gosu.milliseconds
    @edge_forgivness = 80

    @image_xscale = 1

    @state = :moving # states are :moving, :dead

    @right_keys = [Gosu::KB_RIGHT, Gosu::KB_D, Gosu::GP_0_RIGHT, Gosu::GP_0_RIGHT_STICK_X_AXIS]
    @left_keys = [Gosu::KB_LEFT, Gosu::KB_A, Gosu::GP_0_LEFT, Gosu::GP_0_LEFT_STICK_X_AXIS]
    @jump_keys = [Gosu::KB_SPACE, Gosu::GP_0_BUTTON_0]
    @run_keys = [Gosu::KB_LEFT_SHIFT, Gosu::GP_0_BUTTON_2]

    @sounds = {
      jump: Gosu::Sample.new('./sfx/jump_03.wav'),
      pickup: Gosu::Sample.new('./sfx/coin.wav'),
      last_pickup: Gosu::Sample.new('./sfx/vgmenuhighlight.wav'),
      death: Gosu::Sample.new('./sfx/vgdeathsound.wav'),
      exit: Gosu::Sample.new('./sfx/vgmenuselect.wav')
    }

    @sprite = Gosu::Image.load_tiles('./gfx/player.png', 16, 16, retro: true)
    @sprite_id = 0
    @sprite_duration = 150
    @sprite_duration_running = 100
    @sprite_tick = Gosu.milliseconds
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
    return false if @state != :moving

    collision = @window.map.collision?(x, y, w, h)
    case collision
    when :death, :enemy
      @sounds[:death].play
      @state = :dead
      @window.lose_life
      return false
    when :pickup
      if @window.map.pickups.size == 0
        @sounds[:last_pickup].play
      else  
        @sounds[:pickup].play
      end
      return false # pas de collision à gérer
    when :exit
      @sounds[:exit].play
      @window.next_level
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
    @sounds[:jump].play(0.3)
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
      @window.reset
    when :moving
      # le joueur est dans les airs
      if !(on_floor?)
        @y_speed += @gravity_acceleration

        # TODO : changer la frame

        # controler la hauteur du saut
        if @y_speed < -3 && space == 0
          @y_speed = -3
        end

        # code pour sauter (edge forgivness)
        if (can_jump? && jump_keys_ok?)
          jump
        end
      # le joueur est au sol
      else
        @running_multiplier = @run_keys.any?{|key| Gosu.button_down?(key)} ? @running_speed : 1.0

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

        sprite_duration = (@running_multiplier > 1) ? @sprite_duration_running : @sprite_duration

        if Gosu.milliseconds - @sprite_tick >= sprite_duration
          @sprite_id += 1
          @sprite_id = 1 if @sprite_id > 2
          @sprite_tick = Gosu.milliseconds 
        end
      else
        @sprite_id = 0
      end

      # vérifier si gauche ou droite
      acceleration = @acceleration * @running_multiplier
      if (right > 0 or left > 0)
        @x_speed += (right - left) * acceleration
        @x_speed = clamp(@x_speed, -(@max_speed * @running_multiplier), (@max_speed * @running_multiplier))
      else
        apply_friction(acceleration)
      end

      move
    end
  end

  def draw
    @sprite[@sprite_id].draw_rot(@x, @y, @z, 0, 0.5, 0.5, @image_xscale)
  end
end