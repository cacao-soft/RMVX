#=============================================================================
#  [RGSS2] アイテム使用予約 - v1.0.0
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

  戦闘中に数の足りないアイテムは選択できなくします。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を多用しております。なるべく上部に導入して下さい。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#      このスクリプトには設定項目はありません。そのままお使いください。       #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_BattleAction
  #--------------------------------------------------------------------------
  # ○ 行動が有効か否かの判定
  #    イベントコマンドによる [戦闘行動の強制] ではないとき、ステートの制限
  #    やアイテム切れなどで予定の行動ができなければ false を返す。
  #--------------------------------------------------------------------------
  def valid?
    return false if nothing?                      # 何もしない
    return true if @forcing                       # 行動強制中
    return false unless battler.movable?          # 行動不能
    if skill?                                     # スキル
      return false unless battler.skill_can_use?(skill)
    end
    return true
  end
end
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :active_battler
  #--------------------------------------------------------------------------
  # ○ アイテムの使用可能判定
  #     item : アイテム
  #--------------------------------------------------------------------------
  def item_can_use?(item)
    return false unless item.is_a?(RPG::Item)
    return false if item_number(item) == 0
    if $game_temp.in_battle
      if item.battle_ok?
        item_number = 0   # 使用予定数
        # 自分より前のパーティのアイテム使用予定数を確認する
        for actor in members
          # 自分以降は確認しない
          break if actor == @active_battler
          # 選択中のアイテムと同じものを使用する予定の場合
          if actor.action.kind == 2 && actor.action.item_id == item.id
            # 使用予定数に＋１する
            item_number += 1
          end
        end
        # 所持数より使用予定数が少ないなら使用可能（true）
        return item_number(item) > item_number
      else
        return false
      end
    else
      return item.menu_ok?
    end
  end
end
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ アクターコマンド選択の開始
  #--------------------------------------------------------------------------
  alias _cao_start_actor_command_selection_engage start_actor_command_selection
  def start_actor_command_selection
    $game_party.active_battler = @active_battler
    _cao_start_actor_command_selection_engage
  end
end
