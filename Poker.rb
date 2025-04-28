#=============================================================================
#  [RGSS2] ポーカー - v1.0.8
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

  ミニゲーム「ポーカー」の機能を追加します。

 -- 画像規格 ----------------------------------------------------------------

  ★ トランプの画像
   504 x 192 の画像（Trump）を "Graphics/System" にご用意ください。

  ★ 背景画像
   544 x 416 の画像（BackPoker）を "Graphics/System" にご用意ください。
   ※ 背景画像を使用しない場合は、必要ありません。

 -- 使用方法 ----------------------------------------------------------------

  ★ ポーカーの開始
   イベントコマンド「ラベル」に ポーカー開始 と記述

  ★ コインの操作
   イベントコマンド「変数の操作」で増減させてください。
   ※ ミニゲームは、このコインを消費してプレイします。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================

module CAO_POKER
  #--------------------------------------------------------------------------
  # ◇ コインを格納するイベント変数の番号
  #--------------------------------------------------------------------------
  VAR_COIN = 17
  #--------------------------------------------------------------------------
  # ◇ 賭けられるコインの上限
  #--------------------------------------------------------------------------
  #   0 で上限なし(999999枚まで)
  #--------------------------------------------------------------------------
  MAX_COIN = 0
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの可視
  #--------------------------------------------------------------------------
  #   背景画像を使用する場合は false にし、ウィンドウを非表示してください。
  #--------------------------------------------------------------------------
  WINDOW_OPACITY = true
  #--------------------------------------------------------------------------
  # ◇ コインの配当
  #--------------------------------------------------------------------------
  #   賭けコインの n 倍で計算します。
  #   一番最初の要素は、0 以外にはしないでください。
  #--------------------------------------------------------------------------
  POKER_WINNING = [0, 1.1, 2, 3, 5, 7, 10, 50, 100, 500]
  #--------------------------------------------------------------------------
  # ◇ 効果音の設定（["ファイル名, ピッチ"]）
  #--------------------------------------------------------------------------
  SOUND_COIN = ["Shop", 100]      # 賭けコイン決定時
  SOUND_PO   = ["Chime2", 100]    # 役が揃ったとき
  SOUND_PX   = ["Crow", 100]      # 役が揃わなかったとき
  SOUND_WC1O = ["Chime2", 100]    # ダブルチャンス成功時
  SOUND_WC3O = ["Chicken", 100]   # ダブルチャンス全て成功時
  SOUND_WCX  = ["Jump2", 100]     # ダブルチャンス失敗時
  #--------------------------------------------------------------------------
  # ◇ ＢＧＭの設定
  #--------------------------------------------------------------------------
  #   ＢＧＭのファイル名を設定。変更しない場合は、nil を代入
  #--------------------------------------------------------------------------
  BGM_WC_NAME = "Scene9"  # ダブルチャンス時
  #--------------------------------------------------------------------------
  # ◇ 用語の設定
  #--------------------------------------------------------------------------
    # 賭けコイン入力
    NUMBER_TEXT = "賭けるコインの枚数"
    # コインの単位
    NAME_COIN = "枚"
    # 役名（１０個）
    POKER_NAME = [
      "ハイカード", "ワンペア", "ツーペア", "スリーカード",
      "ストレート", "フラッシュ", "フルハウス", "フォーカード",
      "ストレートフラッシュ", "ロイヤルストレートフラッシュ"
    ]
    # コマンド文字の配列（２次）
    CMD_NAME = [
      ["カードを交換する"],
      ["続ける", "やめる"],
      ["挑戦する", "挑戦しない"]
    ]
    # ヘルプウィンドウのメッセージ（Scene_Poker#update_help_window）
    # ダブルチャンスのテキスト（Window_Poker#start_double_chance）
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


# 正規表現
CAO_POKER::REGEXP_START = /^ポーカー開始/i

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_poker_update_scene_change update_scene_change
  def update_scene_change
    return if $game_player.moving?    # プレイヤーの移動中？
    if $game_temp.next_scene == "poker"
      $game_temp.next_scene = nil
      $game_temp.map_bgm = RPG::BGM.last
      $scene = Scene_Poker.new
    else
      _cao_poker_update_scene_change
    end
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_poker_command_118 command_118
  def command_118
    if @params[0][CAO_POKER::REGEXP_START]
      $game_temp.next_scene = "poker"
      return true
    end
    return _cao_poker_command_118
  end
