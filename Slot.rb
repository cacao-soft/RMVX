#=============================================================================
#  [RGSS2] シングルラインスロット - v1.0.0
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

  シングルラインスロットの機能を追加します。

 -- 使用方法 ----------------------------------------------------------------

  ★ スロットゲームを開始する
   イベントコマンド「ラベル」に スロット開始：0,1,2 と記入してください。

  ★ 操作方法
   Ｃボタン : 1BET, 回転を止める
   Ａボタン : MAX_BET
   下ボタン : 回転開始
   Ｂボタン : スロット終了

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
module Slot
  #--------------------------------------------------------------------------
  # ◇ コインを保存するＥＶ変数の番号
  #--------------------------------------------------------------------------
  VAR_ID_COIN = 1
  #--------------------------------------------------------------------------
  # ◇ 賭けコインの枚数 (1BET)
  #--------------------------------------------------------------------------
  BET_ONE = 1
  #--------------------------------------------------------------------------
  # ◇ リールのシンボルの並び
  #--------------------------------------------------------------------------
  SYMBOL = {}
  SYMBOL[0] = [0, 4, 3, 0, 5, 1, 4, 3, 1, 0, 2, 2, 4, 2, 1, 0]
  SYMBOL[1] = [2, 1, 4, 5, 0, 4, 3, 5, 1, 2, 0, 3, 3, 2, 3, 4]
  SYMBOL[2] = [3, 4, 2, 0, 3, 2, 4, 1, 5, 3, 1, 1, 4, 4, 2, 5]
  #--------------------------------------------------------------------------
  # ◇ 配当金
  #--------------------------------------------------------------------------
  #     左から小さい順で。順番は関係ない。設定されているものが揃えば良い。
  #--------------------------------------------------------------------------
  WINTABLE = {
    [0,0,0] => [100, 300, 999, false],
    [1,1,1] => [ 40,  60,  80, true],
    [2,2,2] => [ 30,  40,  50, false],
    [3,3,3] => [ 20,  30,  40, false],
    [4,4,4] => [  6,  10,  15, false],
    [5,5,5] => [ 50,  75, 100, false],
    [5,5]   => [  2,   3,   4, false],
    [5]     => [  1,   2,   3, false],
  }
  #--------------------------------------------------------------------------
  # ◇ 画像の位置
  #--------------------------------------------------------------------------
  POS_REEL = [64, 160, 16]    # リールの位置
  POS_BET  = [254, 357, 1]    # 賭け数の位置
  POS_COIN = [278, 357, 6]    # コイン数の位置
  #--------------------------------------------------------------------------
  # ◇ リールの回転速度
  #--------------------------------------------------------------------------
  SPIN_SPEED = 24
  #--------------------------------------------------------------------------
  # ◇ 最大スリップ数
  #--------------------------------------------------------------------------
  MAX_SLIP = 0
  #--------------------------------------------------------------------------
  # ◇ 効果音
  #--------------------------------------------------------------------------
  SOUND_SPIN = RPG::SE.new("Evasion", 80)
#~     SOUND_SPIN = RPG::SE.new("Saint5", 80)
  SOUND_STOP = RPG::SE.new("Knock", 80)
#~     SOUND_STOP = RPG::SE.new("Shot2", 80)
  SOUND_WIN = RPG::SE.new("Flash2", 80)
#~     SOUND_WIN = RPG::SE.new("Saint9", 80)

end # module Slot
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::Slot
  #--------------------------------------------------------------------------
  # ● 正規表現
  #--------------------------------------------------------------------------
#~   REGEXP_START = /^<START_SLOT>\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/i
  REGEXP_START = /^スロット開始：\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/i
  #--------------------------------------------------------------------------
  # ● コインの枚数を取得
  #--------------------------------------------------------------------------
  def self.coin
    $game_variables[VAR_ID_COIN]
  end
  #--------------------------------------------------------------------------
  # ● コインの枚数を設定
  #--------------------------------------------------------------------------
  def self.coin=(value)
    $game_variables[VAR_ID_COIN] = value
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_slot_command_118 command_118
  def command_118
    if @params[0][CAO::Slot::REGEXP_START]
      $game_temp.slot_reel = [$1.to_i, $2.to_i, $3.to_i]
      $game_temp.next_scene = "slot"
      return true
    end
    return _cao_slot_command_118
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_slot_update_scene_change update_scene_change
  def update_scene_change
    return if $game_player.moving?    # プレイヤーの移動中？
    if $game_temp.next_scene == "slot"
      $game_temp.next_scene = nil
      $scene = Scene_Slot.new
    else
      _cao_slot_update_scene_change
    end
  end
end

