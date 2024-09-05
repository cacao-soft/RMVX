#=============================================================================
#  [RGSS2] アイテム合成 - v2.0.1
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

  ★ 合成画面を表示する (簡易)
   イベントコマンド「ラベル」に <アイテム合成> と記入し、
   イベントコマンド「ショップの処理」でアイテムを設定する。

  ★ 合成画面を表示する (分割)
   イベントコマンド「ラベル」に <合成準備> と記入し、
   イベントコマンド「ショップの処理」で、アイテムを設定し、
   イベントコマンド「ラベル」に <合成開始> と記入し合成画面を開く。
   イベントコマンド「ラベル」に <合成中止> と記入すれば、準備が中止される。
  ※ アイテムの設定は、複数に分けても構わない。

  ★ 合成素材の設定
   アイテムのメモ欄に @CONFLATE[種類ＩＤ:個数] と記入してください。
     種類 .. I:アイテム, W:武器, A:防具
     ＩＤ .. データベース上でのアイテムの番号
     個数 .. 左辺のアイテムの必要な数
   [...] には、, で区切ることで複数の設定ができます。
   最初の要素に数値のみの設定を行うと、合成に必要な費用を設定できます。
   費用の設定を省略した場合、価格に CUT_RATE をかけた値が使用されます。
  例) @CONFLATE[100, I1:3, I13:1, A17:1]
  ※ @CONFLATE は、複数に分けて設定することも可能です。

=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module Conflate
  #--------------------------------------------------------------------------
  # ◇ 値引率
  #--------------------------------------------------------------------------
  CUT_RATE = 0.3
  
  #--------------------------------------------------------------------------
  # ◇ ショップステータスを表示する
  #--------------------------------------------------------------------------
  USE_SHOP_STATUS = true
  
  #--------------------------------------------------------------------------
  # ◇ 背景画像
  #--------------------------------------------------------------------------
  #     ファイル名を設定します。使用しない場合は nil としてください。
  #--------------------------------------------------------------------------
  FILE_SCENEBACK  = nil#"BackConflate"
  FILE_STATUSBACK = nil#"BackConflateStatus"
  
  #--------------------------------------------------------------------------
  # ◇ 用語設定
  #--------------------------------------------------------------------------
  VOCAB = {}    # <= 変更しないでください。
  VOCAB[:gold]     = "所持金"
  VOCAB[:material] = "合成素材"
  VOCAB[:have]     = "所持数"
  VOCAB[:have_u]   = "個"
  VOCAB[:cost]     = "合成費用"
end
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::Conflate
  REGEXP_GOLD = /^@CONFLATE\[(\d+)(?:,|\])/i
  REGEXP_KEYS = /^@CONFLATE\[(.+?)\]/i
  REGEXP_GOODS = /([IWA])(\d+):(\d+)/i
end

class RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● 合成費用の取得
  #--------------------------------------------------------------------------
  def conflate_price
    return self.note.gsub(" ", "")[CAO::Conflate::REGEXP_GOLD, 1]
  end
  #--------------------------------------------------------------------------
  # ● 合成に必要なアイテムの取得
  #--------------------------------------------------------------------------
  def conflate_items
    self.note.gsub(" ", "").scan(CAO::Conflate::REGEXP_KEYS).flatten.
    join(",").scan(CAO::Conflate::REGEXP_GOODS).map do |key|
      case key.first.upcase
      when "I"; [$data_items[key[1].to_i], key[2].to_i]
      when "W"; [$data_weapons[key[1].to_i], key[2].to_i]
      when "A"; [$data_armors[key[1].to_i], key[2].to_i]
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 合成に必要なアイテムが揃っているか判定
  #--------------------------------------------------------------------------
  def enough_material?
    return self.conflate_items.all? {|o,n| n <= $game_party.item_number(o) }
  end
  #--------------------------------------------------------------------------
  # ● 合成可能か判定
  #--------------------------------------------------------------------------
  def can_make?
    return false if $game_party.gold < self.conflate_price
    return false unless $game_party.item_number(self) < 99
    return false unless self.enough_material?
    return true
  end
end

class RPG::Item
  #--------------------------------------------------------------------------
  # ○ 合成費用の取得
  #--------------------------------------------------------------------------
  def conflate_price
    return Integer(super || self.price * CAO::Conflate::CUT_RATE)
  end
end
class RPG::Weapon
  #--------------------------------------------------------------------------
  # ○ 合成費用の取得
  #--------------------------------------------------------------------------
  def conflate_price
    return Integer(super || self.price * CAO::Conflate::CUT_RATE)
  end
