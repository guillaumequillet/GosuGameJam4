class Pickup
  attr_reader :type, :x, :y, :reward
  def initialize(type, x, y, tile_size)
    @tile_size = tile_size
    @type, @x, @y = type, x, y
    @scale_x = 1
    @scale_amount = -0.05
    load_sprite
    set_reward
  end

  def load_sprite
    @sprite = Gosu::Image.load_tiles("./gfx/pickups/#@type.png", @tile_size, @tile_size, retro: true)
    @frame = 0
  end

  def set_reward
    @reward = case @type
    when 'gem' then 10
    end
  end

  def update
    @scale_x += @scale_amount
    
    if @scale_amount < 0 and @scale_x <= 0
      @scale_amount = -@scale_amount
    end

    if @scale_amount > 0 and @scale_x > 1      
      @scale_amount = -@scale_amount
    end
  end

  def draw
    x = @x + 0.5
    y = @y + 0.5
    @sprite[@frame].draw_rot(x * @tile_size, y * @tile_size, 0, 0, 0.5, 0.5, @scale_x, 1)
  end
end