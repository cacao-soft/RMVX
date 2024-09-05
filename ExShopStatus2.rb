#=============================================================================
#  [RGSS2] ＜拡張＞ ショップステータス #2 - v1.0.4
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

  デフォルトのショップステータスウィンドウの内容を拡張します。
  選択中のアイテムの性能を表示します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を多く行っております。なるべく上部に配置してください。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
module ExShopStatus
  #--------------------------------------------------------------------------
  # ◇ アイテムの情報を表示する
  #--------------------------------------------------------------------------
  INFO_ITEM = true
  #--------------------------------------------------------------------------
  # ◇ 武器と防具の詳細情報を表示する
  #--------------------------------------------------------------------------
  WA_FOOTER = true
    #--------------------------------------------------------------------------
    # ◇ 命中率と回避率をする
    #--------------------------------------------------------------------------
    HIT_AND_EVA = true
    #--------------------------------------------------------------------------
    # ◇ 付加情報とオプションを表示設定
    #--------------------------------------------------------------------------
    #     true  : 属性・ステートの付加・耐性情報
    #     false : オプション
    #--------------------------------------------------------------------------
    ADD_OR_OPTION = true
  #--------------------------------------------------------------------------
  # ◇ 数値によって色を変更する
  #--------------------------------------------------------------------------
  COLOR_UP_DOWN = true
  #--------------------------------------------------------------------------
  # ◇ テキスト設定
  #--------------------------------------------------------------------------
  TEXT_SET = {
    :hit      => "命中率",
    :eva      => "回避率",
    :element  => ["攻撃属性", "防御属性"],
    :state    => ["付加ステート", "耐性ステート"],
    :option   => "オプション",
    :scope    => "効果範囲",
    :occasion => "使用場所",
    :re_hp    => "HP回復量",
    :re_mp    => "MP回復量",
    :re_state => "治療ステート",
    :re_up    => "能力値の上昇量",
    :damage   => "ダメージ",
    :atk_f    => "打撃関係度",
    :spi_f    => "精神関係度",
    :op_i     => ["物理攻撃", "MPにダメージ", "ダメージを吸収", "防御力無視"],
    :op_w     => ["両手持ち", "ターン内先制", "連続攻撃", "クリティカル頻発"],
    :op_a     => ["クリティカル防止", "消費MP半分", "経験値2倍", "HP自動回復"],
    :a_scope  => ["なし", "敵単体", "敵全体", "敵単体 連続", "敵単体 ランダム",
                  "敵二体 ランダム", "敵三体 ランダム", "味方単体", "味方全体",
                  "味方単体 (戦闘不能) ", "味方全体 (戦闘不能)", "使用者"],
    :a_osn    => ["常時", "バトルのみ", "メニューのみ", "使用不可"],
    :para     => ["なし", "最大HP", "最大MP",
                  "攻撃力", "防御力", "精神力", "敏捷性"],
    :none     => "なし"
  }
  #--------------------------------------------------------------------------
  # ◇ 文字色設定
  #--------------------------------------------------------------------------
  COLOR_SET = {
    "炎" => Color.new(240, 0, 0),
    "雷" => Color.new(240, 220, 64)
  }
