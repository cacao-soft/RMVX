#
# カスタムショップステータス [EB2] (12.05.15)
#
class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ● アクターの現装備と能力値変化の描画
  #--------------------------------------------------------------------------
  def draw_actor_parameter_change(x, y, old_param, new_param)
    self.contents.font.color = normal_color
    self.contents.draw_text(x + 80, y, 40, WLH, old_param, 2)
    self.contents.font.color = system_color
    self.contents.draw_text(x + 120, y, 24, WLH, VOCAB_SEPARATOR, 1)
    if new_param
      value = new_param <=> old_param
      change_parameter_color(value)
      text_power = VOCAB_POWER[value]
      self.contents.draw_text(x + 144, y, 40, WLH, new_param, 2)
      self.contents.draw_text(x + 184, y, 24, WLH, text_power, 1)
    else
      self.contents.font.color = normal_color
      self.contents.draw_text(x + 144, y, 40, WLH, VOCAB_NONE, 2)
    end
  end
end