end

class Window_Coin < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 160, WLH + 32)
    self.opacity = CAO_POKER::WINDOW_OPACITY ? 255 : 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    rect = Rect.new(0, 0, self.width - 32, WLH)
    rect.width -= 24
    self.contents.font.color = normal_color
    self.contents.draw_text(rect, $game_variables[CAO_POKER::VAR_COIN], 2)
    rect.x = rect.width
    rect.width = 24
    self.contents.font.color = system_color
    self.contents.draw_text(rect, CAO_POKER::NAME_COIN, 2)
  end
end

class Window_PokerCommand < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  MODE_POKER   = 0                        # ポーカー
  MODE_AGAIN   = 1                        # 再びプレイ
  MODE_WCHANCE = 2                        # ダブルチャンス
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :commands                 # コマンド
  attr_reader   :mode                     # 表示項目の種類
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(x, y, width)
    super(x, y, width, WLH + 32, 16)
    @mode = MODE_POKER
    @item_max = CAO_POKER::CMD_NAME[@mode].size
    @column_max = @item_max
    refresh
    self.index = -1
    self.active = false
    self.visible = false
    self.opacity = CAO_POKER::WINDOW_OPACITY ? 255 : 0
  end
  #--------------------------------------------------------------------------
  # ● コマンド項目の変更
  #--------------------------------------------------------------------------
  def mode=(val)
    @mode = val
    @index = 0
    @item_max = CAO_POKER::CMD_NAME[@mode].size
    @column_max = @item_max
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    for i in 0...@item_max
      draw_item(i)
    end
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
    self.contents.draw_text(rect, CAO_POKER::CMD_NAME[@mode][index], 1)
  end
end

class Window_PokerNumber < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 360, 384, 56)
    @number = 0
    @digits_max = 6   # 桁数
    if CAO_POKER::MAX_COIN != 0
      @digits_max = CAO_POKER::MAX_COIN.to_s.size
    end
    @index = @digits_max - 1
    self.z += 9999
    self.opacity = CAO_POKER::WINDOW_OPACITY ? 255 : 0
    clear
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ● 数値の取得
  #--------------------------------------------------------------------------
  def number
    return @number
  end
  #--------------------------------------------------------------------------
  # ● 数値の設定
  #     number : 新しい数値
  #--------------------------------------------------------------------------
  def number=(number)
    @number = [[number, 0].max, 10 ** @digits_max - 1].min
    if CAO_POKER::MAX_COIN != 0
      @number = [CAO_POKER::MAX_COIN, @number].min
    end
    refresh
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_right(wrap)
    if @index < @digits_max - 1 or wrap
      @index = (@index + 1) % @digits_max
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_left(wrap)
    if @index > 0 or wrap
      @index = (@index + @digits_max - 1) % @digits_max
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
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
        self.number = @number
#~         refresh
      end
      last_index = @index
      if Input.repeat?(Input::RIGHT)
        cursor_right(Input.trigger?(Input::RIGHT))
      end
      if Input.repeat?(Input::LEFT)
        cursor_left(Input.trigger?(Input::LEFT))
      end
      if @index != last_index
        Sound.play_cursor
      end
      update_cursor
    end
  end
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  def clear
    self.contents.clear
    self.contents.font.color = system_color
    self.contents.draw_text(0, 0, 180, WLH, "#{CAO_POKER::NUMBER_TEXT}", 1)
    self.contents.draw_text(304, 0, 48, WLH, "#{CAO_POKER::NAME_COIN}", 1)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
#~     self.contents.clear_rect(192, 0, 100, WLH)
#~     self.contents.font.color = normal_color
#~     s = sprintf("%0*d", @digits_max, @number)
#~     for i in 0...@digits_max
#~       self.contents.draw_text(194 + i * 16, 0, 16, WLH, s[i,1], 1)
#~     end
    self.contents.clear_rect(180, 0, 124, WLH)
    self.contents.font.color = normal_color
    s = sprintf("%0*d", @digits_max, @number)
