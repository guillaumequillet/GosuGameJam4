class Pickup
  attr_reader :type, :x, :y, :reward
  def initialize(type, x, y, tile_size)
    @tile_size = tile_size
    @type, @x, @y = type, x, y
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

  def draw
    @sprite[@frame].draw(@x * @tile_size, @y * @tile_size, 0)
  end
end