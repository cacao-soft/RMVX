#=============================================================================
#  [RGSS2] 文字装飾 - v1.0.4
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

  - 描画文字に、縁取り・ネオン・グラデーション効果を追加します。
  - 影の色を変更する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 組み込みクラス Bitmap#draw_text を再定義しています。
  ※ 装飾文字の描画には、通常の倍ほどの時間が掛かります。

 -- 使用方法 ----------------------------------------------------------------

  ★ すべての描画方法を変更
   下記の設定項目『装飾文字のタイプ(DECORATE_TYPE)』を変更してください。

  ★ 個別に描画
   Bitmap#draw_border_text   : 縁取り文字の描画
   Bitmap#draw_neon_text     : ネオン文字の描画
   Bitmap#draw_gradient_text : グラデーション文字の描画
   Bitmap#draw_shadow_text   : 影付き文字の描画
   ※ 引数は、draw_text と同じです。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
module BM
  #--------------------------------------------------------------------------
  # ◇ 装飾文字のタイプ
  #--------------------------------------------------------------------------
  #     0 .. 装飾なし        (処理速度にデフォルトとの差はありません)
  #     1 .. 縁取り          (およそ 2.0 ～ 2.2 倍ほどの時間が掛かります)
  #     2 .. ネオン          (およそ 2.8 ～ 3.0 倍ほどの時間が掛かります)
  #     3 .. グラデーション  (およそ 2.0 倍ほどの時間が掛かります)
  #     4 .. 影付き          (およそ 2.0 倍ほどの時間が掛かります)
  #--------------------------------------------------------------------------
  DECORATE_TYPE = 1

  #--------------------------------------------------------------------------
  # ◇ 装飾カラー
  #--------------------------------------------------------------------------
  #     nil                .. 自動設定 (文字の色より暗い色を使用します。)
  #     [red, green, blue] .. 装飾色を固定 (例、[0,0,0] で黒で固定)
  #--------------------------------------------------------------------------
  DECORATE_COLOR = nil

  #--------------------------------------------------------------------------
  # ◇ 縁取りの太さ
  #--------------------------------------------------------------------------
  #     1 .. 細い縁取り
  #     2 .. 太い縁取り
  #--------------------------------------------------------------------------
  BORDER_SIZE = 2

  #--------------------------------------------------------------------------
  # ◇ 縁取りの濃さを半分にする
  #--------------------------------------------------------------------------
  BORDER_HALF = false

  #--------------------------------------------------------------------------
  # ◇ 光の大きさ
  #--------------------------------------------------------------------------
  #     0 .. ほのかな光
  #     1 .. はっきりとした光
  #     2 .. 助長なかがやき
  #--------------------------------------------------------------------------
  NEON_SIZE = 0

  #--------------------------------------------------------------------------
  # ◇ グラデーションの太さ
  #--------------------------------------------------------------------------
  #     色の変化を px で設定します。
  #     1だとデフォルトで24色、2だと12色、4だと6色というように変化します。
  #--------------------------------------------------------------------------
  GRADIENT_SIZE = 2

  #--------------------------------------------------------------------------
  # ◇ 影の色
  #--------------------------------------------------------------------------
  #     nil                .. 自動設定 (文字の色を半透明で表示します。)
  #     [red, green, blue] .. 影の色を固定 (例、[0,0,0,128] で半透明な黒)
  #--------------------------------------------------------------------------
  SHADOW_COLOR = nil

  #--------------------------------------------------------------------------
  # ◇ 位置補正
  #--------------------------------------------------------------------------
  #     [x, y] の配列で設定します。
  #     設定された値だけ描画位置をずらします。
  #     ※ 通常の描画(draw_text)には適用されません。
  #--------------------------------------------------------------------------
  POSITION = [0, 1]

