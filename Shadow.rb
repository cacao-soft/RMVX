#=============================================================================
#  [RGSS2] 自動影機能の回避 - v1.0.2
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/mit-license.php
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- 概    要 ----------------------------------------------------------------

  影が自動で追加されるのを回避します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を行っております。なるべく上の方に設置してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ 影を描画しない
   マップ名の先頭に "$" を記述する。
   もしくは、マップ名に "<%no_shadow>" か "<%無影>" を記述する。

=end


module CAO
module SD
#==============================================================================
# ◆ ユーザー設定
#==============================================================================
  # 影を自動で表示する
  DISPLAY = true

  
#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#
  
  
  $data_mapinfos = load_data("Data/MapInfos.rvdata") if $data_mapinfos.nil?
  def self.map_data
    return Cache.map_data unless CAO::SD::DISPLAY
    name = $data_mapinfos[$game_map.map_id].name
    return Cache.map_data if /(?:^\$|<%(?:no_shadow|無影)>)/ =~ name
    return $game_map.data
  end
end
end

module Cache
  #--------------------------------------------------------------------------
  # ◎ タイルマップの保存
  #--------------------------------------------------------------------------
  def self.map_data
    @map_data = {} if @map_data.nil?
    unless @map_data.include?($game_map.map_id)
      map_data = $game_map.data
      for x in 0...map_data.xsize
        for y in 0...map_data.ysize
          if (4352..8191) === map_data[x, y, 0]
            map_data[x, y, 1] = map_data[x, y, 0]
            map_data[x, y, 0] = 0
          end
        end
      end
      @map_data[$game_map.map_id] = map_data
    end
    return @map_data[$game_map.map_id]
  end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # ○ タイルマップの作成
  #--------------------------------------------------------------------------
  def create_tilemap
    @tilemap = Tilemap.new(@viewport1)
    @tilemap.bitmaps[0] = Cache.system("TileA1")
    @tilemap.bitmaps[1] = Cache.system("TileA2")
    @tilemap.bitmaps[2] = Cache.system("TileA3")
    @tilemap.bitmaps[3] = Cache.system("TileA4")
    @tilemap.bitmaps[4] = Cache.system("TileA5")
    @tilemap.bitmaps[5] = Cache.system("TileB")
    @tilemap.bitmaps[6] = Cache.system("TileC")
    @tilemap.bitmaps[7] = Cache.system("TileD")
    @tilemap.bitmaps[8] = Cache.system("TileE")
    @tilemap.map_data = CAO::SD.map_data
    @tilemap.passages = $game_map.passages
  end
end
