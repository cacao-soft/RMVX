#=============================================================================
#  [RGSS2] アイテムの合成 - v1.0.8
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/mit-license.php
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- 概    要 ----------------------------------------------------------------

  アイテムの合成機能を追加します。

 -- 使用方法 ----------------------------------------------------------------

  ★ 合成画面の起動
   ⇒ イベントコマンド「ラベル」に"<アイテム精製>"と記述
   § スクリプト：$game_temp.scene_refine = true

  ★ 合成材料の設定
   ⇒ アイテムのメモ欄に">REFINE[種類,番号,個数]"と記述
      種類（I：アイテム W：武器 A：防具）
   例）>REFINE[I,3,2][W,13,1]
   ※ 例のように複数指定できますが、最高３つまでです。
   ※ 個数は最大９９までです。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
  #--------------------------------------------------------------------------
  # ◇ 金額の設定
  #     値（数値） ：購入金額を数値で割る
  #--------------------------------------------------------------------------
    REFINE_GOLD = 3
  #--------------------------------------------------------------------------
  # ◇ 用語の設定
  #--------------------------------------------------------------------------
    # ヘルプに表示する文章
    REFIN_HELP_TEXT_1 = "合成したいアイテムを選択してください。"
    REFIN_HELP_TEXT_2 = "いくつ合成しますか？"
    # 精製費用
    REFIN_PRICE_MES = "合成費用"
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :scene_refine
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_refine initialize
  def initialize
    @scene_refine = false
    _cao_initialize_refine
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_refine command_118
  def command_118
    if /^<アイテム精製>/ =~ @params[0]
      $game_temp.scene_refine = true 
    else
      return _cao_command_118_refine
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ○ ショップの処理
  #--------------------------------------------------------------------------
  def command_302
    if $game_temp.scene_refine
      $game_temp.scene_refine = false
      $game_temp.next_scene = "refine"
    else
      $game_temp.next_scene = "shop"
    end
    $game_temp.shop_goods = [@params]
    $game_temp.shop_purchase_only = @params[2]
    loop do
      @index += 1
      if @list[@index].code == 605
        $game_temp.shop_goods.push(@list[@index].parameters)
      else
        return false
      end
    end
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_refine_update_scene_change update_scene_change
  def update_scene_change
    return if $game_player.moving?    # プレイヤーの移動中？
    if $game_temp.next_scene == "refine"
      $game_temp.next_scene = nil
      $scene = Scene_Refine.new
    else
      _cao_refine_update_scene_change
    end
  end
end