class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :slot_reel                # スロット リール配列
end

class Sprite_SlotNumber < Sprite
  attr_reader :number, :digits
  #--------------------------------------------------------------------------
  # ● オブジェクトの初期化
  #--------------------------------------------------------------------------
  def initialize(x, y, digits)
    @bmp_number = Cache.system("SlotNumber")
    @csize = Rect.new(0, 0, @bmp_number.width / 10, @bmp_number.height)
    @number = 0
    super()
    self.x = x
    self.y = y
    self.digits = digits
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.bitmap.clear
    sprintf("%0#{@digits}d", @number).split(//).each_with_index do |c,i|
      @csize.x = @csize.width * c.to_i
      self.bitmap.blt(@csize.width * i, 0, @bmp_number, @csize)
    end
  end
  #--------------------------------------------------------------------------
  # ● 桁数数の設定
  #--------------------------------------------------------------------------
  def digits=(value)
    return if @digits == value
    @digits = [1, value].max
    self.bitmap.dispose if self.bitmap
    self.bitmap = Bitmap.new(@csize.width * @digits, @csize.height)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 数値の設定
  #--------------------------------------------------------------------------
  def number=(value)
    return if @number == value
    @number = [0, [value, 10 ** @digits - 1].min].max
    refresh
  end
end

class Sprite_Reel < Sprite
  attr_accessor :speed
  #--------------------------------------------------------------------------
  # ● オブジェクトの初期化
  #--------------------------------------------------------------------------
  def initialize(x, y, reel)
    @items = reel
    @item_max = reel.size
    super()
    self.x = x
    self.y = y
    create_reel
    ready
  end
  #--------------------------------------------------------------------------
  # ● リール画像の生成
  #--------------------------------------------------------------------------
  def create_reel
    img_symbol = Cache.system("SlotSymbol")
    @width = img_symbol.width / 2       # シンボルの横幅
    @height = img_symbol.height / 3     # シンボルの縦幅
    self.bitmap = Bitmap.new(@width, @height * (@item_max + 3))
    # 背景色の描画
    self.bitmap.fill_rect(self.bitmap.rect, Color.new(255, 255, 255))
    # シンボルの描画
    rect = Rect.new(0, 0, @width, @height)
    for i in 0...@item_max
      rect.x = @items[i] % 2 * @width
      rect.y = @items[i] / 2 * @height
      self.bitmap.blt(0, (@item_max + 2 - i) * @height, img_symbol, rect)
    end
    for i in 0...3
      rect.x = @items[i] % 2 * @width
      rect.y = @items[i] / 2 * @height
      self.bitmap.blt(0, (2 - i) * @height, img_symbol, rect)
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    last_index = self.index
    unless @stop
      self.oy -= @speed
      self.oy += @height * @item_max if self.oy < 0
    end
    if self.index != last_index
      if @need_stop
        if @slip != 0
          @slip -= 1
          @speed -= @slowdown
        else
          self.oy = self.index * @height
          @stop = true
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def index
    return self.oy / @height % @item_max + 1
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def symbol
    return @items[(@item_max - self.oy / @height + 1) % @item_max]
  end
  #--------------------------------------------------------------------------
  # ● 回転開始
  #--------------------------------------------------------------------------
  def start
    @stop = false
    @need_stop = false
    @speed = CAO::Slot::SPIN_SPEED
  end
  #--------------------------------------------------------------------------
  # ● 回転停止
  #--------------------------------------------------------------------------
  def stop
    @need_stop = true
    if CAO::Slot::MAX_SLIP <= 0
      @slip = 0
    else
      @slip = rand(CAO::Slot::MAX_SLIP) + 1
      @slowdown = CAO::Slot::SPIN_SPEED / (@slip + 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 回転準備
  #--------------------------------------------------------------------------
  def ready
    @stop = true
    @need_stop = false
    self.oy = @height
  end
  #--------------------------------------------------------------------------
  # ● 回転中判定
  #--------------------------------------------------------------------------
  def rolling?
    return false if @stop || @need_stop
    return true
  end
  #--------------------------------------------------------------------------
  # ● 停止判定
  #--------------------------------------------------------------------------
  def stop?
    return @stop
  end
end

class Spriteset_Reel
  include CAO::Slot
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  attr_accessor :active
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def initialize
    x = CAO::Slot::POS_REEL[0]
    y = CAO::Slot::POS_REEL[1]
    w = Cache.system("SlotSymbol").width / 2 + CAO::Slot::POS_REEL[2]
    @reel_sprite = []
    @reel_sprite << Sprite_Reel.new(x, y, SYMBOL[$game_temp.slot_reel[0]])
    @reel_sprite << Sprite_Reel.new(x+w, y, SYMBOL[$game_temp.slot_reel[1]])
    @reel_sprite << Sprite_Reel.new(x+w*2, y, SYMBOL[$game_temp.slot_reel[2]])
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    @reel_sprite.each {|reel| reel.dispose }
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    @reel_sprite.each {|reel| reel.update }
    if self.active && Input.trigger?(Input::C)
      for reel in @reel_sprite
        next unless reel.rolling?
        SOUND_STOP.play
        reel.stop
        break
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def symbols
    return @reel_sprite.map {|reel| reel.symbol }
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def odds
    table_reel = self.symbols.sort
    # ３つ揃った
    odds ||= CAO::Slot::WINTABLE[table_reel]
    # ２つ揃った
    odds ||= CAO::Slot::WINTABLE[table_reel[0..1]]
    odds ||= CAO::Slot::WINTABLE[table_reel[1..2]]
    # １つ揃った
    odds ||= CAO::Slot::WINTABLE[[table_reel[0]]]
    odds ||= CAO::Slot::WINTABLE[[table_reel[1]]]
    odds ||= CAO::Slot::WINTABLE[[table_reel[2]]]
    return odds
  end
  #--------------------------------------------------------------------------
  # ● 回転開始
  #--------------------------------------------------------------------------
  def start
    self.active = true
    @reel_sprite.each {|reel| reel.start }
  end
  #--------------------------------------------------------------------------
  # ● 回転準備
  #--------------------------------------------------------------------------
  def ready
    @reel_sprite.each {|reel| reel.ready }
  end
  #--------------------------------------------------------------------------
  # ● 停止判定
  #--------------------------------------------------------------------------
  def stop?
    return @reel_sprite.all? {|reel| reel.stop? }
  end
end

class Scene_Slot < Scene_Base
  include CAO::Slot
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  PROCESS_BET    = 0
  PROCESS_STOP   = 1
  PROCESS_ODDS   = 2
  PROCESS_REPLAY = 3
  PROCESS_WAIT   = 40
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    @spriteset = Spriteset_Reel.new
    
    @frame_sprite = Sprite.new
    @frame_sprite.bitmap = Cache.system("SlotFrame")
    @frame_sprite.z = 10
    
    @bet_sprite = Sprite_SlotNumber.new(*POS_BET)
    @bet_sprite.z = 10
    @coin_sprite = Sprite_SlotNumber.new(*POS_COIN)
    @coin_sprite.z = 10
    
    @process = PROCESS_BET
    @bet_sprite.number = 0
    @coin_sprite.number = CAO::Slot.coin
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  def terminate
    @spriteset.dispose
    @frame_sprite.dispose
    @bet_sprite.dispose
    @coin_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ● 元の画面へ戻る
  #--------------------------------------------------------------------------
  def return_scene
    CAO::Slot.coin = @coin_sprite.number
    $scene = Scene_Map.new
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    @spriteset.update
    @frame_sprite.update
    @bet_sprite.update
    @coin_sprite.update
    case @process
    when PROCESS_BET
      update_bet_input
    when PROCESS_STOP
      if @spriteset.stop?
        @spriteset.active = false
        @process = PROCESS_ODDS
      end
    when PROCESS_ODDS
      odds = @spriteset.odds
      # 支払い
      if odds
        SOUND_WIN.play
        @coin_sprite.number += odds[@bet_sprite.number - 1]
      end
      # Replay
      if odds && odds[3]
        @process = PROCESS_REPLAY
      else
        @bet_sprite.number = 0
        @process = PROCESS_BET
      end
    when PROCESS_WAIT
      start_spin
    else
      @process += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_bet_input
    if Input.trigger?(Input::B)
#~       Sound.play_cancel
      return_scene
    elsif Input.trigger?(Input::C)
      bet_one
    elsif Input.trigger?(Input::A)
      bet_max
    elsif Input.trigger?(Input::DOWN)
      start_spin
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def bet_one
    return unless @bet_sprite.number < 3
    if BET_ONE * (@bet_sprite.number + 1) <= @coin_sprite.number
      Sound.play_decision
      @bet_sprite.number += 1
    else
      Sound.play_buzzer
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def bet_max
    return unless @bet_sprite.number < 3
    if BET_ONE * 3 <= @coin_sprite.number
      Sound.play_decision
      @bet_sprite.number = 3
    else
      Sound.play_buzzer
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def start_spin
    return if @bet_sprite.number == 0
    SOUND_SPIN.play
    @coin_sprite.number -= BET_ONE * @bet_sprite.number
    @spriteset.start
    @spriteset.active = true
    @process = PROCESS_STOP
  end
end
