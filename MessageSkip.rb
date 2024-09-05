#=============================================================================
#  [RGSS2] メッセージスキップ - v1.0.2
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

  特定のボタンを押している間メッセージを早送りします。

=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
class Window_Message
  
  # スキップ禁止スイッチの番号
  SKIP_SW_NUM = 14
  
  # スキップするボタン (Ctrlキー)
  SKIP_BUTTON = Input::CTRL
  
  # スキップに掛ける時間
  SKIP_WAIT = 10
  
  # 戦闘中は無効
  DISABLE_IN_BATTLE = true
  
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_Message
  #--------------------------------------------------------------------------
  # ● 早送りフラグの更新
  #--------------------------------------------------------------------------
  def skip?
    return false unless Input.press?(SKIP_BUTTON)
    return false if $game_switches[SKIP_SW_NUM]
    return false if $game_temp.in_battle && DISABLE_IN_BATTLE
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 早送りフラグの更新
  #--------------------------------------------------------------------------
  alias _cao_skip_update_show_fast update_show_fast
  def update_show_fast
    if skip? && @text != nil && !@text.empty?
      @show_fast = true
      update_message while @text != nil
      @wait_count = SKIP_WAIT
    else
      _cao_skip_update_show_fast
    end
  end
  #--------------------------------------------------------------------------
  # ○ 文章送りの入力処理
  #--------------------------------------------------------------------------
  alias _cao_skip_input_pause input_pause
  def input_pause
    if skip?
      self.pause = false
      if @text != nil and not @text.empty?
        new_page if @line_count >= MAX_LINE
      else
        terminate_message
      end
    else
      _cao_skip_input_pause
    end
  end
end
