#=============================================================================
#  [RGSS2] ショップアイテム分類 - v1.0.7
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

  表示するアイテムを種類別に分けます。

 -- 注意事項 ----------------------------------------------------------------

  ※ エイリアスなしの再定義を多用しているため、上の方に導入してください。

 -- 画像規格 ----------------------------------------------------------------

  ★ ショップアイコン
   144 x 24 の画像（ShopIcon）を "Graphics/System" にご用意ください。
   ※ 詳細はサイトの説明をご覧ください。

 -- 使用方法 ----------------------------------------------------------------

  ★ 専門店の設定
   イベントコマンド「スクリプト」で $game_temp.shop_kind = n を実行。
   n には、0 から始まる数値を入れてください。(0:アイテム, 1:武器 ... )
   この設定はショップ処理終了時に解除されます。
  ※ 手動で解除したい場合は、$game_temp.shop_kind = nil としてください。


=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトには設定項目はありません。                   #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#

module CAO
module KSHOP
  # アイテムのアイコン画像
  FILE_ITME_ICON = "ShopIcon"

  # アイテムの表示切替時の効果音
  SE_PAGE = ["Audio/SE/Book", 90, 150]

  # 売却時の数字のアラインメント
  NUM_ALIGN = 2

  # テキストの設定
  TEXT_SELL = "買取価格："
  TEXT_HAVE = "所持数："

  #--------------------------------------------------------------------------
  # ● 売却価格の取得
  #--------------------------------------------------------------------------
  def self.get_sell_price(price)
    return price / 2
  end
  #--------------------------------------------------------------------------
  # ● KGC[装備拡張]の有無
  #--------------------------------------------------------------------------
  def self.in_kgc_equip_ext?
    return Hash === $imported && $imported["EquipExtension"]
  end
  #--------------------------------------------------------------------------
  # ● アイテム＋装備品の総数
  #--------------------------------------------------------------------------
  def self.item_max
    if in_kgc_equip_ext?
      return KGC::EquipExtension::EQUIP_TYPE.uniq.size + 2
    else
      return 6  # アイテム, 武器, 盾, 頭, 身体, 装飾
    end
  end
  #--------------------------------------------------------------------------
  # ● アイテムの表示順の取得
  #--------------------------------------------------------------------------
  def self.item_index(item)
    case item
    when RPG::Item
      index = 0
    when RPG::Weapon
      index = 1
    when RPG::Armor
      if in_kgc_equip_ext?
        index = 2 + KGC::EquipExtension::EQUIP_TYPE.index(item.kind)
      else
        index = 2 + item.kind
      end
    end
    return index
  end
end # module KSHOP
end # module CAO

class Game_Temp
  #--------------------------------------------------------------------------
  # ○ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :shop_kind                # ショップ 商品の種類
end

class Window_ShopCommand < Window_Selectable
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 56, 384, 56)
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

class Window_ShopIcon < Window_Base
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :index                    #
  #--------------------------------------------------------------------------
  # 〇 オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 56, 384, 56)
    @item_max = CAO::KSHOP.item_max
    @index = $game_temp.shop_kind || 0
    @img_icon = Cache.system(CAO::KSHOP::FILE_ITME_ICON)
    refresh
  end
  #--------------------------------------------------------------------------
  # 〇 リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    cw = self.contents.width / @item_max
    for i in 0...@item_max
      x = cw * i + (cw - 24) / 2
      rect = Rect.new(24 * i, 0, 24, 24)
      self.contents.blt(x, 0, @img_icon, rect, (@index == i ? 255 : 128))
    end
  end
  #--------------------------------------------------------------------------
  # 〇 フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    return if $game_temp.shop_kind
    if Input.trigger?(Input::LEFT)
      @index = (@index - 1 + @item_max) % @item_max
    end
    if Input.trigger?(Input::RIGHT)
      @index = (@index + 1) % @item_max
    end
  end
end

