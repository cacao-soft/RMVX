#=============================================================================
#  [RGSS2] ショップ店員 - v1.0.5
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

  ショップ処理に店員さんのコメントを追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ デフォルトの表示方法は使用できなくなります。
  ※ 全機能を使用するには、Interpreter 108 EX が必要です。

 -- 画像規格 ----------------------------------------------------------------

  ★ コメントウィンドウ
   216 x 156 の画像 "WindowShop" を "Graphics/Pictures" にご用意ください。

  ★ 店員画像
   200 x 200 の画像を "Graphics/Pictures" にご用意ください。

  ★ 装備マーク
   24 x 24 の画像 "EquipShop" を "Graphics/System" にご用意ください。

 -- 使用方法 ----------------------------------------------------------------

  ★ ショップを起動する
   今まで通り、イベントコマンドの「ショップ処理」で行ってください。

  ★ 店員のコメントに定型文を使用する。
   イベントコマンド「ラベル」に"<店員[n]：定型文[m]>"と記述してください。
   m の値は、下記で設定する「COME_LISTS」の配列番号です。

  ★ ショップごとに店員のコメントを設定する
   注釈の１行目に"<店員[n]>"２行目以降にコメントを記述してください。
   n の値は、下記で設定する「CLERK_LISTS」の配列番号です。
   ※ 実行には、Interpreter 108 EX が必要です。
   ※ コメントは、１０文字程度の５行で記述してください。

  ※ ショップ処理の前に店員コメントを設定しなかった場合は、
    コメントと画像それぞれ配列の１番目のものが表示されます。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO_SHOP
  #--------------------------------------------------------------------------
  # ◇ ステータスの増減カラー
  #--------------------------------------------------------------------------
  TEXT_COLOR = [
    Color.new(255, 255, 255),   # 変わらない
    Color.new(60, 210, 100),    # 増える
    Color.new(255, 0, 0)        # 減る
  ]
  #--------------------------------------------------------------------------
  # ◇ 店員コメントの定型文（２次）
  #--------------------------------------------------------------------------
  COME_LISTS = [
    # 基本コメント
    ["", "いらっしゃいませ。", "何になさいますか？"],
    # 定型コメント
    ["１行は１０文字程度で", "５行まで入力可能です。"],
    ["あいうえお", "かきくけこ", "さしすせそ", "たちつてと", "なにぬねの"],
    ["いらっしゃいませ。", "何をお求めですか？", "申し訳ありません。",
    "ハチミツは、我慢できなくて", "食べてしまいました。"]
  ]
  #--------------------------------------------------------------------------
  # ◇ 店員画像リスト（２次）
  #--------------------------------------------------------------------------
  CLERK_LISTS = [
    # 基本画像
    "Clerk",
    # 他
    "Kuma", "People2-4"
  ]
  #--------------------------------------------------------------------------
  # ◇ 用語の設定
  #--------------------------------------------------------------------------
    # ショップステータス
    PARA_TEXTS = %w[ATK DEF SPI AGI]
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Temp
  attr_accessor :shop_come
  attr_accessor :clerk
  alias _cao_initialize_shop initialize
  def initialize
    _cao_initialize_shop
    @shop_come = []
    @clerk = ""
  end
end
class Game_Interpreter
  alias _cao_command_118_clerk command_118
  def command_118
    if /^<店員\[(\d+)\]：定型文\[(\d+)\]>/ =~ @params[0]
      $game_temp.clerk = CAO_SHOP::CLERK_LISTS[$1.to_i]
      $game_temp.shop_come = CAO_SHOP::COME_LISTS[$2.to_i]
      return true
    end
    return _cao_command_118_clerk
  end
if $CAO_EX108I
  alias _cao_command_108_clerk command_108
  def command_108
    if /^<店員\[(\d+)\]>/ =~ @parameters[0]
      $game_temp.clerk = CAO_SHOP::CLERK_LISTS[$1.to_i]
      $game_temp.shop_come = []
      for i in 1...@parameters.size
        $game_temp.shop_come << @parameters[i]
      end
      return true
    end
    for params in @parameters
      if /^<店員\[(\d+)\]：定型文\[(\d+)\]>/ =~ params
        $game_temp.clerk = CAO_SHOP::CLERK_LISTS[$1.to_i]
        $game_temp.shop_come = CAO_SHOP::COME_LISTS[$2.to_i]
        return true
      end
    end
    return _cao_command_108_clerk
  end