end
class RPG::Armor
  #--------------------------------------------------------------------------
  # ○ 合成費用の取得
  #--------------------------------------------------------------------------
  def conflate_price
    return Integer(super || self.price * CAO::Conflate::CUT_RATE)
  end
end

class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :conflate_setting         # 合成 準備中フラグ
  attr_accessor :conflate_immediate       # 合成 即時実行フラグ
  attr_accessor :conflate_goods           # 合成 商品リスト
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_conflate_initialize initialize
  def initialize
    _cao_conflate_initialize
    @conflate_goods = []      # 合成アイテムＩＤ
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_conflate_command_118 command_118
  def command_118
    case @params[0]
    when /^<アイテム合成>/
      $game_temp.conflate_goods = []
      $game_temp.conflate_setting = true
      $game_temp.conflate_immediate = true
    when /^<合成準備>/
      $game_temp.conflate_goods = []
      $game_temp.conflate_setting = true
      $game_temp.conflate_immediate = false
    when /^<合成開始>/
      $game_temp.next_scene = "conflate"
      $game_temp.conflate_setting = false
      $game_temp.conflate_immediate = false
    when /^<合成中止>/
      $game_temp.conflate_goods = []
      $game_temp.conflate_setting = false
      $game_temp.conflate_immediate = false
    end
    _cao_conflate_command_118
  end
  #--------------------------------------------------------------------------
  # ○ ショップの処理
  #--------------------------------------------------------------------------
  alias _cao_conflate_command_302 command_302
  def command_302
    if $game_temp.conflate_setting
      items = [$data_items, $data_weapons, $data_armors]
      while [302, 605].include?(@list[@index].code)
        kind = @list[@index].parameters[0]
        id = @list[@index].parameters[1]
        $game_temp.conflate_goods.push(items[kind][id]) if items[kind][id]
        @index += 1
      end
      if $game_temp.conflate_immediate
        $game_temp.next_scene = "conflate"
        $game_temp.conflate_setting = false
        $game_temp.conflate_immediate = false
      end
      return false
    end
    _cao_conflate_command_302
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_conflate_update_scene_change update_scene_change
  def update_scene_change
    return if $game_player.moving?    # プレイヤーの移動中？
    if $game_temp.next_scene == "conflate"
      $game_temp.next_scene = nil
      $scene = Scene_Conflate.new
    else
      _cao_conflate_update_scene_change
    end
  end
end

class Window_Conflate < Window_Selectable
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x : ウィンドウの X 座標
  #     y : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 240, 360)
    self.index = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● アイテムの取得
  #--------------------------------------------------------------------------
  def item
    return @data[self.index]
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @data = []
    $game_temp.conflate_goods.each {|item| @data.push(item) }
    @item_max = @data.size
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    draw_item_name(item, rect.x, rect.y, item.can_make?)
  end
  #--------------------------------------------------------------------------
  # ● ヘルプテキスト更新
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_text(self.item == nil ? "" : self.item.description)
  end
end

class Window_ConflateGold < Window_Base
  include CAO::Conflate
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x : ウィンドウの X 座標
  #     y : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 304, 56)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = system_color
    self.contents.draw_text(0, 0, self.contents.width, WLH, VOCAB[:gold])
    draw_currency_value($game_party.gold, 0, 0, self.width - 32)
  end
end