end
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_ShopStatus < Window_Base
  #--------------------------------------------------------------------------
  # ● インクルード
  #--------------------------------------------------------------------------
  include CAO::ExShopStatus
  #--------------------------------------------------------------------------
  # ● 装備変更後の能力値の描画色取得
  #--------------------------------------------------------------------------
  def parameter_color(value)
    if COLOR_UP_DOWN  # 数値によって色を変更する
      return [power_down_color, normal_color, power_up_color][(value <=> 0)+1]
    else
      return normal_color
    end
  end
  #--------------------------------------------------------------------------
  # ● 描画色の取得
  #--------------------------------------------------------------------------
  def color_set(text)
    return COLOR_SET.key?(text) ? COLOR_SET[text] : normal_color
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    if @item != nil
      number = $game_party.item_number(@item)
      self.contents.font.color = system_color
      self.contents.draw_text(0, 0, 208, WLH, Vocab::Possession)
      self.contents.font.color = normal_color
      self.contents.draw_text(0, 0, 208, WLH, number, 2)
      draw_parameter
    end
  end
  #--------------------------------------------------------------------------
  # ● パラメータの描画
  #--------------------------------------------------------------------------
  def draw_parameter
    if RPG::Item === @item
      if INFO_ITEM
        draw_item_parameter
        @item.base_damage.zero? ? draw_recovery_item : draw_damage_item
      end
    else
      draw_equip_parameter
      if WA_FOOTER
        ADD_OR_OPTION ? draw_element_and_state(168) : draw_option(168)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● アイテムのパラメータの描画
  #--------------------------------------------------------------------------
  def draw_item_parameter
    self.contents.font.color = system_color
    self.contents.draw_text(0, 24, 100, WLH, TEXT_SET[:scope])
    self.contents.draw_text(0, 48, 100, WLH, TEXT_SET[:occasion])
    self.contents.font.color = normal_color
    t1 = TEXT_SET[:a_scope][@item.scope]
    t2 = TEXT_SET[:a_osn][@item.occasion]
    self.contents.draw_text(108, 24, 100, WLH, t1, 2)
    self.contents.draw_text(108, 48, 100, WLH, t2, 2)
  end
  #--------------------------------------------------------------------------
  # ● 回復アイテムのパラメータの描画
  #--------------------------------------------------------------------------
  def draw_recovery_item
    self.contents.font.color = system_color
    self.contents.draw_text(0, 84, 80, WLH, TEXT_SET[:re_hp])
    self.contents.draw_text(0, 108, 80, WLH, TEXT_SET[:re_mp])
    self.contents.draw_text(0, 144, 208, WLH, TEXT_SET[:re_state])
    self.contents.draw_text(0, 224, 208, WLH, TEXT_SET[:re_up])
    self.contents.font.color = normal_color
    th = "#{@item.hp_recovery_rate}% + #{sprintf("%4d", @item.hp_recovery)}"
    tm = "#{@item.mp_recovery_rate}% + #{sprintf("%4d", @item.mp_recovery)}"
    self.contents.draw_text(88, 84, 120, WLH, th, 2)
    self.contents.draw_text(88, 108, 120, WLH, tm, 2)

    if @item.minus_state_set.empty?
      self.contents.draw_text(26, 168, 200, WLH, TEXT_SET[:none])
    else
      for i in 0...@item.minus_state_set.size
        break if i == 14  # 表示上限
        icon = $data_states[@item.minus_state_set[i]].icon_index
        draw_icon(icon, i % 7 * 26 + 18, i / 7 * 24 + 168)
      end
    end
    self.contents.font.color = normal_color
    t1 = TEXT_SET[:para][@item.parameter_type]
    self.contents.draw_text(24, 248, 100, WLH, t1)
    self.contents.draw_text(104, 248, 80, WLH, @item.parameter_points, 2)
  end
  #--------------------------------------------------------------------------
  # ● 攻撃アイテムのパラメータの描画
  #--------------------------------------------------------------------------
  def draw_damage_item
    self.contents.font.color = system_color
    self.contents.draw_text(0, 84, 80, WLH, TEXT_SET[:damage])
    self.contents.draw_text(0, 108, 100, WLH, TEXT_SET[:atk_f])
    self.contents.draw_text(0, 132, 100, WLH, TEXT_SET[:spi_f])
    self.contents.font.color = normal_color
    damage = sprintf("%1$4d ± %2$3d", @item.base_damage, @item.variance)
    self.contents.draw_text(88, 84, 120, WLH, damage, 2)
    self.contents.draw_text(108, 108, 100, WLH, @item.atk_f, 2)
    self.contents.draw_text(108, 132, 100, WLH, @item.spi_f, 2)
    ADD_OR_OPTION ? draw_element_and_state(168) : draw_option(168)
  end
  #--------------------------------------------------------------------------
  # ● 装備品のパラメータの描画
  #--------------------------------------------------------------------------
  def draw_equip_parameter
    params = [ $data_system.terms.atk, $data_system.terms.def,
               $data_system.terms.spi, $data_system.terms.agi ]
    value = [@item.atk, @item.def, @item.spi, @item.agi]
    for i in 0...4
      self.contents.font.color = system_color
      self.contents.draw_text(0, 36 + WLH * i, 100, WLH, params[i])
      self.contents.font.color = parameter_color(value[i])
      self.contents.draw_text(108, 36 + WLH * i, 100, WLH, value[i], 2)
    end
    draw_hit_and_eva if HIT_AND_EVA
  end
  #--------------------------------------------------------------------------
  # ● ヒット率・回避率の描画
  #--------------------------------------------------------------------------
  def draw_hit_and_eva
    if @item.is_a?(RPG::Weapon)
      text = TEXT_SET[:hit]
      value = @item.hit
    else
      text = TEXT_SET[:eva]
      value = @item.eva
    end
    self.contents.font.color = system_color
    self.contents.draw_text(0, 132, 100, WLH, text)
    self.contents.font.color = parameter_color(value)
    self.contents.draw_text(108, 132, 100, WLH, value, 2)
  end
  #--------------------------------------------------------------------------
  # ● 属性・ステートの描画
  #--------------------------------------------------------------------------
  def draw_element_and_state(y)
    case @item
    when RPG::Item
      item_state = @item.plus_state_set
    when RPG::Weapon
      item_state = @item.state_set
    when RPG::Armor
      item_state = @item.state_set
    end
    self.contents.font.color = system_color
    kind = (RPG::Armor === @item ? 1 : 0)
    self.contents.draw_text(0, y, 200, WLH, TEXT_SET[:element][kind])
    self.contents.draw_text(0, y + WLH * 2, 200, WLH, TEXT_SET[:state][kind])
    # 属性の描画
    if @item.element_set.size == 0
      self.contents.font.color = normal_color
      self.contents.draw_text(26, y + WLH, 200, WLH, TEXT_SET[:none])
    else
      for i in 0...@item.element_set.size
        text = $data_system.elements[@item.element_set[i]]
        self.contents.font.color = color_set(text)
        self.contents.draw_text(26 * i + 18, y + WLH, 24, WLH, text, 1)
      end
    end
    # ステートの描画
    if item_state.size == 0
      self.contents.font.color = normal_color
      self.contents.draw_text(26, y + WLH * 3, 200, WLH, TEXT_SET[:none])
    else
      for i in 0...item_state.size
        icon = $data_states[item_state[i]].icon_index
        draw_icon(icon, 26 * i + 18, y + WLH * 3, 24)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● オプションの描画
  #--------------------------------------------------------------------------
  def draw_option(y)
    option = []
    case @item
    when RPG::Item
      text = TEXT_SET[:op_i]
      option << @item.physical_attack
      option << @item.damage_to_mp
      option << @item.absorb_damage
      option << @item.ignore_defense
    when RPG::Weapon
      text = TEXT_SET[:op_w]
      option << @item.two_handed
      option << @item.fast_attack
      option << @item.dual_attack
      option << @item.critical_bonus
    when RPG::Armor
      text = TEXT_SET[:op_a]
      option << @item.prevent_critical
      option << @item.half_mp_cost
      option << @item.double_exp_gain
      option << @item.auto_hp_recover
    end
    self.contents.font.color = system_color
    self.contents.draw_text(4, y, 200, WLH, TEXT_SET[:option])
    for i in 0...4
      self.contents.font.color = normal_color
      self.contents.font.color.alpha = option[i] ? 255 : 128
      self.contents.draw_text(i%2*104+2, i/2*WLH+y+WLH, 100, WLH, text[i], 1)
    end
  end
end
