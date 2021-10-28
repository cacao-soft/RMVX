#
# カスタムショップステータス [EB3] (12.05.15)
#
class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ● アクターの現装備と能力値変化の描画
  #--------------------------------------------------------------------------
  def draw_actor_parameter_change(x, y, old_param, new_param)
    if new_param
      value = new_param <=> old_param
      change_parameter_color(value)
      text_power = VOCAB_POWER[value]
      self.contents.draw_text(x + 80, y, 48, WLH, new_param, 2)
      self.contents.draw_text(x + 128, y, 32, WLH, text_power, 1)
      self.contents.font.color = normal_color
      self.contents.draw_text(x + 160, y, 48, WLH, old_param, 2)
    else
      text_power = ""
      self.contents.font.color = normal_color
      self.contents.draw_text(x + 80, y, 48, WLH, VOCAB_NONE, 2)
      self.contents.draw_text(x + 160, y, 48, WLH, VOCAB_NONE, 2)
    end
    if text_power.empty?
      self.contents.font.color = system_color
      self.contents.draw_text(x + 128, y, 32, WLH, VOCAB_SEPARATOR, 1)
    end
  end
end