end
end
class Window_ShopCommand < Window_Selectable
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, 304, 56, 12)
    @commands = [Vocab::ShopBuy, Vocab::ShopSell, Vocab::ShopCancel]
    @item_max = @commands.size
    @column_max = 3
    refresh
    self.index = 0
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    draw_item(0)
    draw_item(1, !$game_temp.shop_purchase_only)
    draw_item(2)
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index   : 項目番号
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item(index, enabled = true)
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    self.contents.clear_rect(rect)
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = enabled ? 255 : 128
    self.contents.draw_text(rect, @commands[index], 1)
  end
end
class Window_ShopBuy < Window_Selectable
  def initialize(x, y)
    super(x, y, 304, 176)
    @shop_goods = $game_temp.shop_goods
    refresh
    self.index = 0
  end
end
class Window_ShopSell < Window_Item
  def initialize(x, y, width, height)
    super(x, y, width, height)
    @column_max = 1
  end
  def draw_item(index)
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    item = @data[index]
    if item != nil
      number = $game_party.item_number(item)
      enabled = enable?(item)
      rect.width -= 4
      draw_item_name(item, rect.x, rect.y, enabled)
      self.contents.draw_text(rect, item.price / 2, 2)
    end
  end
end
class Window_ShopNumber < Window_Base
  def refresh
    y = 36
    self.contents.clear
    draw_item_name(@item, 0, y)
    self.contents.font.color = normal_color
    self.contents.draw_text(212, y, 20, WLH, "×")
    self.contents.draw_text(248, y, 20, WLH, @number, 2)
    self.cursor_rect.set(244, y, 28, WLH)
    draw_currency_value(@price * @number, 4, y + WLH * 2, 264)
  end
end
class Window_ShopStatus < Window_Base
  def initialize(x, y)
    super(x, y, 304, 128)
    @item = nil
    refresh
  end
  def refresh
    self.contents.clear
    if @item != nil
      for actor in $game_party.members
        draw_actor_parameter_change(actor, 26, WLH * actor.index)
      end
    end
  end
  def draw_actor_parameter_change(actor, x, y)
    return if @item.is_a?(RPG::Item)
    enabled = actor.equippable?(@item)
    alpha = enabled ? 255 : 128
    rect = Rect.new(0, 0, 20, 20)
    rect.x = 96 * (actor.character_index % 4) + 38
    rect.y = 128 * (actor.character_index / 4) + 2
    self.contents.fill_rect(1, y + 1, 22, 22, Color.new(255, 255, 255, alpha))
    bitmap = Cache.character(actor.character_name)
    self.contents.blt(2, y + 2, bitmap, rect, alpha)
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = alpha
    if @item.is_a?(RPG::Weapon)
      item1 = weaker_weapon(actor)
    elsif actor.two_swords_style and @item.kind == 0
      item1 = nil
    else
      item1 = actor.equips[1 + @item.kind]
    end
    if enabled
      if (actor.equips[0] == @item) ||
          (@item.is_a?(RPG::Weapon) && actor.equips[1] == @item) ||
          (!@item.is_a?(RPG::Weapon) && actor.equips[1 + @item.kind] == @item)
        self.contents.blt(26, y, Cache.system("EquipShop"), bitmap.rect)
      end
      change = []
      atk1 = item1 == nil ? 0 : item1.atk
      atk2 = @item == nil ? 0 : @item.atk
      change << atk2 - atk1
      def1 = item1 == nil ? 0 : item1.def
      def2 = @item == nil ? 0 : @item.def
      change << def2 - def1
      spi1 = item1 == nil ? 0 : item1.spi
      spi2 = @item == nil ? 0 : @item.spi
      change << spi2 - spi1
      agi1 = item1 == nil ? 0 : item1.agi
      agi2 = @item == nil ? 0 : @item.agi
      change << agi2 - agi1
      self.contents.font.size = 16
      4.times do |i|
        tx = x + 26 + (55 * i) + 23
        self.contents.font.color = system_color
        self.contents.draw_text(tx - 20, y, 20, WLH, CAO_SHOP::PARA_TEXTS[i])
        self.contents.font.color = CAO_SHOP::TEXT_COLOR[change[i] <=> 0]
        self.contents.draw_text(tx, y, 32, WLH, sprintf("%+d", change[i]), 2)
      end
      self.contents.font.size = 20
    end
  end