class Window_ShopBuy < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :item_index               #
  #--------------------------------------------------------------------------
  # 〇 オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_kshop initialize
  def initialize(x, y)
    @item_index = $game_temp.shop_kind || 0
    _cao_initialize_kshop(x, y)
  end
  #--------------------------------------------------------------------------
  # 〇 アイテムの取得
  #--------------------------------------------------------------------------
  def item
    return @data[@item_index][self.index]
  end
  #--------------------------------------------------------------------------
  # 〇 リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @data = Array.new(CAO::KSHOP.item_max) { [] }
    for goods_item in @shop_goods
      case goods_item[0]
      when 0
        item = $data_items[goods_item[1]]
      when 1
        item = $data_weapons[goods_item[1]]
      when 2
        item = $data_armors[goods_item[1]]
      end
      if item != nil
        @data[CAO::KSHOP.item_index(item)].push(item)
      end
    end
    @item_max = @data[@item_index].size
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # 〇 項目の描画
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[@item_index][index]
    number = $game_party.item_number(item)
    enabled = (item.price <= $game_party.gold and number < 99)
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    draw_item_name(item, rect.x, rect.y, enabled)
    rect.width -= 4
    self.contents.draw_text(rect, item.price, 2)
  end
  #--------------------------------------------------------------------------
  # 〇 ヘルプテキスト更新
  #--------------------------------------------------------------------------
  def update_help
    item = self.item
    @help_window.set_text(item == nil ? "" : item.description)
  end
end

class Window_ShopSell < Window_Item
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :item_index               #
  #--------------------------------------------------------------------------
  # 〇 オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super(x, y, width, height)
    @column_max = 1
    @item_index = $game_temp.shop_kind || 0
  end
  #--------------------------------------------------------------------------
  # 〇 リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @data = []
    for item in $game_party.items
      next unless include?(item)
      @data.push(item)
      if item.is_a?(RPG::Item) and item.id == $game_party.last_item_id
        self.index = @data.size - 1
      end
    end
    @data.push(nil) if include?(nil)
    @item_max = @data.size
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # 〇 項目の描画
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    item = @data[index]
    if item != nil
      number = $game_party.item_number(item)
      enabled = enable?(item)
      draw_item_name(item, rect.x, rect.y, enabled)
      self.contents.font.color = system_color
      self.contents.draw_text(244, rect.y, 95, WLH, CAO::KSHOP::TEXT_SELL)
      self.contents.draw_text(413, rect.y, 75, WLH, CAO::KSHOP::TEXT_HAVE)
      self.contents.font.color = normal_color
      price = CAO::KSHOP.get_sell_price(item.price)
      align = CAO::KSHOP::NUM_ALIGN
      self.contents.draw_text(339, rect.y, 70, WLH, price, align)
      self.contents.draw_text(488, rect.y, 20, WLH, number, align)
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def include?(item)
    return false if item == nil
    return @item_index == CAO::KSHOP.item_index(item)
  end
  #--------------------------------------------------------------------------
  # 〇 アイテム名の描画
  #     item    : アイテム (スキル、武器、防具でも可)
  #     x       : 描画先 X 座標
  #     y       : 描画先 Y 座標
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item_name(item, x, y, enabled = true)
    if item != nil
      draw_icon(item.icon_index, x, y, enabled)
      self.contents.font.color = normal_color
      self.contents.font.color.alpha = enabled ? 255 : 128
      self.contents.draw_text(x + 24, y, 240, WLH, item.name)
    end
  end
end

class Window_ShopNumber < Window_Base
  #--------------------------------------------------------------------------
  # 〇 オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 304, 304)
    @item = nil
    @max = 1
    @price = 0
    @index = 1
    @number = 1
    @digits_max = 2
  end
  #--------------------------------------------------------------------------
  # 〇 アイテム、最大個数、価格の設定
  #--------------------------------------------------------------------------
  def set(item, max, price)
    @item = item
    @max = max
    @price = price
    @number = 1
    @index = 1
    refresh
    update_cursor
  end
  #--------------------------------------------------------------------------
  # 〇 リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    y = 96
    self.contents.clear
    draw_item_name(@item, 0, y)
    self.contents.font.color = normal_color
    self.contents.draw_text(212, y, 20, WLH, "×")
    s = sprintf("%0*d", @digits_max, @number)
    for i in 0...@digits_max
      self.contents.draw_text(240 + i * 14, y, 14, WLH, s[i,1], 1)
    end
    draw_currency_value(@price * @number, 4, y + WLH * 2, 264)
  end
  #--------------------------------------------------------------------------
  # 〇 フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if self.active
      if Input.repeat?(Input::UP) or Input.repeat?(Input::DOWN)
        Sound.play_cursor
        place = 10 ** (@digits_max - 1 - @index)
        n = @number / place % 10
        @number -= n * place
        n = (n + 1) % 10 if Input.repeat?(Input::UP)
        n = (n + 9) % 10 if Input.repeat?(Input::DOWN)
        @number += n * place
        @number = [@number, @max].min
        refresh
      end
      last_index = @index
      if Input.repeat?(Input::RIGHT)
        if @index < @digits_max - 1 or Input.trigger?(Input::RIGHT)
          @index = (@index + 1) % @digits_max
        end
      end
      if Input.repeat?(Input::LEFT)
        if @index > 0 or Input.trigger?(Input::LEFT)
          @index = (@index + @digits_max - 1) % @digits_max
        end
      end
      if @index != last_index
        Sound.play_cursor
      end
      update_cursor
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    self.cursor_rect.set(240 + @index * 14, 96, 14, WLH)
  end
