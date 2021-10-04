# マップでキー操作無効

SWID_MOVE = 1    # 移動を無効にするスイッチ番号
SWID_ACTION = 2  # 決定を無効にするスイッチ番号

class Game_Player
  #--------------------------------------------------------------------------
  # ○ 方向ボタン入力による移動処理
  #--------------------------------------------------------------------------
  alias _cao_disabled_move_by_input move_by_input
  def move_by_input
    return if $game_switches[SWID_MOVE]
    _cao_disabled_move_by_input
  end
  #--------------------------------------------------------------------------
  # ○ 決定ボタンによるイベント起動判定
  #--------------------------------------------------------------------------
  alias _cao_disabled_check_action_event check_action_event
  def check_action_event
    return false if $game_switches[SWID_ACTION]
    _cao_disabled_check_action_event
  end
end