#~     x = 300 - 16 * (@digits_max - 1)
    @digits_max.times do |i|
      self.contents.draw_text(item_rect(i), s[i,1], 1)
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def left
    return 300 - 16 * @digits_max
  end
  #--------------------------------------------------------------------------
  # ● 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    return Rect.new(self.left + index * 16, 0, 16, WLH)
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    if @index < 0                   # カーソル位置が 0 未満の場合
      self.cursor_rect.empty        # カーソルを無効とする
    else                            # カーソル位置が 0 以上の場合
      self.cursor_rect = item_rect(@index)
    end
  end
  #--------------------------------------------------------------------------
  # ● コインの支払い
  #--------------------------------------------------------------------------
  def lose_coin
    if $game_variables[CAO_POKER::VAR_COIN] >= @number && @number != 0
      $game_variables[CAO_POKER::VAR_COIN] -= @number
      return true
    end
    return false
  end
end

class Window_Poker < Window_Base
  include CAO_POKER
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  MODE_POKER = 0                          # ポーカーモード
  MODE_WCHANCE = 1                        # ダブルチャンスモード

  CARD_WIDTH = 36                         # カード１枚の横幅
  CARD_HEIGHT = 48                        # カード１枚の縦幅
  CARD_SPACING = 20                       # カードの間隔
  CARD_ZOOM = 2                           # カードの拡大率
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_writer   :bet                      # 賭けたコインの枚数
  attr_reader   :mode                     # ポーカーとダブルチャンス
  attr_reader   :chance                   # ダブルチャンスの最大回数
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 56, 544, 304)
    self.active = false
    self.opacity = WINDOW_OPACITY ? 255 : 0
    clear
    draw_rate
  end
  #--------------------------------------------------------------------------
  # ● 変数の初期化
  #--------------------------------------------------------------------------
  def clear
    @index = -1
    @bet = 0
    @mode = MODE_POKER
    @chance = 0
    create_card
  end
  #--------------------------------------------------------------------------
  # ● ゲーム開始
  #--------------------------------------------------------------------------
  def start
    draw_rate
    5.times do |i| number_in_card(i) end
  end
  #--------------------------------------------------------------------------
  # ● ゲーム終了
  #--------------------------------------------------------------------------
  def terminate
    self.contents.clear
    5.times {|i| @card[i].sprite.dispose }
    clear
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.contents.dispose
    5.times {|i| @card[i].sprite.dispose }
    super
  end
  #--------------------------------------------------------------------------
  # ● ダブルチャンス開始
  #--------------------------------------------------------------------------
  def start_double_chance
    @chance += 1
    @mode = MODE_WCHANCE
    @index = 1
    self.contents.clear
    self.contents.font.color = normal_color
    text = ["【ダブルチャンス】"]
    text << "　　今回、獲得したコインを賭けて挑戦します。"
    text << "　　表のカードより大きい数字のカードを選んでください。"
    text << "　　成功した場合は、賭けた枚数分コインを獲得できます。"
    text << "　　失敗した場合、獲得したコインを全て失います。"
    for i in 0...text.size
      self.contents.draw_text(0, WLH * i, 512, WLH, text[i])
    end
    for i in 0...5
      @card[i].open = (i == 0) ? true : false
      @card[i].kind = @stock[0]   # 手札を補充
      @stock.delete_at(0)         # 山札を１枚削除
      number_in_card(i)           # 画像をセット
      @card[i].sprite.y = 230
    end
    @card[@index].sprite.y = 220
  end
  #--------------------------------------------------------------------------
  # ● 配当の描画
  #--------------------------------------------------------------------------
  def draw_rate(index = 0)
    self.contents.clear
    self.contents.font.size = 18
    for i in 0...10
      x = i < 5 ? 0 : 264
      y = WLH * (i % 5)
      self.contents.font.color = normal_color
      self.contents.font.color = Color.new(255, 0, 0) if i == index && i != 0
      self.contents.draw_text(x, y, 170, WLH, POKER_NAME[i])
      self.contents.draw_text(x + 170, y, 18, WLH, "：", 1)
      self.contents.draw_text(x+188,y,60,WLH, (POKER_WINNING[i]*@bet).to_i,2)
    end
    self.contents.font.size = 20
  end
  #--------------------------------------------------------------------------
  # ● 配当の描画（賭け枚数選択時）
  #--------------------------------------------------------------------------
  def draw_start_rate(bet)
    self.contents.clear
    self.contents.font.size = 18
    for i in 0...10
      x = i < 5 ? 0 : 264
      y = WLH * (i % 5)
      self.contents.font.color = normal_color
      self.contents.draw_text(x, y, 170, WLH, POKER_NAME[i])
      self.contents.draw_text(x + 170, y, 18, WLH, "：", 1)
      self.contents.draw_text(x+188, y, 60, WLH, (POKER_WINNING[i]*bet).to_i, 2)
    end
    self.contents.font.size = 20
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    for i in 0...5
      unless @card[i].open
        @card[i].kind = @stock[0]   # 手札を補充
        @stock.delete_at(0)         # 山札を１枚削除
        @card[i].open = true        # カードを表に
        number_in_card(i)           # 画像をセット
      end
    end
    index = check_card
    draw_rate(index) if index > 0
  end
  #--------------------------------------------------------------------------
  # ● カードの初期化
  #--------------------------------------------------------------------------
  def create_card
    # カードの山札（0xx~：スハダク　x00~：1-13）
    stock = Array.new(52) { |i| n = 100 * (i / 13) + i % 13 }
    @stock = stock.sort_by{ rand }   # シャッフル
    # カードセット（種類、表裏、スプライト）
    card_set = Struct.new(:kind, :open, :sprite)
    @card = []
    for i in 0...5
      @card[i] =  card_set.new
      # カードの種類
      @card[i].kind = @stock[0]
      # 山札から削除
      @stock.delete_at(0)
      # カードの表裏
      @card[i].open = true
      # カードのスプライト
      @card[i].sprite = Sprite.new
      @card[i].sprite.bitmap = Bitmap.new(CARD_WIDTH, CARD_HEIGHT)
      @card[i].sprite.zoom_x = CARD_ZOOM
      @card[i].sprite.zoom_y = CARD_ZOOM
      @card[i].sprite.y = 230
      @card[i].sprite.z = self.z + 1
      card_width = CARD_WIDTH * CARD_ZOOM
      margin = (544 - (card_width * 5 + CARD_SPACING * 4)) / 2
      @card[i].sprite.x = (card_width + CARD_SPACING) * i + margin
    end
  end
  #--------------------------------------------------------------------------
  # ● カードの画像代入
  #--------------------------------------------------------------------------
  def number_in_card(index)
    rect = Rect.new(468, 0, CARD_WIDTH, CARD_HEIGHT)
    if @card[index].open
      rect.x = CARD_WIDTH * (@card[index].kind % 100)
      rect.y = CARD_HEIGHT * (@card[index].kind / 100)
    end
    @card[index].sprite.bitmap.blt(0, 0, Cache.system("Trump"), rect)
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    last_index = @index
    if @mode == MODE_POKER  # 通常モード
      if Input.repeat?(Input::RIGHT)
        @index >= 4 ? @index = 0 : @index += 1
      end
      if Input.repeat?(Input::LEFT)
        @index <= 0 ? @index = 4 : @index -= 1
      end
      if Input.trigger?(Input::C)
        Sound.play_decision
        rect = Rect.new(468, 0, CARD_WIDTH, CARD_HEIGHT)
        @card[@index].open ^= true    # カードを裏返す
        number_in_card(@index)
      end
    else    # ダブルチャンスモード
      if Input.repeat?(Input::RIGHT)
        @index >= 4 ? @index = 1 : @index += 1
      end
      if Input.repeat?(Input::LEFT)
        @index <= 1 ? @index = 1 : @index -= 1
      end
    end
    if @index != last_index
      Sound.play_cursor
      @card[last_index].sprite.y = 230
      @card[@index].sprite.y = 220
    end
  end
  #--------------------------------------------------------------------------
  # ● 選択時の上下移動
  #--------------------------------------------------------------------------
  def update_card
    if @index == -1
      @index = 0
      @card[@index].sprite.y = 220
    else
      @card[@index].sprite.y = 230
      @index = -1
    end
  end
  #--------------------------------------------------------------------------
  # ● カードの役判定
  #--------------------------------------------------------------------------
  def check_card
    mark = Array.new(5) { |i| @card[i].kind / 100 }
    number = Array.new(5) { |i| @card[i].kind % 100 }
    number.sort!
    # マークが同じ
    mark.delete(mark[4])
    bool_mark = mark == []
    # 数字が連番
    if number[0] == 0 && number[4] == 12
      ary = [[9, 10, 11], [1, 10, 11], [1, 2, 11], [1, 2, 3]]
      for i in 0...4
        if number[1, 3] == ary[i]
          boll_number = true
          break
        end
      end
    else
      for i in 0...5
        break unless number[2] - 2 + i == number[i]
        boll_number = true if i == 4
      end
    end
    if bool_mark && boll_number && number[1] == 9
      # ロイヤルストレートフラッシュ
      return 9
    elsif bool_mark && boll_number
      # ストレートフラッシュ
      return 8
    elsif bool_mark
      # フラッシュ
      return 5
    elsif boll_number
      # ストレート
      return 4
    end
    for i in 0...5
      n = number.clone
      n.delete(number[i])
      case n.size
      when 1
        # フォーカード
        return 7
      when 2
        # フルハウス  # スリーカード
        return (n[0] == n[1]) ?  6 : 3
      when 3
        # フルハウス
        return 6 if n == [n[0], n[0], n[0]]
        # ツーペア
        return 2 if n[0] == n[1] || n[0] == n[2] || n[1] == n[2]
        # ワンペア
        return 1
      end
    end
    return 0
  end
  #--------------------------------------------------------------------------
  # ● カードの大きさ判定
  #--------------------------------------------------------------------------
  def check_high
    @card[@index].open = true   # カードを表にする
    number_in_card(@index)      # 画像をセット
    # カードを比較
    return true if @card[0].kind % 100 < @card[@index].kind % 100
    return false
  end
