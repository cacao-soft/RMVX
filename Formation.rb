#=============================================================================
#  [RGSS2] 隊列の変更 - v1.0.0
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

  アクターごとに隊列を設定可能にする。
  位置によって通常攻撃を禁止する機能を追加します。
  Window_Base に隊列の位置を表示する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 追加機能は、すべてスクリプトで提供されます。

 -- 使用方法 ----------------------------------------------------------------

  ★ 位置の変更
    Game_Actors#position=(pos)
    pos : -1..クラス設定、0..前衛、1..中衛、2..後衛
    例）$game_actor[1].position = 0

  ★ 通常攻撃不可能な位置の設定
    武器のメモ欄に <位置×> と記入すると、その位置では通常攻撃不可にする。
    複数設定する場合は、改行する。
    例）<前衛×>
    その他に英語を使用した設定が可能。
    Game_Actors::POS_NAME で設定された位置の名称に左右されない。
     <NO_VANGUARD>  : 前衛禁止
     <NO_MIDGUARD>  : 中衛禁止
     <NO_REARGUARD> : 後衛禁止

  ★ 武器の使用判定
    Game_Actors#wield_weapons?
    戻り値 : true..通常攻撃可能、false..通常攻撃不可
    例）$game_actor[1].wield_weapons?

  ★ 位置の名称の取得
    Game_Actors#position_name
    例）$game_actor[1].position_name

  ★ 隊列の描画
    Window_Base#draw_actor_position(actor, x, y, width = 120, align = 0)

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Actor
  # 位置の名称 (ココを変更するとメモ欄の記入文字も変化)
  POS_NAME = ["前衛", "中衛", "後衛"]
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #     actor_id : アクター ID
  #--------------------------------------------------------------------------
  alias _cao_setup_class_pos setup
  def setup(actor_id)
    _cao_setup_class_pos(actor_id)
    @position = -1
  end
  #--------------------------------------------------------------------------
  # ○ 狙われやすさの取得
  #--------------------------------------------------------------------------
  def odds
    return 4 - (@position < 0 ? self.class.position : @position)
  end
  #--------------------------------------------------------------------------
  # ● 隊列の位置の取得
  #--------------------------------------------------------------------------
  def position
    return (@position < 0 ? self.class.position : @position)
  end
  #--------------------------------------------------------------------------
  # ● 隊列の位置の変更
  #     pos : 位置 (-1..クラス設定、0..前衛、1..中衛、2..後衛)
  #--------------------------------------------------------------------------
  def position=(pos)
    @position = pos
  end
  #--------------------------------------------------------------------------
  # ● 隊列の位置の名称を取得
  #--------------------------------------------------------------------------
  def position_name
    return POS_NAME[@position < 0 ? self.class.position : @position]
  end
  #--------------------------------------------------------------------------
  # ● 装備品の使用判定
  #     item : アイテム
  #--------------------------------------------------------------------------
  def wield?(item)
    case self.position
    when 0
      return false if item.note.match(/^<(#{POS_NAME[0]}×|NO_VANGUARD)>/i)
    when 1
      return false if item.note.match(/^<(#{POS_NAME[1]}×|NO_MIDGUARD)>/i)
    when 2
      return false if item.note.match(/^<(#{POS_NAME[2]}×|NO_REARGUARD)>/i)
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● 武器の使用判定
  #--------------------------------------------------------------------------
  def wield_weapons?
    for w in self.weapons
      return false unless self.wield?(w)
    end
    return true
  end
end

class Window_Base < Window
  #--------------------------------------------------------------------------
  # ● ポジションの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 描画先の横幅
  #     align : アラインメント (0..左揃え、1..中央揃え、2..右揃え)
  #--------------------------------------------------------------------------
  def draw_actor_position(actor, x, y, width = 120, align = 0)
    self.contents.draw_text(x, y, width, WLH, actor.position_name, align)
  end
end

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ アクターコマンド選択の開始
  #--------------------------------------------------------------------------
  alias _cao_start_actor_cmd_select_class_pos start_actor_command_selection
  def start_actor_command_selection
    _cao_start_actor_cmd_select_class_pos
    unless @active_battler.wield_weapons?
      @actor_command_window.draw_item(0, false)
    end
  end
  #--------------------------------------------------------------------------
  # ○ アクターコマンド選択の更新
  #--------------------------------------------------------------------------
  alias _cao_update_actor_cmd_select update_actor_command_selection
  def update_actor_command_selection
    if Input.trigger?(Input::C)
      if @actor_command_window.index == 0 && !@active_battler.wield_weapons?
        Sound.play_buzzer
        return
      end
    end
    _cao_update_actor_cmd_select
  end
end
