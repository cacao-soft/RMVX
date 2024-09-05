#
# カスタムショップステータス [IB] (15.11.18)
#

#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO::ShopStatus
  #--------------------------------------------------------------------------
  # ◇ 効果範囲を表示する
  #--------------------------------------------------------------------------
  DISPLAY_SCOPE = true
  #--------------------------------------------------------------------------
  # ◇ 使用場所を表示する
  #--------------------------------------------------------------------------
  DISPLAY_OCCASION = true
  #--------------------------------------------------------------------------
  # ◇ ステートを右に寄せる
  #--------------------------------------------------------------------------
  DEXTROSINISTRAL_ISM = false   # 治療ステート
  DEXTROSINISTRAL_ISP = false   # 付加ステート
  #--------------------------------------------------------------------------
  # ◇ アイコンの表示数
  #--------------------------------------------------------------------------
  MAX_ELEMENTS_I = 2    # 属性
  MAX_STATES_I   = 7    # ステート
  #--------------------------------------------------------------------------
  # ◇ アイテムの種類ごとの表示内容
  #--------------------------------------------------------------------------
  # (:recovery, :growth, :minus_state, :plus_state, :element, :damage, :space)
  #   アイテムのメモ欄に <SHOP_○○> と記述。(例：<SHOP_RECOVERY>)
  #   記述がない場合は、自動判定(NONE,RECOVERY,GROWTH,ATTACK)します。
  #--------------------------------------------------------------------------
  ITEM_PARAMS = {}
  ITEM_PARAMS["RECOVERY"] = [:recovery, :minus_state]
  ITEM_PARAMS["GROWTH"]   = [:growth]
  ITEM_PARAMS["ATTACK"]   = [:element, :damage, :plus_state]
  ITEM_PARAMS["POWER"]    = [:plus_state]
  #--------------------------------------------------------------------------
  # ◇ 用語設定
  #--------------------------------------------------------------------------
  VOCAB_DAMAGE = "ダメージ"
  VOCAB_ELEMEMNT = "攻撃属性"
  VOCAB_STATE_P = "付加ステート"
  VOCAB_STATE_M = "治療ステート"
  VOCAB_RECOVERY = ["HP回復量", "MP回復量"]
  VOCAB_SCOPE = ["効果範囲",
    "なし", "敵単体", "敵全体" , "敵単体 連続", "敵単体 ランダム",
    "敵二体 ランダム", "敵三体 ランダム", "味方単体", "味方全体",
    "味方単体 (戦闘不能)", "味方全体 (戦闘不能)", "使用者"
  ]
  VOCAB_OCCASION = ["使用場所",
    "常時", "バトルのみ", "メニューのみ","使用不可"
  ]
  VOCAB_GROWTH = ["能力強化",
    "なし", "最大HP", "最大MP", "攻撃力", "防御力", "精神力", "敏捷性"
  ]
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ● アイテムパラメータの描画
  #--------------------------------------------------------------------------
  def draw_item_parameter
    draw_possession(0, 0, 16)
    draw_scope(0, @last_y)
    draw_occasion(0, @last_y)
    draw_item_parameters
  end

  #--------------------------------------------------------------------------
  # ● 効果範囲の描画
  #--------------------------------------------------------------------------
  def draw_scope(x, y)
    return unless DISPLAY_SCOPE
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 100, WLH, VOCAB_SCOPE[0])
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, 208, WLH, VOCAB_SCOPE[@item.scope + 1], 2)
    @last_y += WLH
    @last_y += 16 unless DISPLAY_OCCASION
  end
  #--------------------------------------------------------------------------
  # ● 使用場所の描画
  #--------------------------------------------------------------------------
  def draw_occasion(x, y)
    return unless DISPLAY_OCCASION
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 100, WLH, VOCAB_OCCASION[0])
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, 208, WLH, VOCAB_OCCASION[@item.occasion+1], 2)
    @last_y += WLH + 16
  end

  #--------------------------------------------------------------------------
  # ● 回復アイテムか判定
  #--------------------------------------------------------------------------
  def recovery_item?
    return true if @item.hp_recovery_rate != 0
    return true if @item.hp_recovery != 0
    return true if @item.mp_recovery_rate != 0
    return true if @item.mp_recovery != 0
    return false
  end
  #--------------------------------------------------------------------------
  # ● 成長アイテムか判定
  #--------------------------------------------------------------------------
  def growth_item?
    return @item.parameter_type != 0
  end
  #--------------------------------------------------------------------------
  # ● 攻撃アイテムか判定
  #--------------------------------------------------------------------------
  def attack_item?
    return @item.base_damage != 0
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def item_parameters
    note = @item.note[/^<SHOP_(\w+?)>/, 1]
    return ITEM_PARAMS[note]       if note
    return ITEM_PARAMS["ATTACK"]   if attack_item?
    return ITEM_PARAMS["GROWTH"]   if growth_item?
    return ITEM_PARAMS["RECOVERY"] if recovery_item?
    return ITEM_PARAMS["NONE"]
  end

  #--------------------------------------------------------------------------
  # ● アイテム情報の描画
  #--------------------------------------------------------------------------
  def draw_item_parameters
    last_param = nil
    for param in (item_parameters || [])
      @last_y -= 8 if param == :damage && last_param == :element
      @last_y -= 8 if param == :element && last_param == :damage
      last_param = param
      eval("draw_#{param}")
    end
  end
  #--------------------------------------------------------------------------
  # ● 回復量のテキスト取得
  #--------------------------------------------------------------------------
  def recovery_text(rate, point)
    text = ""
    text << "#{rate}%"            if rate != 0
    text << " + "                 if rate != 0 && point != 0
    text << sprintf("%4d", point) if point != 0
    return text.empty? ? VOCAB_ZERO : text
  end
  #--------------------------------------------------------------------------
  # ● 回復量の描画
  #--------------------------------------------------------------------------
  def draw_recovery
    self.contents.font.color = system_color
    self.contents.draw_text(0, @last_y, 100, WLH, VOCAB_RECOVERY[0])
    self.contents.draw_text(0, @last_y + WLH, 100, WLH, VOCAB_RECOVERY[1])
    self.contents.font.color = normal_color
    self.contents.draw_text(0, @last_y, 208, WLH,
      recovery_text(@item.hp_recovery_rate, @item.hp_recovery), 2)
    self.contents.draw_text(0, @last_y + WLH, 208, WLH,
      recovery_text(@item.mp_recovery_rate, @item.mp_recovery), 2)
    @last_y += WLH * 2 + 8
  end
  #--------------------------------------------------------------------------
  # ● 成長の描画
  #--------------------------------------------------------------------------
  def draw_growth
    self.contents.font.color = system_color
    self.contents.draw_text(0, @last_y, 100, WLH, VOCAB_GROWTH[0])
    self.contents.font.color = normal_color
    self.contents.draw_text(100, @last_y, 108, WLH,
      VOCAB_GROWTH[@item.parameter_type + 1])
    self.contents.draw_text(100, @last_y, 108, WLH,
      "+#{@item.parameter_points}", 2)
    @last_y += WLH + 8
  end
  #--------------------------------------------------------------------------
  # ● ダメージの描画
  #--------------------------------------------------------------------------
  def draw_damage
    self.contents.font.color = system_color
    self.contents.draw_text(0, @last_y, 100, WLH, VOCAB_DAMAGE)
    self.contents.font.color = normal_color
    self.contents.draw_text(100, @last_y, 108, WLH, @item.base_damage, 2)
    @last_y += WLH + 8
  end
  #--------------------------------------------------------------------------
  # ● 属性の描画
  #--------------------------------------------------------------------------
  def draw_element
    elements = @item.element_set & USABLE_ELEMENTS
    if elements.empty?
      param = VOCAB_NOICON
    elsif GROUP_ELEMENTS[elements]
      param = GROUP_ELEMENTS[elements]
    else
      param = $data_system.elements.values_at(*elements)
    end
    draw_additive(param, 0, @last_y, VOCAB_ELEMEMNT, false, false,
      MAX_ELEMENTS_I)
    @last_y += 8
  end
  #--------------------------------------------------------------------------
  # ● 治療ステートの描画
  #--------------------------------------------------------------------------
  def draw_minus_state
    states = @item.minus_state_set & USABLE_STATES
    if states.empty?
      param = VOCAB_NOICON
    elsif GROUP_STATES[states]
      param = GROUP_STATES[states]
    else
      param = $data_states.values_at(*states)
    end
    draw_additive(param, 0, @last_y, VOCAB_STATE_M, true,
      DEXTROSINISTRAL_ISM, MAX_STATES_I)
    @last_y += 8
  end
  #--------------------------------------------------------------------------
  # ● 付加ステートの描画
  #--------------------------------------------------------------------------
  def draw_plus_state
    states = @item.plus_state_set & USABLE_STATES
    if states.empty?
      param = VOCAB_NOICON
    elsif GROUP_STATES[states]
      param = GROUP_STATES[states]
    else
      param = $data_states.values_at(*states)
    end
    draw_additive(param, 0, @last_y, VOCAB_STATE_P, true,
      DEXTROSINISTRAL_ISP, MAX_STATES_I)
    @last_y += 8
  end
  #--------------------------------------------------------------------------
  # ● 改行
  #--------------------------------------------------------------------------
  def draw_space
    @last_y += WLH
  end
end