end

class Scene_Poker < Scene_Base
  include CAO_POKER
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  BGM_DOUBLE_CHANCE = BGM_WC_NAME ? RPG::BGM.new(BGM_WC_NAME) : nil
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    @command_window = Window_PokerCommand.new(0, 360, 384)
    @main_window = Window_Poker.new
    @number_window = Window_PokerNumber.new
    @coin_window = Window_Coin.new(384, 360)
    @help_window = Window_Base.new(0, 0, 544, 56)
    @help_window.opacity = WINDOW_OPACITY ? 255 : 0
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    @command_window.dispose
    @number_window.dispose
    @coin_window.dispose
    @help_window.dispose
    @main_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    update_help_window
    @coin_window.update
    if @main_window.active
      update_card_select
      @main_window.update
    elsif @number_window.active
      update_bet_input
    elsif @command_window.active
      update_command_select
      @command_window.update
    end
  end
  #--------------------------------------------------------------------------
  # ● メニュー画面系の背景作成
  #--------------------------------------------------------------------------
  def create_menu_background
    @menuback_sprite = Sprite.new
    if WINDOW_OPACITY
      @menuback_sprite.bitmap = $game_temp.background_bitmap
      @menuback_sprite.color.set(16, 16, 16, 128)
    else
      @menuback_sprite.bitmap = Cache.system("BackPoker")
    end
    update_menu_background
  end
  #--------------------------------------------------------------------------
  # ● 掛け金の入力更新
  #--------------------------------------------------------------------------
  def update_bet_input
    last_number = @number_window.number
    @number_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      unless @number_window.lose_coin
        Sound.play_buzzer
        return
      end
      Audio.se_play("Audio/SE/" + SOUND_COIN[0], 100, SOUND_COIN[1])
      @main_window.bet = @number_window.number
      @coin_window.refresh
      @number_window.active = false
      @number_window.visible = false
      @command_window.visible = true
      @command_window.index = -1
      @command_window.refresh
      @main_window.active = true
      @main_window.start
      @main_window.update_card
    end
    if last_number != @number_window.number
      @main_window.draw_start_rate(@number_window.number)
    end
  end
  #--------------------------------------------------------------------------
  # ● カード選択の更新
  #--------------------------------------------------------------------------
  def update_card_select
    # ポーカーゲーム中のカード選択とコマンドの切り替え
    if Input.trigger?(Input::DOWN) && @main_window.mode == 0
      Sound.play_cursor
      @main_window.update_card
      @main_window.active = false
      @command_window.index = 0
      @command_window.active = true
    end
    # ダブルチャンス中のカード選択
    if Input.trigger?(Input::C)  && @main_window.mode != 0
      # 選択したカードが大きかった
      if @main_window.check_high
        if @main_window.chance == 3
          Audio.se_play("Audio/SE/" + SOUND_WC3O[0], 100, SOUND_WC3O[1])
        else
          Audio.se_play("Audio/SE/" + SOUND_WC1O[0], 100, SOUND_WC1O[1])
        end
        $game_variables[VAR_COIN] += @gain_coin
        @command_window.mode = Window_PokerCommand::MODE_WCHANCE
        @command_window.active = true
        @main_window.active = false
      else
        Audio.se_play("Audio/SE/" + SOUND_WCX[0], 100, SOUND_WCX[1])
        $game_variables[VAR_COIN] = @chance_coin
        @command_window.mode = Window_PokerCommand::MODE_AGAIN
        @command_window.active = true
        @main_window.active = false
      end
      @coin_window.refresh
      if @main_window.chance == 3
        @main_window.active = false
        @command_window.active = true
        @command_window.mode = Window_PokerCommand::MODE_AGAIN
      end
      $game_temp.map_bgm.play if BGM_DOUBLE_CHANCE
    end
  end
  #--------------------------------------------------------------------------
  # ● コマンド選択の更新
  #--------------------------------------------------------------------------
  def update_command_select
    if Input.trigger?(Input::UP) && @command_window.mode == 0
      Sound.play_cursor
      @main_window.update_card
      @main_window.active = true
      @command_window.index = -1
      @command_window.active = false
    end
    if Input.trigger?(Input::C)
      Sound.play_decision
      case @command_window.mode
      when Window_PokerCommand::MODE_POKER  # カード交換
        @main_window.refresh
        check_pat
      when Window_PokerCommand::MODE_AGAIN  # 続ける、やめる
        if @command_window.index == 0       # 続ける
          @command_window.mode = Window_PokerCommand::MODE_POKER
          # コマンドウィンドウの切り替え
          @command_window.active = false
          @command_window.visible = false
          @number_window.active = true
          @number_window.visible = true
          # メインウィンドウ内容を削除
          @main_window.terminate
          @main_window.draw_start_rate(@number_window.number)
        else                                # やめる
          Sound.play_cancel
          $scene = Scene_Map.new
        end
      when Window_PokerCommand::MODE_WCHANCE  # ダブルチャンス
        if @command_window.index == 0       # 挑戦する
          BGM_DOUBLE_CHANCE.play if BGM_DOUBLE_CHANCE
          if @main_window.chance == 0
            @chance_coin = $game_variables[VAR_COIN] - @gain_coin
          end
          @command_window.contents.clear
          @command_window.active = false
          @main_window.active = true
          @main_window.start_double_chance
          @command_window.index = -1
        else                                # 挑戦しない
          @chance_coin = 0
          @command_window.mode = Window_PokerCommand::MODE_AGAIN
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 役の判定
  #--------------------------------------------------------------------------
  def check_pat
    @gain_coin = 0
    pat = @main_window.check_card
    if pat > 0  # ハイカード以外なら
      Audio.se_play("Audio/SE/" + SOUND_PO[0], 100, SOUND_PO[1])
      @gain_coin = (@number_window.number * POKER_WINNING[pat]).to_i
      $game_variables[VAR_COIN] += @gain_coin
      @command_window.mode = Window_PokerCommand::MODE_WCHANCE
    else  # ハイカードなら
      Audio.se_play("Audio/SE/" + SOUND_PX[0], 100, SOUND_PX[1])
      @command_window.mode = Window_PokerCommand::MODE_AGAIN
    end
    @coin_window.refresh
  end
  #--------------------------------------------------------------------------
  # ● ヘルプウィンドウの更新
  #--------------------------------------------------------------------------
  def update_help_window
    if @main_window.active
      if @main_window.mode == Window_Poker::MODE_POKER
        t = "交換するカードを選択して裏返してください。"
      else
        t = "表にするカードを１枚選択してください。"
      end
    elsif @number_window.active
      t = "賭けるコインの枚数を入力してください。"
    elsif @command_window.active
      case @command_window.mode
      when Window_PokerCommand::MODE_POKER
        t = "裏向きのカードを交換します。"
      when Window_PokerCommand::MODE_AGAIN
        ary = ["ゲームを続けます。", "ゲームを終了します。"]
        t = ary[@command_window.index]
      when Window_PokerCommand::MODE_WCHANCE
        ary = [ "成功時には、コイン #{@gain_coin} 枚を獲得できます。",
                "ダブルチャンスには、挑戦しません。"                   ]
        t = ary[@command_window.index]
      end
    end
    if t != @help_last_text
      @help_last_text = t
      @help_window.contents.clear
      @help_window.contents.draw_text(0, 0, 512, 24, t, 1)
    end
  end
end