class Window_ConflateStatus < Window_Base
  include CAO::Conflate
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x : ウィンドウの X 座標
  #     y : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 304, 224)
    @item = nil
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    return if @item == nil
    self.contents.font.color = system_color
    self.contents.draw_text(0, 0, self.contents.width, WLH, VOCAB[:material])
    @item.conflate_items.each_with_index do |(item,num), i|
      y = i * WLH + WLH
      draw_item_name(item, 8, y, num <= $game_party.item_number(item))
      self.contents.draw_text(8, y, self.contents.width-52, WLH, num, 2)
      text = sprintf("(%02d)", $game_party.item_number(item))
      self.contents.draw_text(8, y, self.contents.width-8, WLH, text, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● アイテムの設定
  #     item : 新しいアイテム
  #--------------------------------------------------------------------------
  def item=(item)
    if @item != item
      @item = item
      refresh
    end
  end
end

class Window_ConflateInfo < Window_Base
  include CAO::Conflate
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x : ウィンドウの X 座標
  #     y : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 304, 80)
    @item = nil
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    return if @item == nil
    width = self.contents.width
    self.contents.font.color = system_color
    self.contents.draw_text(0, 0, width, WLH, VOCAB[:have])
    self.contents.draw_text(0, 0, width, WLH, VOCAB[:have_u], 2)
    self.contents.draw_text(0, WLH, width, WLH, VOCAB[:cost])
    self.contents.draw_text(0, WLH, width, WLH, Vocab::gold, 2)
    self.contents.font.color = normal_color
    width -= contents.text_size(Vocab::gold).width + 2
    self.contents.draw_text(0, 0, width, WLH, $game_party.item_number(@item), 2)
    self.contents.draw_text(0, WLH, width, WLH, @item.conflate_price, 2)
  end
  #--------------------------------------------------------------------------
  # ● アイテムの設定
  #     item : 新しいアイテム
  #--------------------------------------------------------------------------
  def item=(item)
    if @item != item
      @item = item
      refresh
    end
  end
end

class Scene_Conflate < Scene_Base
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    @viewport = Viewport.new(0, 56, 544, 360)
    @viewport.z = 100
    create_menu_background
    @help_window = Window_Help.new
    @gold_window = Window_ConflateGold.new(240, 304)
    @gold_window.viewport = @viewport
    @conflate_window = Window_Conflate.new(0, 0)
    @conflate_window.viewport = @viewport
    @conflate_window.help_window = @help_window
    @info_window = Window_ConflateInfo.new(240, 0)
    @info_window.viewport = @viewport
    @material_window = Window_ConflateStatus.new(240, 80)
    @material_window.viewport = @viewport
    create_status_window
    
    if CAO::Conflate::FILE_SCENEBACK || CAO::Conflate::FILE_STATUSBACK
      @help_window.opacity = 0
      @gold_window.opacity = 0
      @conflate_window.opacity = 0
      @info_window.opacity = 0
      @material_window.opacity = 0
      @status_window.opacity = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    @viewport.dispose
    @help_window.dispose
    @gold_window.dispose
    @conflate_window.dispose
    @info_window.dispose
    @material_window.dispose
    @status_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● メニュー画面系の背景作成
  #--------------------------------------------------------------------------
  def create_menu_background
    if CAO::Conflate::FILE_SCENEBACK
      @menuback_sprite = Sprite.new
      @menuback_sprite.bitmap = Cache.system(CAO::Conflate::FILE_SCENEBACK)
    else
      super
    end
    if CAO::Conflate::FILE_STATUSBACK
      @statusback_sprite = Sprite.new(@viewport)
      @statusback_sprite.bitmap = Cache.system(CAO::Conflate::FILE_STATUSBACK)
    end
    update_menu_background
  end
  #--------------------------------------------------------------------------
  # ● メニュー画面系の背景解放
  #--------------------------------------------------------------------------
  def dispose_menu_background
    super
    @statusback_sprite.dispose if CAO::Conflate::FILE_STATUSBACK
  end
  #--------------------------------------------------------------------------
  # ● ショップステータスウィンドウの生成
  #--------------------------------------------------------------------------
  def create_status_window
    @status_window = Window_ShopStatus.new(544, 0)
    @status_window.x = 544
    @status_window.height = 360
    @status_window.viewport = @viewport
  end
  #--------------------------------------------------------------------------
  # ● 元の画面へ戻る
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Scene_Map.new
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    @viewport.update
    @help_window.update
    @gold_window.update
    @conflate_window.update
    @info_window.update
    @material_window.update
    @status_window.update
    
    @info_window.item = @conflate_window.item
    @material_window.item = @conflate_window.item
    @status_window.item = @conflate_window.item
    
    update_conflate_input
    update_status_input
    
    if @open_status
      @viewport.ox += 16
      if @viewport.ox > @status_window.width
        @viewport.ox = @status_window.width
        @open_status = false
      end
    elsif @close_status
      @viewport.ox -= 16
      if @viewport.ox < 0
        @viewport.ox = 0
        @close_status = false
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 合成アイテムの入力更新
  #--------------------------------------------------------------------------
  def update_conflate_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene
    elsif Input.trigger?(Input::C)
      if @conflate_window.item.can_make?
        Sound.play_shop
        $game_party.lose_gold(@conflate_window.item.conflate_price)
        for item,n in @conflate_window.item.conflate_items
          $game_party.lose_item(item, n)
        end
        $game_party.gain_item(@conflate_window.item, 1)
        @gold_window.refresh
        @conflate_window.refresh
        @info_window.refresh
        @material_window.refresh
        @status_window.refresh
      else
        Sound.play_buzzer
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● ショップステータスの入力更新
  #--------------------------------------------------------------------------
  def update_status_input
    return unless CAO::Conflate::USE_SHOP_STATUS
    if Input.trigger?(Input::LEFT)
      @open_status = false
      @close_status = true
    elsif Input.trigger?(Input::RIGHT)
      @open_status = true
      @close_status = false
    end
  end
end
