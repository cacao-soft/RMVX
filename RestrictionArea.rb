#=============================================================================
#  [RGSS2] 行動範囲の設定 - v1.1.0
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

  プレイヤー、イベントの行動範囲をエリアで制限する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ Game_Character#passable? を再定義しています。

 -- 使用方法 ----------------------------------------------------------------

  ★ プレイヤーの行動範囲を設定
   行動可能エリア : $game_player.activity_area = [id]
   進入禁止エリア : $game_player.ropedoff_area = [id]

  ★ イベントの行動範囲を設定
   行動可能エリア : $game_map.events[n].activity_area = [id]
   進入禁止エリア : $game_map.events[n].ropedoff_area = [id]
   ※ スクリプトでの設定は、一時的なものです。通常は、注釈をお使いください。

   注釈に『行動可能エリア：id』
   注釈に『進入禁止エリア：id』
   複数のエリアを設定する場合は、(,)で区切ってください。
   この設定は、ページごとに適用されます。


=end


class Game_Character
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor  :activity_area         # 行動可能エリアIDの配列
  attr_accessor  :ropedoff_area         # 進入禁止エリアIDの配列
  #--------------------------------------------------------------------------
  # ○ 通行可能判定
  #     x : X 座標
  #     y : Y 座標
  #--------------------------------------------------------------------------
  def passable?(x, y)
    x = $game_map.round_x(x)                        # 横方向ループ補正
    y = $game_map.round_y(y)                        # 縦方向ループ補正
    return false unless $game_map.valid?(x, y)      # マップ外？
    return true if @through or debug_through?       # すり抜け ON？
    return false if ropedoff_area?(x, y)            # 禁止エリア？ ★
    return false unless map_passable?(x, y)         # マップが通行不能？
    return false if collide_with_characters?(x, y)  # キャラクターに衝突？
    return false unless activity_area?(x, y)        # 行動エリア？ ★
    return true                                     # 通行可
  end
  #--------------------------------------------------------------------------
  # ● 行動エリア内判定
  #     x : X 座標
  #     y : Y 座標
  #--------------------------------------------------------------------------
  def activity_area?(x, y)
    # 設定されていないなら全エリア行動可能
    return true if @activity_area.nil? || @activity_area.empty?
    for i in @activity_area
      area = $data_areas[i]
      next if area == nil
      next if $game_map.map_id != area.map_id
      next if x < area.rect.x
      next if y < area.rect.y
      next if x >= area.rect.x + area.rect.width
      next if y >= area.rect.y + area.rect.height
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 禁止エリア内判定
  #     x : X 座標
  #     y : Y 座標
  #--------------------------------------------------------------------------
  def ropedoff_area?(x, y)
    return false if @ropedoff_area.nil? || @ropedoff_area.empty?
    for i in @ropedoff_area
      area = $data_areas[i]
      next if area == nil
      next if $game_map.map_id != area.map_id
      next if x < area.rect.x
      next if y < area.rect.y
      next if x >= area.rect.x + area.rect.width
      next if y >= area.rect.y + area.rect.height
      return true
    end
    return false
  end
end

class Game_Event
  #--------------------------------------------------------------------------
  # ○ イベントページのセットアップ
  #--------------------------------------------------------------------------
  alias _cao_setup_restriction_area setup
  def setup(new_page)
    if new_page
      @activity_area = []
      @ropedoff_area = []
      for cmd in new_page.list
        if cmd.code == 108 || cmd.code == 408
          case cmd.parameters[0]
          when /^行動可能エリア：(\d+(?:,\s*\d+)*)/
            @activity_area = $1.split(/,\s*/).collect {|item| item.to_i }
          when /^進入禁止エリア：(\d+(?:,\s*\d+)*)/
            @ropedoff_area = $1.split(/,\s*/).collect {|item| item.to_i }
          end
        end
      end
    end
    _cao_setup_restriction_area(new_page)
  end
end
