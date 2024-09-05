#=============================================================================
#  [RGSS2] タイルの置換 - v1.1.0
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/license/mit
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- 概    要 ----------------------------------------------------------------

  指定座標のタイルを別のタイルに置き換える機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ ! 付きのメソッドの実行を繰り返すと変換情報が溜まります。
  ※ ロードゲームすると、常にマップをセットアップします。

 -- 使用方法 ----------------------------------------------------------------

  ★ 別タイルへ置換
   $game_map.chgt(x, y, w, h, tileset_id, tile_index)
   $game_map.chgt(x, y, tileset_id, tile_index)
   $game_map.chgt(rect, tileset_id, tile_index)
     tileset_id .. "A"から"E"までの文字列
     tile_index .. タイルセットでの位置
   ※ chgt! で変更を保存します。マップをリロードしても元に戻りません。

  ★ 別の位置のタイルへ置換
   $game_map.subt(dx, dy, sx, sy, sw, sh, map_id, strata = [0,1,2])
   $game_map.subt(dx, dy, sx, sy, map_id, strata = [0,1,2])
     dx, dy .. コピー先の位置 (現在のマップ)
     sx, sy .. コピー元の位置
     sw, sh .. コピーするサイズ
     map_id .. コピー元のマップＩＤ
     strata .. コピーする階層の配列 (全部で３層)
   ※ subt! で変更を保存します。マップをリロードしても元に戻りません。

  ★ 変換情報をクリア
   $game_map.conversion_mapdata.clear
   $game_map.conversion_mapdata(map_id).clear
  ※ 引数を省略すると全マップの変換情報を削除します。
  ※ 情報を削除しただけでは、マップの状態は変化しません。

  ★ マップの状態を更新する
   $game_map.reload_mapdata

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Rect
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def to_a
    return self.x, self.y, self.width, self.height
  end
end

class Game_Map
  #--------------------------------------------------------------------------
  # ● タイルＩＤのテーブル
  #--------------------------------------------------------------------------
  TABLE_TILE = Table.new(5, 512, 3)
  16.times do |i|
    8.times do |j|
      index = i * 8 + j
      TABLE_TILE[0, index, 0] = index * 48 + 2048
      TABLE_TILE[0, index + 256, 0] = index + 1536
      if j < 6 && j % 3 != 0
        TABLE_TILE[0, index, 1] = TABLE_TILE[0, index, 0]
        TABLE_TILE[0, index, 0] = TABLE_TILE[0, index - 1, 0]
      end
    end
  end
  32.times do |i|
    8.times do |j|
      index = i * 8 + j
      4.times {|k| TABLE_TILE[k + 1, index, 2] = k * 256 + index }
    end
  end
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_tile_initialize initialize
  def initialize
    _cao_tile_initialize
    @conversion_mapdata = {}      # タイル変換情報
  end
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #--------------------------------------------------------------------------
  alias _cao_tile_setup setup
  def setup(map_id)
    _cao_tile_setup(map_id)
    convert_mapdata
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def convert_mapdata
    return unless @conversion_mapdata[@map_id]
    @conversion_mapdata[@map_id].each do |args|
      if args[0] == :chgt
        chgt(*args[1, 8])
      else
        subt(*args[1, 8])
      end
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def reload_mapdata
    return unless $scene.kind_of?(Scene_Map)
    spriteset = $scene.instance_variable_get(:@spriteset)
    tilemap = spriteset.instance_variable_get(:@tilemap)
    @map.data = load_data(sprintf("Data/Map%03d.rvdata", @map_id)).data
    tilemap.map_data = @map.data
    convert_mapdata
  end
  #--------------------------------------------------------------------------
  # ● タイルの変換情報の取得
  #--------------------------------------------------------------------------
  def conversion_mapdata(map_id = nil)
    if map_id
      @conversion_mapdata[map_id] ||= []
      return @conversion_mapdata[map_id]
    else
      return @conversion_mapdata
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def chgt(*args)
    _chgt(*args)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def chgt!(*args)
    conversion_mapdata(@map_id) << _chgt(*args)
    conversion_mapdata(@map_id).uniq!
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def subt(*args)
    _subt(*args)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def subt!(*args)
    conversion_mapdata(@map_id) << _subt(*args)
    conversion_mapdata(@map_id).uniq!
  end

private
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def _chgt(*args)
    case args.size
    when 3
      x, y, w, h, strata, tile_index = *args[0]
      strata = args[1]
      tile_index = args[2]
    when 4
      x, y, w, h, strata, tile_index = args[0], args[1], 1, 1, args[2], args[3]
    when 6
      x, y, w, h, strata, tile_index = args
    else
      msg = "wrong number of arguments (#{args.size} for 6)"
      raise ArgumentError, msg, caller(2)
    end

    strata = strata.upcase[0] - ?A
    w.times do |i|
      h.times do |j|
        xx = x + i
        yy = y + j
        if strata == 0
          if tile_index < 128
            prev = (@map.data[xx, yy, 0] < 2048) ? 0 : @map.data[xx, yy, 0]
            now = TABLE_TILE[strata, tile_index, 0]
            now += (prev - 2048) % 48 if prev != 0 && now != 0
            @map.data[xx, yy, 0] = now
            prev = (@map.data[xx, yy, 1] < 2048) ? 0 : @map.data[xx, yy, 1]
            now = TABLE_TILE[strata, tile_index, 1]
            now += (prev - 2048) % 48 if prev != 0 && now != 0
            @map.data[xx, yy, 1] = now
          else
            @map.data[xx, yy, 0] = TABLE_TILE[strata, tile_index, 0]
            @map.data[xx, yy, 1] = 0
          end
        else
          @map.data[xx, yy, 2] = TABLE_TILE[strata, tile_index, 2]
        end
      end
    end
    return [:chgt] + args
    # return [:chgt, x, y, w, h, strata, tile_index]
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def _subt(*args)
    case args.size
    when 5
      dx, dy, sx, sy, map_id = args
      sw, sh, strata = 1, 1, [0,1,2]
    when 6
      dx, dy, sx, sy, map_id, strata = args
      sw, sh = 1, 1
    when 7
      dx, dy, sx, sy, sw, sh, map_id = args
      strata = [0,1,2]
    when 8
      dx, dy, sx, sy, sw, sh, map_id, strata = args
    else
      msg = "wrong number of arguments (#{args.size} for 8)"
      raise ArgumentError, msg, caller(2)
    end

    map = load_data(sprintf("Data/Map%03d.rvdata", map_id))
    sw.times do |i|
      sh.times do |j|
        for k in strata
          @map.data[dx + i, dy + j, k] = map.data[sx + i, sy + j, k]
        end
      end
    end
    return [:subt] + args
    # return [:subt, dx, dy, sx, sy, sw, sh, map_id, strata]
  end
end

class Scene_File
  #--------------------------------------------------------------------------
  # ○ セーブデータの読み込み
  #--------------------------------------------------------------------------
  alias _cao_tile_read_save_data read_save_data
  def read_save_data(file)
    _cao_tile_read_save_data(file)
    if $game_system.version_id == $data_system.version_id
      $game_map.setup($game_map.map_id)
      $game_player.center($game_player.x, $game_player.y)
    end
  end
end
