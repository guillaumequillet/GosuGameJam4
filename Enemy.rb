class Enemy
  attr_reader :x, :y
  def initialize(type, x, y, tile_size)
    @tile_size = tile_size
    @type, @x, @y = type, x, y
    load_sprite
    @frame_time = 1500
    @frame_tick = Gosu.milliseconds
    @sound = Gosu::Sample.new('./sfx/penguin_RIP 02.wav')
  end

  def load_sprite
    @sprite = Gosu::Image.load_tiles("./gfx/enemies/#@type.png", @tile_size, @tile_size, retro: true)
    @frame = 0
  end

  def update(player)
    if Gosu.milliseconds - @frame_tick >= @frame_time
      @frame_tick = Gosu.milliseconds
      @frame = (@frame == 0) ? 1 : 0
      @sound.play(0.5) if @frame == 1
    end
  end

  def draw
    @sprite[@frame].draw(@x * @tile_size, @y * @tile_size, 0)
  end
end