end
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Bitmap
  #--------------------------------------------------------------------------
  # ● 別名定義
  #--------------------------------------------------------------------------
  alias _cao_draw_text_bitmap draw_text unless $!
  #--------------------------------------------------------------------------
  # 〇 新 draw_text
  #--------------------------------------------------------------------------
  def draw_text(*args)
    # 描画処理の分岐
    case CAO::BM::DECORATE_TYPE
    when 1
      draw_border(*convert_args(args))
    when 2
      draw_neon(*convert_args(args))
    when 3
      draw_gradient(*convert_args(args))
    when 4
      draw_shadow(*convert_args(args))
    else
      _cao_draw_text_bitmap(*convert_args(args))
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_border_text(*args)
    draw_border(*convert_args(args))
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_neon_text(*args)
    draw_neon(*convert_args(args))
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_gradient_text(*args)
    draw_gradient(*convert_args(args))
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_shadow_text(*args)
    draw_shadow(*convert_args(args))
  end
  #--------------------------------------------------------------------------
  # ● 引数を個々に変換
  #--------------------------------------------------------------------------
  def convert_args(args)
    # 引数のパターンをチェック
    case args.size
    when 2, 3
      if Rect === args[0]
        x,y,width,height = args[0].x,args[0].y,args[0].width,args[0].height
        text, align = args[1], (args[2] ? args[2] : 0)
      else
        msg = "cannot convert #{args[0].class} into Rect"
        raise TypeError, msg, caller(2)
      end
    when 5, 6
      x, y, width, height = *args
      text, align = args[4], (args[5] ? args[5] : 0)
    else
      msg = "wrong number of argsuments (#{args.size} for 5)"
      raise ArgumentError, msg, caller(2)
    end
    for param in [x, y, width, height, align]
      unless Integer === param
        msg = "cannot convert #{param.class} into Integer"
        raise TypeError, msg, caller(4)
      end
    end
    text = text.inspect unless String === text
    # 描画位置の補正
    x += CAO::BM::POSITION[0]
    y += CAO::BM::POSITION[1]
    return x, y, width, height, text, align
  end
  #--------------------------------------------------------------------------
  # ● ダミー文字の生成
  #--------------------------------------------------------------------------
  def dummy_text(x, y, width, height, text, align)
    b = Bitmap.new(width, height)
    b.font = self.font.dup
    b.font.shadow = false
    b._cao_draw_text_bitmap(x, y, width, height, text, align)
    return b
  end
  #--------------------------------------------------------------------------
  # ● 縁取り文字の描画
  #--------------------------------------------------------------------------
  def draw_border(x, y, width, height, text, align)
    # 縁取りの色
    draw_color = self.font.color.dup
    if CAO::BM::DECORATE_COLOR
      self.font.color.set(*CAO::BM::DECORATE_COLOR)
    else
      self.font.color.red /= 3
      self.font.color.green /= 3
      self.font.color.blue /= 3
    end
    # 縁取り
    b = dummy_text(0, 0, width, height, text, align)
    alpha = CAO::BM::BORDER_HALF ? 128 : 255
    case CAO::BM::BORDER_SIZE
    when 1  # 1px
      self.blt(x, y - 1, b, b.rect, alpha)
      self.blt(x, y + 1, b, b.rect, alpha)
      self.blt(x - 1, y, b, b.rect, alpha)
      self.blt(x + 1, y, b, b.rect, alpha)
    when 2  # 2px
      self.blt(x, y - 2, b, b.rect, alpha)
      self.blt(x, y + 2, b, b.rect, alpha)
      self.blt(x - 2, y, b, b.rect, alpha)
      self.blt(x + 2, y, b, b.rect, alpha)
      self.blt(x - 1, y - 2, b, b.rect, alpha)
      self.blt(x + 1, y - 2, b, b.rect, alpha)
      self.blt(x - 1, y + 2, b, b.rect, alpha)
      self.blt(x + 1, y + 2, b, b.rect, alpha)
      self.blt(x - 2, y - 1, b, b.rect, alpha)
      self.blt(x - 2, y + 1, b, b.rect, alpha)
      self.blt(x + 2, y - 1, b, b.rect, alpha)
      self.blt(x + 2, y + 1, b, b.rect, alpha)
    end
    # 文字を描画
    self.font.color = draw_color
    self.font.shadow = false
    _cao_draw_text_bitmap(x, y, width, height, text, align)
    # Bitmap の解放
    b.dispose
  end
  #--------------------------------------------------------------------------
  # ● ネオン文字の描画
  #--------------------------------------------------------------------------
  def draw_neon(x, y, width, height, text, align)
    # 縁取りの色
    draw_color = self.font.color.dup
    self.font.color.alpha /= 3
    # 縁取り
    b = dummy_text(0, 0, width, height, text, align)
    bb = Bitmap.new(width + 16, height + 16)
    case CAO::BM::NEON_SIZE
    when 0  # 0px
      bb.blt(8, 8, b, b.rect)
    when 1  # 1px
      bb.blt(8, 9, b, b.rect)
      bb.blt(9, 8, b, b.rect)
      bb.blt(7, 8, b, b.rect)
      bb.blt(8, 7, b, b.rect)
    when 2  # 2px
      bb.blt(7, 6, b, b.rect)
      bb.blt(9, 6, b, b.rect)
      bb.blt(7,10, b, b.rect)
      bb.blt(9,10, b, b.rect)
      bb.blt(6, 7, b, b.rect)
      bb.blt(6, 9, b, b.rect)
      bb.blt(10,7, b, b.rect)
      bb.blt(10,9, b, b.rect)
    end
    bb.blur
    self.blt(x - 8, y - 8, bb, bb.rect)
    self.font.color = draw_color
    self.font.shadow = false
    _cao_draw_text_bitmap(x, y, width, height, text, align)
    # Bitmap の解放
    b.dispose
    bb.dispose
  end
  #--------------------------------------------------------------------------
  # ● グラデーション文字
  #--------------------------------------------------------------------------
  def draw_gradient(x, y, width, height, text, align)
    # 上塗り画像
    b = dummy_text(0, 0, width, height, text, align)
    # 下文字
    draw_color = self.font.color.dup
    self.font.color.set(255, 255, 255, self.font.color.alpha)
    _cao_draw_text_bitmap(x, y, width, height, text, align)
    self.font.color = draw_color
    # グラデ開始
    ac = self.font.color.alpha / (height / CAO::BM::GRADIENT_SIZE)
    h = height / CAO::BM::GRADIENT_SIZE
    op = 0
    lr = Rect.new(0, 0, width, CAO::BM::GRADIENT_SIZE)
    for i in 0...h
      lr.y = i * CAO::BM::GRADIENT_SIZE
      self.blt(x, y + i * CAO::BM::GRADIENT_SIZE, b, lr, op)
      op = [op + ac, self.font.color.alpha].min
    end
  end
  #--------------------------------------------------------------------------
  # ● 影付き文字
  #--------------------------------------------------------------------------
  def draw_shadow(x, y, width, height, text, align)
    last_color = self.font.color.dup
    if CAO::BM::SHADOW_COLOR
      self.font.color.set(*CAO::BM::SHADOW_COLOR)
    else
      self.font.color.alpha = 128
    end
    self.font.shadow = false
    _cao_draw_text_bitmap(x + 1, y + 1, width, height, text, align)
    self.font.color = last_color.dup
    self.font.shadow = false
    _cao_draw_text_bitmap(x, y, width, height, text, align)
    self.font.color = last_color
  end
end
