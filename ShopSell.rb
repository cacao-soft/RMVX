#=============================================================================
#  [RGSS2] 売却ショップ - v1.1.0
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

  売却のみ行えるショップ機能を追加します。

 -- 使用方法 ----------------------------------------------------------------

  ★ 売却のみのショップを起動する
   イベントコマンド「ラベル」に "売却ショップ" と記入してください。

  ★ 売却可能な種類を指定する
   イベントコマンド「ラベル」で "売却ショップ (オプション)" 。
   オプション(I:アイテム, W:武器, A:防具)は、複数の指定も可能です。
   例）売却ショップ (IW)     # アイテムと武器のみ売却可能

  ★ 売却可能なアイテムを指定する
   イベントコマンド「ラベル」に "売却のみ" と記入してください。
   その後の「ショップの処理」で指定されたアイテムのみ売却ができます。

  ★ 売却可能なアイテムをキーワードで指定する
   設定されたキーワードを含むアイテムを売却可能にします。
   キーワードは $game_temp.shop_config.include_words = [] に設定します。
   イベントコマンド「ラベル」に "売却ショップ" で起動してください。
   キーワードは、予めアイテムのメモ欄に記入しておいてください。
   ※ キーワードを設定した場合、ラベル命令のオプション(IWA)は無視されます。
   ※ 変数のキーワードは、ショップ起動時に初期化(空)されます。

  ★ ショップで売却可能な種類を指定する
   イベントコマンド「ラベル」に "売却オプション (オプション)" と記入。
   オプション(I:アイテム, W:武器, A:防具)は、複数の指定も可能です。
   その後の「ショップの処理」でショップを起動してください。
   「売却ショップ」との相違点は、購入も可能だという点です。
   例）売却オプション (IW)     # アイテムと武器のみ売却可能


=end


#==============================================================================
# ◆ 設定設定
#==============================================================================
module SellShop
  #--------------------------------------------------------------------------
  # ◇ 価格が０のアイテムは表示しない
  #--------------------------------------------------------------------------
  HIDE_PRICE_ZERO = true
  #--------------------------------------------------------------------------
  # ◇ すべてのキーワードを含むアイテムを表示
  #--------------------------------------------------------------------------
  ALL_KEYWORD = false
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_ShopConfig
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :include_item             # 売却時 アイテムを含める
  attr_accessor :include_weapon           # 売却時 武器を含める
  attr_accessor :include_armor            # 売却時 防具を含める
  attr_accessor :include_words            # 売却時 キーワードのものを含める
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    clear
  end
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  def clear
    @include_item = true
    @include_weapon = true
    @include_armor = true
    @include_words = []
  end
  #--------------------------------------------------------------------------
  # ● アイテムを含めるか判定
  #--------------------------------------------------------------------------
  def include?(item)
    return false if item == nil
    if @include_words.empty?
      case item
      when RPG::Item
        return include_item
      when RPG::Weapon
        return include_weapon
      when RPG::Armor
        return include_armor
      end
    else
      if SellShop::ALL_KEYWORD
        return @include_words.all? {|w| item.note.include?(w) }
      else
        return @include_words.any? {|w| item.note.include?(w) }
      end
    end
    return false
  end
end

class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :shop_sell_only           # ショップ 売却のみフラグ
  attr_reader   :shop_config              # ショップ 詳細設定
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_sellshop_initialize initialize
  def initialize
    _cao_sellshop_initialize
    @shop_sell_only = false
    @shop_config = Game_ShopConfig.new
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_sellshop_command_118 command_118
  def command_118
    case @params[0]
    when /^売却のみ/
      $game_temp.shop_sell_only = true
      return true
    when /^売却ショップ\s*(?:\(([iwa]*)\))?/i
      words = ($1 || "IWA").upcase.split(//)
      $game_temp.shop_config.include_item = words.include?("I")
      $game_temp.shop_config.include_weapon = words.include?("W")
      $game_temp.shop_config.include_armor = words.include?("A")
      $game_temp.next_scene = "shop"
      $game_temp.shop_goods = []
      $game_temp.shop_purchase_only = false
      $game_temp.shop_sell_only = true
      return true
    when /^売却オプション\s*(?:\(([iwa]*)\))?/i
      words = ($1 || "IWA").upcase.split(//)
      $game_temp.shop_config.include_item = words.include?("I")
      $game_temp.shop_config.include_weapon = words.include?("W")
      $game_temp.shop_config.include_armor = words.include?("A")
      return true
    end
    _cao_sellshop_command_118
  end
  #--------------------------------------------------------------------------
  # ○ ショップの処理
  #--------------------------------------------------------------------------
  alias _cao_sellshop_command_302 command_302
  def command_302
    if $game_temp.shop_sell_only
      $game_temp.next_scene = "shop"
      $game_temp.shop_goods = [@params]
      $game_temp.shop_purchase_only = false
      loop do
        @index += 1
        if @list[@index].code == 605          # ショップ 2 行目以降
          $game_temp.shop_goods.push(@list[@index].parameters)
        else
          return false
        end
      end
    end
    _cao_sellshop_command_302
  end
end

class Window_ShopSell
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #     width  : ウィンドウの幅
  #     height : ウィンドウの高さ
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    unless $game_temp.shop_goods.empty?
      @shop_goods = $game_temp.shop_goods.map do |kind,id|
        case kind
        when 0; $data_items[id]
        when 1; $data_weapons[id]
        when 2; $data_armors[id]
        end
      end
    end
    super
  end
  #--------------------------------------------------------------------------
  # ○ アイテムをリストに含めるかどうか
  #     item : アイテム
  #--------------------------------------------------------------------------
  def include?(item)
    return false if item == nil
    return false if SellShop::HIDE_PRICE_ZERO && item.price <= 0
    return false unless $game_temp.shop_config.include?(item)
    return true
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    if $game_temp.shop_sell_only && $game_temp.shop_goods.size != 0
      @data = $game_party.items & @shop_goods
    else
      @data = $game_party.items
    end
    @data = @data.select {|item| include?(item) }
    @item_max = @data.size
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
end

class Scene_Shop
  #--------------------------------------------------------------------------
  # ○ コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_sellshop_create_command_window create_command_window
  def create_command_window
    _cao_sellshop_create_command_window
    if $game_temp.shop_sell_only
      @command_window.draw_item(0, false)
    end
  end
  #--------------------------------------------------------------------------
  # ○ コマンドウィンドウの解放
  #--------------------------------------------------------------------------
  alias _cao_sellshop_dispose_command_window dispose_command_window
  def dispose_command_window
    _cao_sellshop_dispose_command_window
    $game_temp.shop_sell_only = false
    $game_temp.shop_config.clear
  end
  #--------------------------------------------------------------------------
  # ○ コマンド選択の更新
  #--------------------------------------------------------------------------
  alias _cao_sellshop_update_command_selection update_command_selection
  def update_command_selection
    if Input.trigger?(Input::C)
      if @command_window.index == 0 && $game_temp.shop_sell_only
        Sound.play_buzzer
        return
      end
    end
    _cao_sellshop_update_command_selection
  end
end
