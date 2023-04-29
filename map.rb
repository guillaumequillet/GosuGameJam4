require 'json'

class Map
  def initialize(filename)
    file = File.read("./maps/#{filename}")
    @data = JSON.parse(file)
    @layers = @data['layers']

    # temporairement chargé sans tenir compte des fichiers tileset de tiled
    @tile_size = 16
    @tileset = Gosu::Image.load_tiles('./gfx/tileset.png', @tile_size, @tile_size, retro: true)
    @z = 0

    # on charge les blocks
    @blocks = []
    blocks_data = @layers[1]['objects']
    blocks_data.each do |block|
      x, y, w, h = block['x'], block['y'], block['width'], block['height']
      @blocks.push [x, y, w, h]
    end

    # on charge les blocs de mort
    @death_blocks = []
    death_blocks_data = @layers[2]['objects']
    death_blocks_data.each do |death_block|
      x, y, w, h = death_block['x'], death_block['y'], death_block['width'], death_block['height']
      @death_blocks.push [x, y, w, h]
    end
  end

  def update

  end

  def collision?(x_sprite, y_sprite, w_sprite, h_sprite)
    # les sprites sont dessinés centrés donc on décale le point d'origine
    x2 = x_sprite.floor - w_sprite / 2.0
    y2 = y_sprite.floor - h_sprite / 2.0
    w2 = w_sprite
    h2 = h_sprite

    @blocks.each do |block|
      x, y, w, h = *block
      next if x2 >= x + w # trop à droite
      next if x2 + w2 <= x # trop à gauche
      next if y2 >= y + h # trop bas
      next if y2 + h2 <= y # trop haut
      return true # il y a collision
    end

    # si pas de collision, peut être avec un death block
    @death_blocks.each do |block|
      x, y, w, h = *block
      next if x2 >= x + w # trop à droite
      next if x2 + w2 <= x # trop à gauche
      next if y2 >= y + h # trop bas
      next if y2 + h2 <= y # trop haut
      return :death # il y a collision
    end

    return false # pas de collision
  end

  def draw
    # on va déjà prendre la couche "tiles" pour commencer, considérée en position 0 de @layers
    width = @layers[0]['width']
    height = @layers[0]['height']
    data = @layers[0]['data']

    height.times do |y|
      width.times do |x|
        # tiled compte à partir de 1 les tiles utilisés donc "0" veut dire "pas de tile"
        tile_id = data[y * width + x] - 1
        if tile_id >= 0
          @tileset[tile_id].draw(x * @tile_size, y * @tile_size, @z)
        end
      end
    end
  end
end