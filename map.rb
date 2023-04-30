require 'json'

class Map
  attr_reader :start_x, :start_y, :pickups
  def initialize(window, filename)
    @window = window
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

    # on charge les ennemis
    @enemies = []
    enemies_data = @layers[3]['objects']
    enemies_data.each do |enemy|
      if (defined?(enemy['properties'][0]['value']))
        type = enemy['properties'][0]['value']
        x = (enemy['x'].to_i / @tile_size).floor
        y = (enemy['y'].to_i / @tile_size).floor
        @enemies.push Enemy.new(type, x, y, @tile_size)
      end
    end

    # on charge les pickups
    @pickups = []
    pickups_data = @layers[4]['objects']
    pickups_data.each do |pickup|
      if (defined?(pickup['properties'][0]['value']))
        type = pickup['properties'][0]['value']
        x = (pickup['x'].to_i / @tile_size).floor
        y = (pickup['y'].to_i / @tile_size).floor

        if (type == 'start')
          @start_x = (x + 0.5) * @tile_size
          @start_y = (y + 0.5) * @tile_size
        elsif (type == 'exit')
          @exit_x = x * @tile_size
          @exit_y = y * @tile_size
        else
          @pickups.push Pickup.new(type, x, y, @tile_size)
        end
      end
    end

    @total_pickups = @pickups.size
    @font = @window.font
  end

  def update
    @pickups.each {|pickup| pickup.update}
    @enemies.each {|enemy| enemy.update(@window.player)}
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

    # si pas de collision, peut être avec un ennemi
    @enemies.each do |enemy|
      x, y, w, h = enemy.x * @tile_size + 4, enemy.y * @tile_size + 4, @tile_size - 8, @tile_size - 8
      next if x2 >= x + w # trop à droite
      next if x2 + w2 <= x # trop à gauche
      next if y2 >= y + h # trop bas
      next if y2 + h2 <= y # trop haut
      return :enemy # il y a collision
    end

    # si pas de collision, peut être avec un Pickup
    @pickups.each_with_index do |pickup, i|
      x, y, w, h = pickup.x * @tile_size, pickup.y * @tile_size, @tile_size, @tile_size
      next if x2 >= x + w # trop à droite
      next if x2 + w2 <= x # trop à gauche
      next if y2 >= y + h # trop bas
      next if y2 + h2 <= y # trop haut

      # on donne le bonus au joueur et on supprime
      @window.validate_pickup(pickup)
      @pickups.delete_at(i)

      if pickup.type == 'exit'
        return :exit
      else
        return :pickup # il y a collision
      end
    end

    # sortie (si tout est ramassé) ?
    if (@pickups.size == 0)
      x, y, w, h = @exit_x, @exit_y, @tile_size, @tile_size
      return false if x2 >= x + w # trop à droite
      return false if x2 + w2 <= x # trop à gauche
      return false if y2 >= y + h # trop bas
      return false if y2 + h2 <= y # trop haut
      return :exit # il y a collision
    end

    return false # pas de collision
  end

  def draw_exit
    @flags ||= Gosu::Image.load_tiles('./gfx/flags.png', @tile_size, @tile_size, retro: true)
    frame = (@pickups.size == 0) ? 1 : 0
    @flags[frame].draw(@exit_x, @exit_y, 0)
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

    # dessin des enemis
    @enemies.each {|enemy| enemy.draw}

    # dessin des pickups
    @pickups.each {|pickup| pickup.draw}

    # dessin sortie
    draw_exit
  end
  
  def draw_background
    @background_color ||= Gosu::Color.new(255, 29, 43, 83)
    Gosu.draw_rect(0, 0, @window.width, @window.height, @background_color)
  end

  def draw_hud
    # HUD
    @coin ||= Gosu::Image.new('./gfx/pickups/gem.png', retro: true)
    @coin.draw(10, @window.height - 19, 1)
    collected = @total_pickups - @pickups.size
    @font.draw_text("#{collected}/#@total_pickups", 26, @window.height - @font.height, 2)
    @font.draw_text("#{collected}/#@total_pickups", 26 + 1, @window.height - @font.height + 1, 1, 1, 1, Gosu::Color::BLACK)
  end
end