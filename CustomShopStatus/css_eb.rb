#
# カスタムショップステータス [EB] (12.05.16)
#
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
