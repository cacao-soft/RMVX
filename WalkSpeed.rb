#=============================================================================
#  [RGSS2] 移動速度の変更 - v1.0.0
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/mit-license.php
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

  定数 MOVE_SPEED_LIST の値をお好みで変更してください。
  デフォルトでは、０の設定は使用されません。
  ８倍速の設定は、プレイヤーの速度が４倍速でダッシュを行った際に使用されます。
  ダッシュが許可されているのは、プレイヤーのみで乗り物には適用されていないと思います。
  
  デフォルトでは以下のように設定されています。
    歩行：標準速
    ダッシュ：２倍速 (設定されている歩行速度によって変化します。)
    小型船：標準速
    大型船：２倍速
    飛行船：４倍速

=end


class Game_Character
  # 各速度設定 [0, 1/8, 1/4, 1/2, 標準, x2, x4, x8]
  MOVE_SPEED_LIST = [0, 3, 6, 12, 24, 32, 48, 64]
  #--------------------------------------------------------------------------
  # ○ 移動時の更新
  #--------------------------------------------------------------------------
  def update_move
    # 移動速度から移動距離に変換 (ダッシュ状態なら１つ上の速度に)
    distance = MOVE_SPEED_LIST[@move_speed + (dash? ? 1 : 0)]   
    @real_x = [@real_x - distance, @x * 256].max if @x * 256 < @real_x
    @real_x = [@real_x + distance, @x * 256].min if @x * 256 > @real_x
    @real_y = [@real_y - distance, @y * 256].max if @y * 256 < @real_y
    @real_y = [@real_y + distance, @y * 256].min if @y * 256 > @real_y
    update_bush_depth unless moving?
    if @walk_anime
      @anime_count += 1.5
    elsif @step_anime
      @anime_count += 1
    end
  end
end
