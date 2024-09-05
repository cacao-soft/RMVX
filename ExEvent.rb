#=============================================================================
#  [RGSS2] ＜拡張＞ ＥＶ出現条件 - v0.1.0
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

  注釈を使用してイベントの出現条件を拡張します。

 -- 使用方法 ----------------------------------------------------------------

  ★ 出現条件の設定
   イベントコマンド「注釈」の１行目に <出現条件> と入力してください。
  ※ このコマンドは、必ずページの先頭で設定してください。
  ※ 続けて注釈を設定すると、出現条件の設定の続きと解釈されます。

  ★ 組み合わせ
   スイッチ[番号] op 真偽値
   スイッチ[番号] op スイッチ[番号]
   変数[番号] op 数値
   変数[番号] op 変数[番号]
   EVAL(スクリプト)
  ※ 演算子(op)には、== != <= < > => の６種類が使用できます。

  ★ 設定例
   スイッチ[1] == ON
   変数[3] == 123
   EVAL($game_variables[6] == "あいうえお")

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Event
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  CP_OPERATOR = / *(==|!=|<=|<|>|=>|&&|\|\|) */
  CP_TRUE     = /真|TRUE|ON|有/
  CP_FALSE    = /偽|FALSE|OFF|無/

  CP_SSWITCHE = /(?:SS|セルフスイッチ)\[([ABCD])\]/i
  CP_SWITCHE  = /(?:S|スイッチ)\[(\d+)\]/i
  CP_VARIABLE = /(?:V|変数)\[(\d+)\]/i
  CP_GOLD     = /お金|ゴールド/i
  CP_ITEM     = /アイテム数\[(\d+)\]/i
  CP_WEAPON   = /武器数\[(\d+)\]/i
  CP_ARMOR    = /防具数\[(\d+)\]/i
  CP_ITEM2    = /アイテム\[(\d+)\]/i
  CP_WEAPON2  = /武器\[(\d+)\]/i
  CP_ARMOR2   = /防具\[(\d+)\]/i
  CP_ACTOR    = /(?:A|アクター)\[(\d+)\]:([^ ]+)/i
  CP_PARTY    = /(?:P|パーティ)\[(\d+)\]:([^ ]+)/i
  CP_VEHICLE  = /移動タイプ|乗り物タイプ/i
  CP_VEHICLE2 = /(徒歩|小型船|大型船|飛行船)/i
  CP_TIME     = /時間\[(\d+), *(\d+), *(\d+)\]/
  CP_TIMER    = /タイマー動作/i
  CP_TIMER2   = /タイマー/i

  REGEXP_EVAL = /^E(?:VAL)?\((.+?)\)$/i
  #--------------------------------------------------------------------------
  # ● 特殊文字の変換
  #--------------------------------------------------------------------------
  def convert_special_characters(s)
    s.strip!
    s.gsub!(CP_TRUE)     { true }
    s.gsub!(CP_FALSE)    { false }
    s.gsub!(CP_SSWITCHE) { $game_self_switches[[@map_id, @event.id, $1]] }
    s.gsub!(CP_SWITCHE)  { $game_switches[$1.to_i] }
    s.gsub!(CP_VARIABLE) { $game_variables[$1.to_i] }
    s.gsub!(CP_GOLD)     { $game_party.gold }
    s.gsub!(CP_ITEM)     { $game_party.item_number($data_items[$1.to_i]) }
    s.gsub!(CP_WEAPON)   { $game_party.item_number($data_weapons[$1.to_i]) }
    s.gsub!(CP_ARMOR)    { $game_party.item_number($data_armors[$1.to_i]) }
    s.gsub!(CP_ITEM2)    { $game_party.has_item?($data_items[$1.to_i], true) }
    s.gsub!(CP_WEAPON2)  { $game_party.has_item?($data_weapons[$1.to_i], true) }
    s.gsub!(CP_ARMOR2)   { $game_party.has_item?($data_armors[$1.to_i], true) }
    s.gsub!(CP_ACTOR)    { $game_actors[$1.to_i].__send__($2) }
    s.gsub!(CP_PARTY)    { $game_party.members[$1.to_i + 1].__send__($2) }
    s.gsub!(CP_VEHICLE)  { $game_player.vehicle_type }
    s.gsub!(CP_VEHICLE2) { %w(徒歩 小型船 大型船 飛行船).index($1) - 1 }
    s.gsub!(CP_TIME)     { $1.to_i * 3600 + $2.to_i * 60 + $3.to_i }
    s.gsub!(CP_TIMER)    { $game_system.timer_working }
    s.gsub!(CP_TIMER2)   { $game_system.timer / Graphics.frame_rate }
    return s
  end
  #--------------------------------------------------------------------------
  # ● イベントページの条件合致判定 (注釈)
  #--------------------------------------------------------------------------
  def condition_note_met?(param)
    return false if param[/^<条件終了>/]
    return eval($1) if param[REGEXP_EVAL]
    params = param.split(CP_OPERATOR)
    params.each {|s| convert_special_characters(s) }
    return eval(params.to_s)
  rescue
    p $!, param, params
    return false
  end
  #--------------------------------------------------------------------------
  # ○ イベントページの条件合致判定
  #--------------------------------------------------------------------------
  alias _cao_condition_conditions_met? conditions_met?
  def conditions_met?(page)
    l = page.list
    if l.first.code == 108 && l.first.parameters.first[/^<出現条件>/]
      l.each_with_index do |command,i|
        next if i == 0
        break if command.code != 108 && command.code != 408
        next if condition_note_met?(l[i].parameters[0])
        return false
      end
    end
    return _cao_condition_conditions_met?(page)
  end
end
