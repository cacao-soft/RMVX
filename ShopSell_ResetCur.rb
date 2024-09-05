#=============================================================================
#  [RGSS2] 売却画面でカーソルリセット - v1.0.0
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

  ショップの売却画面になったとき、カーソル位置の記憶をリセットする。
   - 売却画面になったときにカーソルをリセット。（売却時にリセットしない）
   - 売却画面でカーソル位置の記憶を読まない。
   - カーソル位置の記憶をリセットしない。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を多用しております。なるべく上部に導入して下さい。


=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#      このスクリプトには設定項目はありません。そのままお使いください。       #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_ShopSell < Window_Item
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @data = []
    for item in $game_party.items
      next unless include?(item)
      @data.push(item)
    end
    @data.push(nil) if include?(nil)
    @item_max = @data.size
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
end
class Scene_Shop < Scene_Base
  #--------------------------------------------------------------------------
  # ● コマンド選択の更新
  #--------------------------------------------------------------------------
  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      case @command_window.index
      when 0  # 購入する
        Sound.play_decision
        @command_window.active = false
        @dummy_window.visible = false
        @buy_window.active = true
        @buy_window.visible = true
        @buy_window.refresh
        @status_window.visible = true
      when 1  # 売却する
        if $game_temp.shop_purchase_only
          Sound.play_buzzer
        else
          Sound.play_decision
          @command_window.active = false
          @dummy_window.visible = false
          @sell_window.active = true
          @sell_window.visible = true
          @sell_window.index = 0
#~           $game_party.last_item_id = 0    # カーソル記憶をリセット
          @sell_window.refresh
        end
      when 2  # やめる
        Sound.play_decision
        $scene = Scene_Map.new
      end
    end
  end
end
