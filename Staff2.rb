#=============================================================================
#  [RGSS2] ショップ店員 - v2.0.1
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

  ※ このスクリプトの実行には、Interpreter 108 EX が必要です。
  ※ このスクリプトの実行には、割り込みシーン が必要です。
  ※ このスクリプトの実行には、＜拡張＞ ウィンドウベース が必要です。

 -- 使用方法 ----------------------------------------------------------------

  ★ ショップ起動
   イベントコマンドで通常通り起動してください。

  ★ 店員のコメント
   イベントコマンド「注釈」の１行目に <店員コメント> と記述して、
   以降にコメントを記述してください。
  ※ 設定なしでも可能です。

  ★ 各種画像
   背景画像や店員画像は、ピクチャで表示してください。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::Staff
  #--------------------------------------------------------------------------
  # ◇ コメントの文字サイズ
  #--------------------------------------------------------------------------
  FONT_SIZE = 20
  #--------------------------------------------------------------------------
  # ◇ ウィンドウをスライドさせる
  #--------------------------------------------------------------------------
  SLIDE_OPEN = true
  #--------------------------------------------------------------------------
  # ◇ ウィンドウを表示する
  #--------------------------------------------------------------------------
  SHOW_WINDOW = true
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの背景画像の設定
  #--------------------------------------------------------------------------
  #     ショップ背景は、店員画像とともにピクチャで表示してください。
  #--------------------------------------------------------------------------
  IMG_COMMENT = "BackShopComment"
  IMG_STATUS  = "BackShopStatus"
  IMG_BUY     = "BackShopItem"
  IMG_SELL    = "BackShopItem"
  IMG_NUMBER  = "BackShopItem"
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
  attr_accessor :shop_comment             # ショップ 店員コメント
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_staff_initialize initialize
  def initialize
    _cao_staff_initialize
    @shop_comment = nil
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 注釈
  #--------------------------------------------------------------------------
  alias _cao_staff_command_108 command_108
  def command_108
    if @parameters.first[/^<店員コメント>/]
      $game_temp.shop_comment = get_all_text_108
      $game_temp.shop_comment.shift
      return true
    end
    return _cao_staff_command_108
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ● ショップ画面への切り替え
  #--------------------------------------------------------------------------
  def call_shop
    $game_temp.next_scene = nil
    Scene_Shop.new
  end
end

class Window_ShopSell
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 304, 304)
    @column_max = 1
    refresh
  end
end

