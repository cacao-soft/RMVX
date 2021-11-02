#
# カスタムショップステータス [EB] (21.11.02)
#

# 表示タイプ (1-3)
CAO::ShopStatus::EBType = 1

class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ● ページ切り替えの処理が必要か
  #--------------------------------------------------------------------------
  def switch_page?
    return $game_party.members.size > 1
  end
  #--------------------------------------------------------------------------
  # ● 最大ページ数
  #--------------------------------------------------------------------------
  def page_max
    return $game_party.members.size
  end
  #--------------------------------------------------------------------------
  # ● 装備パラメータの描画
  #--------------------------------------------------------------------------
  def draw_equip_parameter
    draw_possession(0, 0, 16)
    draw_actor_info(0, @last_y)
    draw_actor_parameters(0, @last_y)
  end
  #--------------------------------------------------------------------------
  # ● アクター情報の描画
  #--------------------------------------------------------------------------
  def draw_actor_info(x, y)
    actor = members[@page]
    draw_actor_graphic(actor, x + 16, y + 32)
    draw_equip_icon(actor, x, y, 32)
    draw_actor_name(actor, x + 36, y + 8)
    draw_actor_level(actor, x + 144, y + 8)
    @last_y += 32 + 8
  end
  #--------------------------------------------------------------------------
  # ● アクターのパラメータの描画
  #--------------------------------------------------------------------------
  def draw_actor_parameters(x, y)
    actor = members[@page]
    dummy = dummy_members[@page]
    PARAMS.each_with_index do |symbol,i|
      self.contents.font.color = system_color
      self.contents.draw_text(x, y + WLH * i, 80, WLH, VOCAB_PARAMS[symbol])
      old_param, new_param = actor_parameter(symbol, actor, dummy)
      draw_actor_parameter_change(x, y + WLH * i, old_param, new_param)
    end
    @last_y += WLH * PARAMS.size + 8
  end
end

class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ● アクターの現装備と能力値変化の描画
  #--------------------------------------------------------------------------
  case
  when 1
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
  when 2
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
  when 3
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
  else
    def draw_actor_parameter_change(x, y, old_param, new_param)
    end 
  end
end
