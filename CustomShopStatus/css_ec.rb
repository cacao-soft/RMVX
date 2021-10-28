#
# カスタムショップステータス [EC] (15.11.18)
#

#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO::ShopStatus
  #--------------------------------------------------------------------------
  # ◇ アクター情報を表示する (アイコン, 装備可能判定, 装備済み判定)
  #--------------------------------------------------------------------------
  DISPLAY_ACTOR_INFO = true
  #--------------------------------------------------------------------------
  # ◇ 属性・ステートを表示する
  #--------------------------------------------------------------------------
  DISPLAY_ELEMENTS_E = true   # 属性
  DISPLAY_STATES_E   = true   # ステート
  #--------------------------------------------------------------------------
  # ◇ 命中率か回避率の片方のみ表示する
  #--------------------------------------------------------------------------
  HIT_OR_EVA = true
  #--------------------------------------------------------------------------
  # ◇ 属性・ステートを２行で表示する
  #--------------------------------------------------------------------------
  DOUBLE_ELEMENT = true   # 属性
  DOUBLE_STATE   = true   # ステート
  #--------------------------------------------------------------------------
  # ◇ 属性・ステートを右に寄せる
  #--------------------------------------------------------------------------
  DEXTROSINISTRAL_E = false
  #--------------------------------------------------------------------------
  # ◇ アイコンの表示数
  #--------------------------------------------------------------------------
  MAX_ELEMENTS_E = 2    # 属性
  MAX_STATES_E   = 7    # ステート
  #--------------------------------------------------------------------------
  # ◇ 用語設定
  #--------------------------------------------------------------------------
  VOCAB_ELEMENT_W = "攻撃属性"
  VOCAB_ELEMENT_A = "耐性属性"
  VOCAB_STATE_W   = "付加ステート"
  VOCAB_STATE_A   = "無効ステート"
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ● 装備パラメータの描画
  #--------------------------------------------------------------------------
  def draw_equip_parameter
    draw_possession(0, 0, 16)
    draw_actor_info(0, @last_y)
    draw_parameters(0, @last_y)
    draw_add_element(0, @last_y)
    draw_add_state(0, @last_y)
  end
  #--------------------------------------------------------------------------
  # ● アクターの情報の描画
  #--------------------------------------------------------------------------
  def draw_actor_info(x, y)
    return unless DISPLAY_ACTOR_INFO
    max = [4, members.size].max
    cw = self.contents.width / max
    x += (cw - 24) / 2
    members.each_with_index do |actor,i|
      draw_actor_icon(actor, x + cw * i, y)
      draw_equip_icon(actor, x + cw * i, y)
    end
    @last_y += WLH + 8
  end
  #--------------------------------------------------------------------------
  # ● 能力値の描画
  #--------------------------------------------------------------------------
  def draw_parameters(x, y)
    for symbol in PARAMS
      if HIT_OR_EVA
        next if @item.is_a?(RPG::Weapon) && symbol == :eva
        next if @item.is_a?(RPG::Armor)  && symbol == :hit
      end
      self.contents.font.color = system_color
      self.contents.draw_text(x, y, 100, WLH, VOCAB_PARAMS[symbol])
      if @item.respond_to?(symbol)
        value = @item.__send__(symbol)
        change_parameter_color(value)
        text = (!DISPLAY_NODATA && value == 0) ? VOCAB_NONE : value
      else
        self.contents.font.color = normal_color
        text = VOCAB_NONE
      end
      self.contents.draw_text(x + 100, y, 108, WLH, text, 2)
      y += WLH
    end
    @last_y = y + 8
  end
  #--------------------------------------------------------------------------
  # ● 属性の描画
  #--------------------------------------------------------------------------
  def draw_add_element(x, y)
    return unless DISPLAY_ELEMENTS_E
    elements = @item.element_set & USABLE_ELEMENTS
    if elements.empty?
      param = VOCAB_NOICON
    elsif GROUP_ELEMENTS[elements]
      param = GROUP_ELEMENTS[elements]
    else
      param = $data_system.elements.values_at(*elements)
    end
    name = @item.is_a?(RPG::Weapon) ? VOCAB_ELEMENT_W : VOCAB_ELEMENT_A
    draw_additive(param, x, y, name, DOUBLE_ELEMENT,
      DEXTROSINISTRAL_E, MAX_ELEMENTS_E)
  end
  #--------------------------------------------------------------------------
  # ● ステートの描画
  #--------------------------------------------------------------------------
  def draw_add_state(x, y)
    return unless DISPLAY_STATES_E
    states = @item.state_set & USABLE_STATES
    if states.empty?
      param = VOCAB_NOICON
    elsif GROUP_STATES[states]
      param = GROUP_STATES[states]
    else
      param = $data_states.values_at(*states)
    end
    name = @item.is_a?(RPG::Weapon) ? VOCAB_STATE_W : VOCAB_STATE_A
    draw_additive(param, x, y, name, DOUBLE_STATE,
      DEXTROSINISTRAL_E, MAX_STATES_E)
  end
end