class Window_ShopComment < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 56, 304, 304)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    return unless $game_temp.shop_comment
    self.contents.font.color = normal_color
    self.contents.font.size = CAO::Staff::FONT_SIZE
    $game_temp.shop_comment.each_with_index do |text,i|
      draw_message(4, 4 + WLH * i, text)
    end
  end
  #--------------------------------------------------------------------------
  # ● 特殊文字の変換
  #--------------------------------------------------------------------------
  def convert_special_characters(text)
    text = text.dup
    text.gsub!(/\\V\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    text.gsub!(/\\V\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    text.gsub!(/\\N\[([0-9]+)\]/i) { $game_actors[$1.to_i].name }
    text.gsub!(/\\C\[([0-9]+)\]/i) { "\x01[#{$1}]" }
    text.gsub!(/\\\\/)             { "\\" }
    return text
  end
  #--------------------------------------------------------------------------
  # ● メッセージの更新
  #--------------------------------------------------------------------------
  def draw_message(x, y, text)
    contents_x = x
    text = convert_special_characters(text)
    loop do
      c = text.slice!(/./m)
      case c
      when nil                          # 描画すべき文字がない
        break
      when "\x01"                       # \C[n]  (文字色変更)
        text.sub!(/\[([0-9]+)\]/, "")
        self.contents.font.color = text_color($1.to_i)
        next
      else                              # 普通の文字
        self.contents.draw_text(contents_x, y, 40, WLH, c)
        c_width = self.contents.text_size(c).width
        contents_x += c_width
      end
    end
  end
end

module CAO::Staff::WindowEx
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def open
    self.visible = true
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def close
    self.visible = false
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def show
    self.visible = true
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def hide
    self.visible = false
  end
end

#==============================================================================
# ■ ウィンドウの開閉メソッドを再定義
#==============================================================================
class Window_ShopBuy;     include CAO::Staff::WindowEx; end
class Window_ShopSell;    include CAO::Staff::WindowEx; end
class Window_ShopNumber;  include CAO::Staff::WindowEx; end
class Window_ShopStatus;  include CAO::Staff::WindowEx; end
class Window_ShopComment; include CAO::Staff::WindowEx; end

#==============================================================================
# ■ 背景画像を使用
#==============================================================================
unless CAO::Staff::SHOW_WINDOW
  class Window_ShopBuy;     include CAO::Background; end
  class Window_ShopSell;    include CAO::Background; end
  class Window_ShopNumber;  include CAO::Background; end
  class Window_ShopStatus;  include CAO::Background; end
  class Window_ShopComment; include CAO::Background; end
end

#==============================================================================
# ■ スライド機能を使用
#==============================================================================
if CAO::Staff::SLIDE_OPEN
  class Window_ShopBuy;     include CAO::Slide; end
  class Window_ShopSell;    include CAO::Slide; end
  class Window_ShopNumber;  include CAO::Slide; end
  class Window_ShopStatus;  include CAO::Slide; end
  class Window_ShopComment; include CAO::Slide; end
end

class Scene_Shop < Scene_Interrupt
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_command_window
    @help_window = Window_Help.new
    @gold_window = Window_Gold.new(384, 360)
    @comment_window = Window_ShopComment.new
    @buy_window = Window_ShopBuy.new(0, 56)
    @sell_window = Window_ShopSell.new(0, 56)
    @number_window = Window_ShopNumber.new(0, 56)
    @status_window = Window_ShopStatus.new(304, 56)

    if CAO::Staff::SLIDE_OPEN
      @comment_window.slide_type = 4
      @buy_window.slide_type = 4
      @sell_window.slide_type = 4
      @status_window.slide_type = 6

      @comment_window.slide_speed = 4
      @buy_window.slide_speed = 4
      @sell_window.slide_speed = 4
      @status_window.slide_speed = 4
    end

    unless CAO::Staff::SHOW_WINDOW
      @command_window.opacity = 0
      @help_window.opacity = 0
      @gold_window.opacity = 0

      @comment_window.background = CAO::Staff::IMG_COMMENT
      @buy_window.background = CAO::Staff::IMG_BUY
      @sell_window.background = CAO::Staff::IMG_SELL
      @status_window.background = CAO::Staff::IMG_STATUS
      @number_window.background = CAO::Staff::IMG_NUMBER
    end

    @buy_window.active = false
    @buy_window.hide
    @buy_window.help_window = @help_window
    @sell_window.active = false
    @sell_window.hide
    @sell_window.help_window = @help_window
    @number_window.active = false
    @number_window.visible = false
    @status_window.hide
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    $game_temp.shop_comment = nil
    dispose_command_window
    @help_window.dispose
    @gold_window.dispose
    @comment_window.dispose
    @buy_window.dispose
    @sell_window.dispose
    @number_window.dispose
    @status_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● 元の画面へ戻る
  #--------------------------------------------------------------------------
  def return_scene
    @exit = true
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    @help_window.update
    @command_window.update
    @gold_window.update
    @comment_window.update
    @buy_window.update
    @sell_window.update
    @number_window.update
    @status_window.update
    if @command_window.active
      update_command_selection
    elsif @buy_window.active
      update_buy_selection
    elsif @sell_window.active
      update_sell_selection
    elsif @number_window.active
      update_number_input
    end
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    s1 = Vocab::ShopBuy
    s2 = Vocab::ShopSell
    s3 = Vocab::ShopCancel
    @command_window = Window_Command.new(384, [s1, s2, s3], 3)
    @command_window.y = 360
    if $game_temp.shop_purchase_only
      @command_window.draw_item(1, false)
    end
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの解放
  #--------------------------------------------------------------------------
  def dispose_command_window
    @command_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● コマンド選択の更新
  #--------------------------------------------------------------------------
  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene
    elsif Input.trigger?(Input::C)
      case @command_window.index
      when 0  # 購入する
        Sound.play_decision
        @command_window.active = false
        @comment_window.close
        @buy_window.open
        @buy_window.active = true
        @buy_window.refresh
        @status_window.open
      when 1  # 売却する
        if $game_temp.shop_purchase_only
          Sound.play_buzzer
        else
          Sound.play_decision
          @command_window.active = false
          @comment_window.close
          @sell_window.active = true
          @sell_window.open
          @sell_window.refresh
        end
      when 2  # やめる
        Sound.play_decision
        return_scene
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 購入アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_buy_selection
    @status_window.item = @buy_window.item
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @comment_window.open
      @buy_window.active = false
      @buy_window.close
      @status_window.close
      @status_window.item = nil
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
  #--------------------------------------------------------------------------
  # ● 売却アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_sell_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @comment_window.open
      @sell_window.active = false
      @sell_window.close
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
        @number_window.set(@item, max, @item.price / 2)
        @number_window.active = true
        @number_window.visible = true
        @status_window.visible = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 個数入力の更新
  #--------------------------------------------------------------------------
  def update_number_input
    if Input.trigger?(Input::B)
      cancel_number_input
    elsif Input.trigger?(Input::C)
      decide_number_input
    end
  end
  #--------------------------------------------------------------------------
  # ● 個数入力のキャンセル
  #--------------------------------------------------------------------------
  def cancel_number_input
    Sound.play_cancel
    @number_window.active = false
    @number_window.visible = false
    case @command_window.index
    when 0  # 購入する
      @buy_window.active = true
      @buy_window.visible = true
    when 1  # 売却する
      @sell_window.active = true
      @sell_window.visible = true
      @status_window.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ● 個数入力の決定
  #--------------------------------------------------------------------------
  def decide_number_input
    Sound.play_shop
    @number_window.active = false
    @number_window.visible = false
    case @command_window.index
    when 0  # 購入する
      $game_party.lose_gold(@number_window.number * @item.price)
      $game_party.gain_item(@item, @number_window.number)
      @gold_window.refresh
      @buy_window.refresh
      @status_window.refresh
      @buy_window.active = true
      @buy_window.visible = true
    when 1  # 売却する
      $game_party.gain_gold(@number_window.number * (@item.price / 2))
      $game_party.lose_item(@item, @number_window.number)
      @gold_window.refresh
      @sell_window.refresh
      @status_window.refresh
      @sell_window.active = true
      @sell_window.visible = true
      @status_window.visible = false
    end
  end
end
