#
# カスタムショップステータス [EB1] (12.05.15)
#

class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ● アクターの現装備と能力値変化の描画
  #--------------------------------------------------------------------------
  def draw_actor_parameter_change(x, y, old_param, new_param)
    self.contents.font.color = normal_color
    self.contents.draw_text(x + 80, y, 48, WLH, old_param, 2)
    self.contents.font.color = system_color
    self.contents.draw_text(x + 128, y, 32, WLH, VOCAB_SEPARATOR, 1)
    if new_param
      change_parameter_color(new_param <=> old_param)
      self.contents.draw_text(x + 160, y, 48, WLH, new_param, 2)
    else
      self.contents.font.color = normal_color
      self.contents.draw_text(x + 160, y, 48, WLH, VOCAB_NONE, 2)
    end
  end
end
