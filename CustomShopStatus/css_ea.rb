#
# カスタムショップステータス [EA] (12.05.16)
#
class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ● ページ切り替えの処理が必要か
  #--------------------------------------------------------------------------
  def switch_page?
    return $game_party.members.size > 4
  end
  #--------------------------------------------------------------------------
  # ● 最大ページ数
  #--------------------------------------------------------------------------
  def page_max
    return $game_party.members.size / 4 + 1
  end
  #--------------------------------------------------------------------------
  # ● 装備パラメータの描画
  #--------------------------------------------------------------------------
  def draw_equip_parameter
    draw_possession(0, 0, 24)
    draw_actor_info(64, @last_y)
    draw_actor_parameters(0, @last_y)
  end
  #--------------------------------------------------------------------------
  # ● アクターの情報の描画
  #--------------------------------------------------------------------------
  def draw_actor_info(x, y)
    members[@page * 4, 4].each_with_index do |actor,i|
      draw_actor_icon(actor, x + 36 * i + 6, y)
      draw_equip_icon(actor, x + 36 * i + 6, y)
    end
    @last_y += WLH + 8
  end
  #--------------------------------------------------------------------------
  # ● アクターのパラメータの描画
  #--------------------------------------------------------------------------
  def draw_actor_parameters(x, y)
    dummys = dummy_members
    for symbol in PARAMS
      self.contents.font.color = system_color
      self.contents.draw_text(x, y, 64, WLH, VOCAB_PARAMS[symbol])
      last_size = self.contents.font.size
      self.contents.font.size = 16
      members[@page * 4, 4].each_with_index do |actor,i|
        old_param, new_param = actor_parameter(symbol, actor, dummys[@page * 4 + i])
        draw_actor_parameter_change(x + 36 * i + 64, y, old_param, new_param)
      end
      self.contents.font.size = last_size
      y += WLH
    end
    @last_y += WLH * PARAMS.size + 8
  end
  #--------------------------------------------------------------------------
  # ● アクターの現装備と能力値変化の描画
  #--------------------------------------------------------------------------
  def draw_actor_parameter_change(x, y, old_param, new_param)
    if new_param
      value = new_param - old_param
      change_parameter_color(value)
      text = (value == 0) ? VOCAB_ZERO : sprintf("%+d", value)
    else
      self.contents.font.color = normal_color
      text = VOCAB_NONE
    end
    self.contents.draw_text(x, y, 36, WLH, text, 1)
  end
end
