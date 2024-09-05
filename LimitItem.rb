#=============================================================================
#  [RGSS2] アイテムの所持制限 - v1.0.0
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

  アイテムの種類毎に所持できる個数を設定します。

 -- 注意事項 ----------------------------------------------------------------

  ※ イベントコマンドで装備を変更する場合は、「持てる？」メソッドで
     所持品に空きがあるかを調べてから変更してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ 所持数の制限に達していないか調べる
   持てる？("識別子ID")
     識別子: I アイテム, W 武器, A 防具
     ID: アイテムの番号
  例）持てる？("I1")


=end


class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :unsuccessful            # 処理の失敗フラグ
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_item initialize
  def initialize
    _cao_initialize_item
    @unsuccessful = false
  end
end

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ◎ 定数
  #--------------------------------------------------------------------------
  MAX_BELONGINGS = 10                     # 合計所持数（種類）
  #--------------------------------------------------------------------------
  # ◎ アイテムの合計所持数取得（装備中のアイテムは含まない）
  #--------------------------------------------------------------------------
  def total_items
    return @items.keys.size + @weapons.keys.size + @armors.keys.size
  end
  #--------------------------------------------------------------------------
  # ○ アイテムの増加 (減少)
  #     item          : アイテム
  #     n             : 個数
  #     include_equip : 装備品も含める
  #--------------------------------------------------------------------------
  def gain_item(item, n, include_equip = false)
    $game_temp.unsuccessful = false
    return if item == nil
    number = item_number(item)
    if n > 0 && MAX_BELONGINGS <= total_items && number == 0
      $game_temp.unsuccessful = true
      Sound.play_buzzer
      return
    end
    case item
    when RPG::Item
      @items[item.id] = [[number + n, 0].max, 99].min
    when RPG::Weapon
      @weapons[item.id] = [[number + n, 0].max, 99].min
    when RPG::Armor
      @armors[item.id] = [[number + n, 0].max, 99].min
    end
    n += number
    if include_equip and n < 0
      for actor in members
        while n < 0 and actor.equips.include?(item)
          actor.discard_equip(item)
          n += 1
        end
      end
    end
  end
end

class Scene_Equip < Scene_Base
  #--------------------------------------------------------------------------
  # ○ アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_item_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @equip_window.active = true
      @item_window.active = false
      @item_window.index = -1
    elsif Input.trigger?(Input::C)
      p1 = Game_Party::MAX_BELONGINGS <= $game_party.total_items
      p2 = !$game_party.has_item?(@item_window.item)
      if (p1 && p2) || (@equip_window.item != nil && p1)
        Sound.play_buzzer
      else
        Sound.play_equip
        @actor.change_equip(@equip_window.index, @item_window.item)
        @equip_window.active = true
        @item_window.active = false
        @item_window.index = -1
        @equip_window.refresh
        for item_window in @item_windows
          item_window.refresh
        end
      end
    end
  end
end

class Window_ShopBuy < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    number = $game_party.item_number(item)
    p1 = (item.price <= $game_party.gold and number < 99)
    p2 = Game_Party::MAX_BELONGINGS <= $game_party.total_items
    p3 = !$game_party.has_item?(@item_window.item)
    enabled = p1 && (p2 || p3)
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    draw_item_name(item, rect.x, rect.y, enabled)
    rect.width -= 4
    self.contents.draw_text(rect, item.price, 2)
  end
end

class Scene_Shop < Scene_Base
  #--------------------------------------------------------------------------
  # ● 購入アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_buy_selection
    @status_window.item = @buy_window.item
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @dummy_window.visible = true
      @buy_window.active = false
      @buy_window.visible = false
      @status_window.visible = false
      @status_window.item = nil
      @help_window.set_text("")
      return
    end
    if Input.trigger?(Input::C)
      @item = @buy_window.item
      number = $game_party.item_number(@item)
      p1 = (@item == nil or @item.price > $game_party.gold or number == 99)
      p2 = Game_Party::MAX_BELONGINGS <= $game_party.total_items
      p3 = !$game_party.has_item?(@item_window.item)
      if p1 && (p2 || p3)
        Sound.play_buzzer
      else
        Sound.play_decision
        max = @item.price == 0 ? 99 : $game_party.gold / @item.price
        max = [max, 99 - number].min
        @buy_window.active = false
        @buy_window.visible = false
        @number_window.set(@item, max, @item.price)
        @number_window.active = true
        @number_window.visible = true
      end
    end
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ◎ 所持品を追加できるか
  #--------------------------------------------------------------------------
  def 持てる？(item = nil)
    if Game_Party::MAX_BELONGINGS > $game_party.total_items
      return true
    elsif /^(I|W|A)(\d+)$/i =~ item
      case $1.upcase
      when "I"
        item = $data_items[$2.to_i]
      when "W"
        item = $data_weapons[$2.to_i]
      when "A"
        item = $data_armors[$2.to_i]
      end
      return $game_party.has_item?(item)
    end
    return false
  end
end