end

class Scene_Shop < Scene_Base
  #--------------------------------------------------------------------------
  # 〇 開始処理
  #--------------------------------------------------------------------------
  alias _cao_start_kshop start
  def start
    _cao_start_kshop
    @icon_window = Window_ShopIcon.new
    @icon_window.active = false
    @icon_window.visible = false
  end
  #--------------------------------------------------------------------------
  # 〇 終了処理
  #--------------------------------------------------------------------------
  alias _cao_terminate_kshop terminate
  def terminate
    _cao_terminate_kshop
    @icon_window.dispose
    $game_temp.shop_kind = nil
  end
  #--------------------------------------------------------------------------
  # 〇 コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_ShopCommand.new
  end
  #--------------------------------------------------------------------------
  # 〇 フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    @help_window.update
    @command_window.update
    @gold_window.update
    @dummy_window.update
    @buy_window.update
    @sell_window.update
    @number_window.update
    @status_window.update
    if @command_window.active
      update_command_selection
    elsif @buy_window.active
      update_buy_selection
      update_item_kind
    elsif @sell_window.active
      update_sell_selection
      update_item_kind
    elsif @number_window.active
      update_number_input
    end
  end
  #--------------------------------------------------------------------------
  # 〇 コマンド選択の更新
  #--------------------------------------------------------------------------
  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      case @command_window.index
      when 0
        Sound.play_decision
        @command_window.active = false
        @command_window.visible = false
        @icon_window.active = true
        @icon_window.visible = true
        @icon_window.refresh
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
          @command_window.visible = false
          @icon_window.active = true
          @icon_window.visible = true
          @icon_window.refresh
          @dummy_window.visible = false
          @sell_window.active = true
          @sell_window.visible = true
          @sell_window.refresh
        end
      when 2
        Sound.play_decision
        $scene = Scene_Map.new
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 表示アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_item_kind
    last_index = @icon_window.index
    @icon_window.update
    if @icon_window.index != last_index
      Audio.se_play(*CAO::KSHOP::SE_PAGE)
      @icon_window.refresh
      @buy_window.index = 0
      @sell_window.index = 0
      @buy_window.item_index = @icon_window.index
      @sell_window.item_index = @icon_window.index
      if @buy_window.active
        @buy_window.refresh
      elsif @sell_window.active
        @sell_window.refresh
      end
    end
  end
  #--------------------------------------------------------------------------
  # 〇 購入アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_buy_selection
    @status_window.item = @buy_window.item
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @command_window.visible = true
      @icon_window.active = false
      @icon_window.visible = false
      @dummy_window.visible = true
      @buy_window.active = false
      @buy_window.visible = false
      @status_window.visible = false
      @status_window.item = nil
      @help_window.set_text("")
    elsif Input.trigger?(Input::C)
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
  #--------------------------------------------------------------------------
  # 〇 売却アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_sell_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @command_window.visible = true
      @icon_window.active = false
      @icon_window.visible = false
      @dummy_window.visible = true
      @sell_window.active = false
      @sell_window.visible = false
      @status_window.item = nil
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
        @number_window.set(@item, max, CAO::KSHOP.get_sell_price(@item.price))
        @number_window.active = true
        @number_window.visible = true
        @status_window.visible = true
      end
    end
  end
end
