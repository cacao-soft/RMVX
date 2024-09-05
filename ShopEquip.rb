# ショップ項目に装備変更追加

class Scene_Shop < Scene_Base
  def create_command_window
    s1 = Vocab::ShopBuy
    s2 = Vocab::ShopSell
    s3 = Vocab::ShopCancel
    s4 = "装備変更"
    @command_window = Window_Command.new(384, [s1, s2, s4, s3], 4, 0, 8)
    @command_window.y = 56
    if $game_temp.shop_purchase_only
      @command_window.draw_item(1, false)
    end
  end
  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      case @command_window.index
      when 0
        Sound.play_decision
        @command_window.active = false
        @dummy_window.visible = false
        @buy_window.active = true
        @buy_window.visible = true
        @buy_window.refresh
        @status_window.visible = true
      when 1
        if $game_temp.shop_purchase_only
          Sound.play_buzzer
        else
          Sound.play_decision
          @command_window.active = false
          @dummy_window.visible = false
          @sell_window.active = true
          @sell_window.visible = true
          @sell_window.refresh
        end
      when 2
        Sound.play_decision
        $scene = Scene_Equip.new
        $scene.from_scene = "shop"
      when 3
        Sound.play_decision
        $scene = Scene_Map.new
      end
    end
  end
end
class Scene_Equip < Scene_Base
  attr_accessor :from_scene
  def return_scene
    if @from_scene == "shop"
      $scene = Scene_Shop.new
    else
      $scene = Scene_Menu.new(2)
    end
  end
  def next_actor
    @actor_index += 1
    @actor_index %= $game_party.members.size
    $scene = Scene_Equip.new(@actor_index, @equip_window.index)
    $scene.from_scene = @from_scene
  end
  def prev_actor
    @actor_index += $game_party.members.size - 1
    @actor_index %= $game_party.members.size
    $scene = Scene_Equip.new(@actor_index, @equip_window.index)
    $scene.from_scene = @from_scene
  end
end