class Window_Base < Window
  REFINE_P = /^>REFINE((\s*\[\s*(I|W|A)\s*,\s*(\d+)\s*,\s*(\d+)\s*\])+)/i
  def match_refine(item, line, dif = 0, num = 1, draw = true)
    y = 28
    if REFINE_P === item.note
      t = $1 ; result = [] ; c = 0
      for i in 1..3
        if /(\s*\[\s*(I|W|A)\s*,\s*(\d+)\s*,\s*(\d+)\s*\]){#{i}}/i === t
          result[c * 3] = $2
          result[c * 3 + 1] = $3
          result[c * 3 + 2] = $4
          c += 1
        end
      end
      if draw
        self.contents.font.color = system_color
        self.contents.draw_text(4, y * line, 230, WLH, "材　料")
        @mindex = 1
        for i in 0...3
          break if result[i * 3] == nil || @mindex > 3
          p1, p2, p3 = result[i*3].upcase, result[i*3+1], result[i*3+2]
          draw_material(p1, p2, p3, line, dif, num)
        end
      else
        return result
      end
    end      
  end
  def draw_material(kind, dis, no, line, dif, num)
    y = 28 * ( @mindex + line )
    no = no.to_i * num
    case kind
    when "I"
      item = $data_items[dis.to_i]
    when "W"
      item = $data_weapons[dis.to_i]
    when "A"
      item = $data_armors[dis.to_i]
    end
    number = $game_party.item_number(item)
    draw_icon(item.icon_index, 14, y, true)
    self.contents.font.color = normal_color
    self.contents.draw_text(38, y, 160 - dif, WLH, item.name)
    self.contents.font.size = 14
    self.contents.draw_text(200 - dif, y + 4, 15, WLH, "×")
    self.contents.font.size = 18
    self.contents.draw_text(216 - dif, y + 2, 18, WLH, "#{no}", 1)
    self.contents.draw_text(236 - dif, y + 2, 36, WLH, "(  )", 1)
    self.contents.font.color = Color.new(240, 60, 60) if no > number
    self.contents.draw_text(236 - dif, y + 2, 36, WLH, "#{number}", 1)
    self.contents.font.size = 20
    @mindex += 1
  end
end

class Window_RefineHelp < Window_Base
  def initialize
    super(0, 0, 544, 96)
  end
  def set_text(t1, t2, align = 0)
    if t1 != @t1 || t2 != @t2 || align != @align
      self.contents.clear
      self.contents.font.color = normal_color
      self.contents.draw_text(4, 0, self.width - 40, WLH, t1, 1)
      self.contents.font.color = system_color
      self.contents.font.size = 14
      self.contents.draw_text(12, 24, self.width - 40, WLH, "説　明")
      self.contents.font.size = 20
      self.contents.font.color = normal_color
      self.contents.draw_text(4, 44, self.width - 40, WLH, t2, align)
      @t1 = t1 ; @t2 = t2 ; @align = align
    end
  end
end

class Window_RefineGold < Window_Base
  def initialize
    super(240, 360, 304, 56)
    refresh
  end
  def refresh
    self.contents.clear
    self.contents.font.color = system_color
    self.contents.draw_text(4, 0, 150, WLH, "所持金")
    draw_currency_value($game_party.gold, 0, 0, 270)
  end
end

class Window_RefineNumber < Window_Base
  def initialize
    super(0, 96, 240, 320)
    @item = nil
    @max = 1
    @price = 0
    @number = 1
  end
  def set(item, max, price)
    @item = item
    @max = max
    @price = price
    @number = 1
    refresh
  end
  def number
    return @number
  end
  def refresh
    y = 28
    self.contents.clear
    draw_item_name(@item, 4, y * 1)
    self.contents.font.color = normal_color
    self.contents.draw_text(138, y * 2, 20, WLH, "×")
    self.contents.draw_text(160, y * 2, 20, WLH, @number, 2)
    self.cursor_rect.set(158, y * 2, 28, WLH)
    draw_currency_value(@price * @number, 14, y * 3, 180)
    match_refine(@item, 5, 64, @number)
  end
  def update
    super
    if self.active
      last_number = @number
      if Input.repeat?(Input::RIGHT) and @number < @max
        @number += 1
      end
      if Input.repeat?(Input::LEFT) and @number > 1
        @number -= 1
      end
      if Input.repeat?(Input::UP) and @number < @max
        @number = [@number + 10, @max].min
      end
      if Input.repeat?(Input::DOWN) and @number > 1
        @number = [@number - 10, 1].max
      end
      if @number != last_number
        Sound.play_cursor
        refresh
      end
    end
  end
end

class Window_Refine < Window_Selectable
  def initialize
    super(0, 96, 240, 320)
    @shop_goods = $game_temp.shop_goods
    refresh
    self.index = 0
  end
  def item
    return @data[self.index]
  end
  def refresh
    @data = []
    for goods_item in @shop_goods
      case goods_item[0]
      when 0
        item = $data_items[goods_item[1]]
      when 1
        item = $data_weapons[goods_item[1]]
      when 2
        item = $data_armors[goods_item[1]]
      end
      @data.push(item) if item != nil
    end
    @item_max = @data.size
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
  def draw_item(index)
    item = @data[index]
    number = $game_party.item_number(item)
    if item != nil
      mate = match_refine(item, 0, 0, 1, false)
      if mate != nil
        for i in 0...mate.size / 3
          n = i * 3
          case mate[n].upcase
          when "I"
            poss = $game_party.item_number($data_items[mate[n + 1].to_i])
          when "W"
            poss = $game_party.item_number($data_weapons[mate[n + 1].to_i])
          when "A"
            poss = $game_party.item_number($data_armors[mate[n + 1].to_i])
          end
          break unless mate_poss = mate[n + 2].to_i <= poss
        end
      end
      reprice = item.price / CAO::REFINE_GOLD <= $game_party.gold
      enabled = (reprice && number < 99 && mate_poss)
      rect = item_rect(index)
      self.contents.clear_rect(rect)
      draw_icon(item.icon_index, rect.x + 2, rect.y, true)
      self.contents.font.color = normal_color
      self.contents.font.color.alpha = enabled ? 255 : 128
      self.contents.draw_text(28, rect.y, 212, WLH, item.name)
    end
  end
  def update_help
    t1 = ""
    t2 = item == nil ? "" : item.description
    @help_window.set_text(t1, t2)
  end
end

class Window_RefineStatus < Window_Base
  def initialize
    super(240, 96, 304, 264)
    @item = nil
    @material = []
    refresh
  end
  def refresh
    ritem = [] ; ritem_no = [] ; @mindex = 0
    y = 30
    self.contents.clear
    if @item != nil
      number = $game_party.item_number(@item)
      self.contents.font.color = system_color
      self.contents.draw_text(4, 8, 264, WLH, Vocab::Possession)
      self.contents.draw_text(4, y + 8, 264, WLH, CAO::REFIN_PRICE_MES)
      self.contents.font.color = normal_color
      self.contents.draw_text(4, 8, 264, WLH, "#{number} 個", 2)
      t2 = "#{@item.price / CAO::REFINE_GOLD} #{Vocab::gold}"
      self.contents.draw_text(4, y + 8, 264, WLH, t2, 2)
      match_refine(@item, 4)
    end
  end
  def item=(item)
    if @item != item
      @item = item
      refresh
    end
  end
end

class Scene_Refine < Scene_Base
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    @help_window = Window_RefineHelp.new
    @gold_window = Window_RefineGold.new
    @ref_window = Window_Refine.new
    @status_window = Window_RefineStatus.new
    @number_window = Window_RefineNumber.new
    @number_window.active = false
    @number_window.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    @help_window.dispose
    @gold_window.dispose
    @ref_window.dispose
    @number_window.dispose
    @status_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    t1 = @ref_window.active ? CAO::REFIN_HELP_TEXT_1 : CAO::REFIN_HELP_TEXT_2
    t2 = @ref_window.item == nil ? "" : @ref_window.item.description
    @help_window.set_text(t1, t2)
    @help_window.update
    @gold_window.update
    @ref_window.update
    @number_window.update
    @status_window.update
    if @ref_window.active
      update_ref_selection
    elsif @number_window.active
      update_number_input
    end
  end
  def update_ref_selection
    @status_window.item = @ref_window.item
    if Input.trigger?(Input::B)
      Sound.play_cancel
      if @ref_window.active
        $scene = Scene_Map.new
      else
        @number_window.active = false
        @number_window.visible = false
        @ref_window.active = true
        @ref_window.visible = true
      end
    end
    if @ref_window.active
      if Input.trigger?(Input::C)
        @item = @ref_window.item
        number = $game_party.item_number(@item)
        mate = @ref_window.match_refine(@item, 0, 0, 1, false)
        mate_poss = [] ; m = [] ; @material = [[],[],[]]
        if mate != nil
          for i in 0...mate.size / 3
            n = i * 3
            case mate[n].upcase
            when "I"
              item = $data_items[mate[n + 1].to_i]
              poss = $game_party.item_number(item)
            when "W"
              item = $data_weapons[mate[n + 1].to_i]
              poss = $game_party.item_number(item)
            when "A"
              item = $data_armors[mate[n + 1].to_i]
              poss = $game_party.item_number(item)
            end
            break unless mate_poss = mate[n + 2].to_i <= poss
            m[i] = poss / mate[n + 2].to_i
            @material[i][0] = item
            @material[i][1] = mate[n + 2].to_i
          end
        end
        patty_gold = @item.price / CAO::REFINE_GOLD > $game_party.gold
        if @item == nil || number == 99 || patty_gold || !mate_poss
          Sound.play_buzzer
        else
          Sound.play_decision
          for i in 0...3
            m[i] = 99 if m[i] == nil
          end
          if @item.price == 0
            max = 99
          else
            max = $game_party.gold / (@item.price / CAO::REFINE_GOLD)
          end
          max = [max, 99 - number, m[0], m[1], m[2]].min
          @ref_window.active = false
          @ref_window.visible = false
          @number_window.set(@item, max, @item.price / CAO::REFINE_GOLD)
          @number_window.active = true
          @number_window.visible = true
        end
      end
    end
  end
  def update_number_input
    if Input.trigger?(Input::B)
      cancel_number_input
    elsif Input.trigger?(Input::C)
      decide_number_input
    end
  end
  def cancel_number_input
    Sound.play_cancel
    @number_window.active = false
    @number_window.visible = false
    @ref_window.active = true
    @ref_window.visible = true
  end
  def decide_number_input
    Sound.play_shop
    @number_window.active = false
    @number_window.visible = false
    $game_party.lose_gold(@item.price/CAO::REFINE_GOLD*@number_window.number)
    $game_party.gain_item(@item, @number_window.number)
    for i in 0...3
      if @material[i][0] != nil
        number = @material[i][1] * @number_window.number
        $game_party.gain_item(@material[i][0], -number)
      end
    end
    @gold_window.refresh
    @ref_window.refresh
    @status_window.refresh
    @ref_window.active = true
    @ref_window.visible = true
  end
end
