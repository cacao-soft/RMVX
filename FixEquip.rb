#=============================================================================
#  [RGSS2] 装備の固定 - v1.0.0
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

  装備画面で装備解除することのできない部位を設定します。

=end


class Scene_Equip < Scene_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  EQUIP_PERMANENTLY = { # ハッシュ（装備解除不可 = ture）
    # "アクター名" => [武器, 盾, 頭防具, 身体防具, 装飾品],
    "ラルフ" => [true, false, false, true, false],
    "ウルリカ" => [true, false, false, true, false]
  }
  #--------------------------------------------------------------------------
  # ● 装備部位選択の更新
  #--------------------------------------------------------------------------
  def update_equip_selection
    # キャンセル
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene # ひとつ前に戻る
    # Ｗ
    elsif Input.trigger?(Input::R)
      Sound.play_cursor
      next_actor # 次のアクター
    # Ｑ
    elsif Input.trigger?(Input::L)
      Sound.play_cursor
      prev_actor # 前のアクター
    # 決定
    elsif Input.trigger?(Input::C)
      # 装備固定箇所が設定されているアクターで尚且つ
      if EQUIP_PERMANENTLY.key?(@actor.name) &&
        # 選択された箇所が固定されているなら
        EQUIP_PERMANENTLY[@actor.name][@equip_window.index]
        Sound.play_buzzer
        return # 処理を中断して戻る
      end
      # 装備固定が設定されているなら（標準）
      if @actor.fix_equipment
        Sound.play_buzzer
      else # そうでないなら、アイテムの選択に移る
        Sound.play_decision
        @equip_window.active = false
        @item_window.active = true
        @item_window.index = 0
      end
    end
  end
end