end
class Sprite_Clerk
  def initialize
    viewport = Viewport.new(304, 30, 240, 330)
    @clerk_sprite = Sprite.new(viewport)
    @clerk_sprite.bitmap = Bitmap.new(240, 330)
    $game_temp.clerk = CAO_SHOP::CLERK_LISTS[0] if $game_temp.clerk == ""
    bitmap = Cache.picture($game_temp.clerk)
    @clerk_sprite.bitmap.blt(20, 120, bitmap, bitmap.rect)
    bitmap = Cache.picture("WindowShop")
    @clerk_sprite.bitmap.blt(12, 0, bitmap, bitmap.rect)
    @text_sprite = Sprite.new(viewport)
    @text_sprite.bitmap = Bitmap.new(200, 136)
    @text_sprite.x = 28
    @text_sprite.y = 16
  end
  def dispose
    $game_temp.clerk = ""
    @clerk_sprite.dispose
    @text_sprite.dispose
  end
  def draw_text(text)
    if text != @text
      @text_sprite.bitmap.clear
      for i in 0...text.size
        @text_sprite.bitmap.draw_text(0, 24 * i, 200, 24, text[i])
      end
      @text = text
    end
  end
end
class Window_ShopItem < Window_Base
  def initialize(x, y)
    super(x, y, 80, 56)
    @item = nil
    refresh
  end
  def refresh
    self.contents.clear
    if @item != nil
      number = $game_party.item_number(@item)
      self.contents.font.color = normal_color
      self.contents.draw_text(0, 0, 24, WLH, number, 1)
      self.contents.font.color = system_color
      self.contents.draw_text(26, 0, 22, WLH, "個", 2)
    end
  end
  def item=(item)
    if @item != item
      @item = item
      refresh
    end
  end
end
class Scene_Shop < Scene_Base
  def start
    super
    create_menu_background
    @help_window = Window_Help.new
    @help_window.y = 360
    @command_window = Window_ShopCommand.new
    @gold_window = Window_Gold.new(384, 304)
    @dummy_window = Window_Base.new(0, 56, 304, 304)
    @buy_window = Window_ShopBuy.new(0, 56)
    @buy_window.active = false
    @buy_window.visible = false
    @buy_window.help_window = @help_window
    @sell_window = Window_ShopSell.new(0, 56, 304, 304)
    @sell_window.active = false
    @sell_window.visible = false
    @sell_window.help_window = @help_window
    @number_window = Window_ShopNumber.new(0, 56)
    @number_window.active = false
    @number_window.visible = false
    @status_window = Window_ShopStatus.new(0, 232)
    @status_window.visible = false
    @clerk_sprite = Sprite_Clerk.new
    $game_temp.shop_come = CAO_SHOP::COME_LISTS[0] if $game_temp.shop_come==[]
    @clerk_sprite.draw_text($game_temp.shop_come)
    @item_window = Window_ShopItem.new(304, 304)
  end
  alias _cao_terminate_shop terminate
  def terminate
    _cao_terminate_shop
    $game_temp.shop_come = []
    @item_window.dispose
    @clerk_sprite.dispose
  end
  def update_buy_selection
    @status_window.item = @buy_window.item
    @item_window.item = @buy_window.item
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @dummy_window.visible = true
      @buy_window.active = false
      @buy_window.visible = false
      @status_window.visible = false
      @status_window.item = nil
      @item_window.item = nil
      @help_window.set_text("")
      return
    end
    if Input.trigger?(Input::C)
      @item = @buy_window.item
      number = $game_party.item_number(@item)
      if @item == nil or @item.price > $game_party.gold or number == 99
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
  def update_sell_selection
    @item_window.item = @sell_window.item
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @dummy_window.visible = true
      @sell_window.active = false
      @sell_window.visible = false
      @status_window.item = nil
      @item_window.item = nil
      @help_window.set_text("")
    elsif Input.trigger?(Input::C)
      @item = @sell_window.item
      @status_window.item = @item
      if @item == nil or @item.price == 0
        Sound.play_buzzer
      else
        Sound.play_decision
        max = $game_party.item_number(@item)
        @sell_window.active = false
        @sell_window.visible = false
        @number_window.set(@item, max, @item.price / 2)
        @number_window.active = true
        @number_window.visible = true
        @status_window.visible = true
      end
    end
  end
  def decide_number_input
    Sound.play_shop
    @number_window.active = false
    @number_window.visible = false
    case @command_window.index
    when 0
      $game_party.lose_gold(@number_window.number * @item.price)
      $game_party.gain_item(@item, @number_window.number)
      @gold_window.refresh
      @buy_window.refresh
      @status_window.refresh
      @item_window.refresh
      @buy_window.active = true
      @buy_window.visible = true
    when 1
      $game_party.gain_gold(@number_window.number * (@item.price / 2))
      $game_party.lose_item(@item, @number_window.number)
      @gold_window.refresh
      @sell_window.refresh
      @status_window.refresh
      @item_window.refresh
      @sell_window.active = true
      @sell_window.visible = true
      @status_window.visible = false
    end
  end
end
