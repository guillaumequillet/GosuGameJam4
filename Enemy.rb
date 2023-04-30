class Enemy
  attr_reader :x, :y
  def initialize(type, x, y, tile_size)
    @tile_size = tile_size
    @type, @x, @y = type, x, y
    load_sprite
  end

  def load_sprite
    @sprite = Gosu::Image.load_tiles("./gfx/enemies/#@type.png", @tile_size, @tile_size, retro: true)
    @frame = 0
  end

  def draw
    @sprite[@frame].draw(@x * @tile_size, @y * @tile_size, 0)
  end
end