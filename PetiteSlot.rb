#=============================================================================
#  [RGSS2] プチスロット - v1.0.2
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

  プチゲーム「スロット」の機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、割り込みシーン が必要です。
  ※ このスクリプトは、必要最低限の機能で構成されています。
     イベントコマンドを使用して自由に処理を追加することが出来ます。

 -- 画像規格 ----------------------------------------------------------------

  ★ スロットのマーク
   96 x 48 の画像（PSlotSymbol）を "Graphics/System" にご用意ください。
   絵柄が揃わなかった場合は、-1 が、
   揃った場合は、シンボルのインデックス番号（0~）が格納されます。
   画像を使用する場合は、マークの数に制限はありません。たぶん・・・。
   ※ 数を増やす場合は、縦方向に列を増やしていってください。(96x72,96x96...)

 -- 使用方法 ----------------------------------------------------------------

  ★ スロットを始める。
   イベントコマンドのスクリプトに"プチスロット開始"と記述してください。
   ※ 引数で詳細指定できます。"プチスロット開始(パターン, スピード)"

  ★ ゲーム結果を受け取る
   ゲーム結果は、下記で設定した変数に格納されています。
   絵柄が揃わなかった場合は、-1 が、揃った場合は、
   シンボルのインデックス番号が格納されます。
   ※ 変数の値は、スロット開始時に -1 で初期化されます。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================

module CAO_PSLOT
  #--------------------------------------------------------------------------
  # ◇ ゲーム結果を格納する変数番号
  #--------------------------------------------------------------------------
  VAR_RESULT = 1
  #--------------------------------------------------------------------------
  # ◇ 画像を使用しない
  #--------------------------------------------------------------------------
  NO_GRAPHICS = true
  #--------------------------------------------------------------------------
  # ◇ 画像を使用しない場合のシンボル（８個）
  #--------------------------------------------------------------------------
  IMG_SYMBOL = ["７", "＠", "ω", "＊", "●", "◆", "▲", "★"]
  #--------------------------------------------------------------------------
  # ◇ 画像の順番（ハッシュ）
  #--------------------------------------------------------------------------
  SYMBOL_PATA = {
    # 0 の key は変更しないでください。引数省略時に使用されます。
    0 => [ # 初期設定
      [0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 7, 7],
      [3, 2, 0, 1, 1, 5, 4, 3, 2, 6, 7, 7],
      [5, 4, 1, 6, 0, 3, 7, 2, 3, 4, 1, 7]
    ],
    # 下記からは、お好きな key で設定可能です。
    1 => [
      [0, 1, 5, 6, 7, 1, 4],
      [7, 6, 0, 1, 5, 3, 2],
      [3, 5, 7, 6, 4, 7, 1]
    ]
  }
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Interpreter
  def プチスロット開始(pata = 0, speed = 2)
    Scene_PSlot.new(pata, speed)
  end
end

class Window_PSlot < Window_Base
  include CAO_PSLOT
  def initialize(pata, speed)
    x = [[$game_player.screen_x - 52, 0].max, 440].min
    y = $game_player.screen_y + ($game_player.screen_y < 64 ? 4 : -92)
    super(x, y, 104, 56)
    @pata = pata
    @speed = speed
    @stop_spin = 0
    @wait = 0
    create_slot_symbol
  end
  def dispose
    @symbol_sprite[0].dispose
    @symbol_sprite[1].dispose
    @symbol_sprite[2].dispose
    super
  end
  def create_slot_symbol
    symbol_max = SYMBOL_PATA[@pata][0].size
    viewport = Viewport.new(self.x + 16, self.y + 16, 72, 24)
    @symbol_sprite = []
    @symbol_sprite[0] = Sprite.new(viewport)
    @symbol_sprite[1] = Sprite.new(viewport)
    @symbol_sprite[2] = Sprite.new(viewport)
    for i in 0...3
      @symbol_sprite[i].x = 24 * i
      @symbol_sprite[i].oy = 24 * symbol_max
      @symbol_sprite[i].viewport.z = 130
    end
    bitmap = create_bitmap_symbol
    for n in 0...3
      @symbol_sprite[n].bitmap = Bitmap.new(24, 24 * (symbol_max + 1))
      rect = Rect.new(0, 0, 24, 24)
      for i in 0...symbol_max
        rect.x = SYMBOL_PATA[@pata][n][i] % 4 * 24
        rect.y = SYMBOL_PATA[@pata][n][i] / 4 * 24
        y = @symbol_sprite[n].bitmap.height - (i * 24) - 24
        @symbol_sprite[n].bitmap.blt(0, y, bitmap, rect)
      end
      rect.x = SYMBOL_PATA[@pata][n][0] % 4 * 24
      rect.y = SYMBOL_PATA[@pata][n][0] / 4 * 24
      @symbol_sprite[n].bitmap.blt(0, 0, bitmap, rect)
    end
  end
  def create_bitmap_symbol
    if NO_GRAPHICS
      bitmap = Bitmap.new(96, 48)
      for y in 0...2
        for x in 0...4
          bitmap.draw_text(24 * x, 24 * y, 24, 24, IMG_SYMBOL[x + 4 * y], 1)
        end
      end
      return bitmap
    else
      return Cache.system("PSlotSymbol")
    end
  end
  def update
    for i in 0...3
      next if @stop_spin > i && @symbol_sprite[i].oy % 24 == 0
      if @symbol_sprite[i].oy == 0
        symbol_height = 24 * (SYMBOL_PATA[@pata][0].size)
        @symbol_sprite[i].oy = symbol_height - @speed
      else
        @symbol_sprite[i].oy -= @speed
      end
    end
  end
  def check_symbol
    num = []
    for i in 0...3
      num[i] = SYMBOL_PATA[@pata][0].size - @symbol_sprite[i].oy / 24
      num[i] = 0 if num[i] == SYMBOL_PATA[@pata][0].size
    end
    return -1 if SYMBOL_PATA[@pata][0][num[0]] != SYMBOL_PATA[@pata][1][num[1]]
    return -1 if SYMBOL_PATA[@pata][0][num[0]] != SYMBOL_PATA[@pata][2][num[2]]
    return SYMBOL_PATA[@pata][0][num[0]]
  end
  def check_oy
    return @symbol_sprite[2].oy % 24 == 0
  end
  def stop_spin
    @stop_spin += 1
  end
end

class Scene_PSlot < Scene_Interrupt
  def initialize(pata, speed)
    @pata = pata
    @speed = speed
    super()
  end
  def start
    super
    $game_variables[CAO_PSLOT::VAR_RESULT] = -1
    @slot_window = Window_PSlot.new(@pata, @speed)
    @line = 0
  end
  def terminate
    super
    @slot_window.dispose
  end
  def update
    super
    @slot_window.update
    update_input
  end
  def update_input
    if Input.trigger?(Input::C) && @line < 3
      Sound.play_decision
      @slot_window.stop_spin
      @line += 1
    elsif @line == 3 && @slot_window.check_oy
      Graphics.wait(20)
      $game_variables[CAO_PSLOT::VAR_RESULT] = @slot_window.check_symbol
      @exit = true
    end
  end
end
