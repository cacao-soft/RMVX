#=============================================================================
#  [RGSS2] Bitmap Class EX - v1.1.3
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

  Bitmap クラスに BMP,PNG 画像の出力機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 他のＣＡＣＡＯ製スクリプトより上に配置してください。
  ※ Cacao Base Script がある場合は、その下に設置してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ Bitmap#save_bitmap(filename)
   このビットマップをビットマップファイルで出力
   filename : 保存するファイル名
  ★ Bitmap#save_png(filename, alpha = false)
   このビットマップをピングファイルで出力
   filename : 保存するファイル名
   alpha    : αチャンネルの有無
  ★ Bitmap#save_png_g(filename, alpha = false)
   このビットマップをピングファイル(グレースケール)で出力
   filename : 保存するファイル名
   alpha    : αチャンネルの有無
  ★ Bitmap#draw_pixel(x, y, color)
   このビットマップに点を描画します。
   
  ★ Bitmap#draw_rect(x, y, width, height, color)
     Bitmap#draw_rect(rect, color)
   このビットマップに矩形(単色)を描画します。
  ★ Bitmap#draw_line_rect(x, y, width, height, color[, border])
     Bitmap#draw_line_rect(rect, color[, border])
   このビットマップに矩形(枠)を描画します。
   border : 枠の太さ (省略時、1)
  ★ Bitmap#draw_gradient_rect(x, y, width, height, gc1, gc2[, vertical])
     Bitmap#draw_gradient_rect(rect, gc1, gc2[, vertical])
   このビットマップに矩形(グラデーション)を描画します。
  ★ Bitmap#draw_window(x, y, width, height[, windowskin[, opacity]])
     Bitmap#draw_window([rect][, windowskin[, opacity]])
   このビットマップにウィンドウを描画します。
   x,y,width,height,rect : ウィンドウの位置とサイズ (省略時、最大サイズ)
   windowskin : スキン名、スキン画像 (省略時、スキン名(Window))
   opacity    : ウィンドウの不透明度 (省略時、200)

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Bitmap
  #--------------------------------------------------------------------------
  # ● ビットマップ画像として保存
  #     filename : ファイル名
  #--------------------------------------------------------------------------
  def save_bitmap(filename)
    bw = self.width
    bh = self.height
    gw = (bw % 4 == 0) ? bw : bw + 4 - bw % 4
    # ファイルヘッダ
    head = ['BM', gw * bh * 3, 0, 0, 54].pack('A2LS2L')
    # 情報ヘッダ
    info = [40, bw, bh, 1, 24, 0, 0, 0, 0, 0, 0].pack('L3S2L6')
    # 画像データ
    data = []
    for y in 0...bh
      for x in 0...gw
        color = self.get_pixel(x, (bh - 1) - y)
        data.push(color.blue)
        data.push(color.green)
        data.push(color.red)
      end
    end
    data = data.pack('C*')
    # ファイルに書き出す
    File.open(filename, 'wb') do |file|
      file.write(head)
      file.write(info)
      file.write(data)
    end
  end
  #--------------------------------------------------------------------------
  # ● ピング画像として保存
  #     filename : ファイル名
  #     alpha    : アルファチャンネルの有無
  #--------------------------------------------------------------------------
  def save_png(filename, alpha = false)
    # 識別
    sgnt = "\x89PNG\r\n\x1a\n"
    # ヘッダ
    ihdr = chunk('IHDR', [width,height,8,(alpha ? 6 : 2),0,0,0].pack('N2C5'))
    # 画像データ
    data = []
    for y in 0...height
      data.push(0)
      for x in 0...width
        color = self.get_pixel(x, y)
        data.push(color.red)
        data.push(color.green)
        data.push(color.blue)
        data.push(color.alpha) if alpha
      end
    end
    idat = chunk('IDAT', Zlib::Deflate.deflate(data.pack('C*')))
    # 終端
    iend = chunk('IEND', "")
    # ファイルに書き出す
    File.open(filename, 'wb') do |file|
      file.write(sgnt)
      file.write(ihdr)
      file.write(idat)
      file.write(iend)
    end
  end
  #--------------------------------------------------------------------------
  # ● グレースケールのピング画像として保存 (NTSC 加重平均法)
  #     filename : ファイル名
  #     alpha    : アルファチャンネルの有無
  #--------------------------------------------------------------------------
  def save_png_g(filename, alpha = false)
    # 識別
    sgnt = "\x89PNG\r\n\x1a\n"
    # ヘッダ
    ihdr = chunk('IHDR', [width,height,8,(alpha ? 4 : 0),0,0,0].pack('N2C5'))
    # 画像データ
    data = []
    for y in 0...height
      data.push(0)
      for x in 0...width
        color = self.get_pixel(x, y)
        gray = (color.red * 3 + color.green * 6 + color.blue) / 10
        data.push(gray)
        data.push(color.alpha) if alpha
      end
    end
    idat = chunk('IDAT', Zlib::Deflate.deflate(data.pack('C*')))
    # 終端
    iend = chunk('IEND', "")
    # ファイルに書き出す
    File.open(filename, 'wb') do |file|
      file.write(sgnt)
      file.write(ihdr)
      file.write(idat)
      file.write(iend)
    end
  end
  
  private
  #--------------------------------------------------------------------------
  # ● チャンクの作成
  #     name : チャンク名
  #     data : チャンクデータ
  #--------------------------------------------------------------------------
  def chunk(name, data)
    return [data.size, name, data, Zlib.crc32(name + data)].pack('NA4A*N')
  end
end

class Bitmap
  #--------------------------------------------------------------------------
  # ● ウィンドウの描画
  #     x, y, width, height, windowskin = nil, opacity = 200
  #     rect, windowskin = nil, opacity = 200
  #     windowskin = nil, opacity = 200
  #--------------------------------------------------------------------------
  #     windowskin : (nil)    デフォルトのスキン画像を使用 ("Window")
  #                : (String) スキン画像のファイル名 (Graphics/System 内のもの)
  #                : (Bitmap) スキン画像
  #--------------------------------------------------------------------------
  def draw_window(*args)
    # == 引数のチェック(例外処理) ==
    case args[0]
    when nil
      x, y, width, height = 0, 0, self.width, self.height
      bmp_skin = skin_to_bitmap(nil)
      opacity = 200
    when Rect           # rect, skin, opacity
      err_size(1, 3, args.size)
      x, y, width, height = args[0].x, args[0].y, args[0].width, args[0].height
      bmp_skin = skin_to_bitmap(args[1])
      opacity = (args[2] || 200); err_type(opacity, Fixnum)
    when String, Bitmap # skin, opacity
      err_size(1, 2, args.size)
      x, y, width, height = 0, 0, self.width, self.height
      bmp_skin = skin_to_bitmap(args[0])
      opacity = (args[1] || 200); err_type(opacity, Fixnum)
    else                # x, y, width, height, skin, opacity
      err_size(4, 6, args.size)
      err_type(args[0], Fixnum)
      err_type(args[1], Fixnum)
      err_type(args[2], Fixnum)
      err_type(args[3], Fixnum)
      x, y, width, height = args[0], args[1], args[2], args[3]
      bmp_skin = skin_to_bitmap(args[4])
      opacity = (args[5] || 200); err_type(opacity, Fixnum)
    end
    
    # == ウィンドウ画像の描画処理 ==
    buffer = Bitmap.new(width, height)
    # 背景の描画
    sr = Rect.new(0, 0, 64, 64)
    dr = Rect.new(2, 2, width-4, height-4)
    buffer.stretch_blt(dr, bmp_skin, sr)
    sr.set(0, 64, 64, 64)
    for i in 0...(width/64+1)
      for j in 0...(height/64+1)
        buffer.blt(i * 64 + 2, j * 64 + 2, bmp_skin, sr)
      end
    end
    buffer.clear_rect(width-2, 0, 2, height)
    buffer.clear_rect(0, height-2, width, 2)
    self.blt(x, y, buffer, buffer.rect, opacity)
    # フレームの描画
    buffer.clear
    for i in 0...((width-32)/32+1)
      sr.set(80, 0, 32, 16)   # 上
      buffer.blt(i*32+16, 0, bmp_skin, sr)
      sr.set(80, 48, 32, 16)  # 下
      buffer.blt(i*32+16, height-16, bmp_skin, sr)
    end
    for i in 0...((height-32)/32+1)
      sr.set(64, 16, 16, 32)  # 左
      buffer.blt(0, i*32+16, bmp_skin, sr)
      sr.set(112, 16, 16, 32) # 右
      buffer.blt(width-16, i*32+16, bmp_skin, sr)
    end
    buffer.clear_rect(width-16, 0, 16, 16)
    buffer.clear_rect(0, height-16, 16, 16)
    buffer.clear_rect(width-16, height-16, 16, 16)
    sr.set(0, 0, 16, 16)
    for i in 0...4
      sr.x = i % 2 * 48 + 64
      sr.y = i / 2 * 48
      buffer.blt(i % 2 * (width - 16), i / 2 * (height - 16), bmp_skin, sr)
    end
    self.blt(x, y, buffer, buffer.rect)
    # バッファの解放
    buffer.dispose
  end
  
  private
  # 引数の数を検査
  def err_size(min, max, size)
    return if (min..max) === size
    msg = "wrong number of arguments (#{size} for #{max})"
    raise ArgumentError, msg, caller(2).first
  end
  # 引数のタイプを検査
  def err_type(obj, expected)
    return if obj.is_a?(expected)
    msg = "wrong argument type #{obj.class} (expected #{expected})"
    raise TypeError, msg, caller(2).first
  end
  # ウィンドウスキン画像に変換
  def skin_to_bitmap(param)
    case param
    when nil
      return Cache.system("Window")
    when String
      return Cache.system(param)
    when Bitmap
      return param
    else
      msg = "wrong argument type #{param.class} (expected String)"
      raise TypeError, msg, caller(2).first
    end
  end
end

class Bitmap
  #--------------------------------------------------------------------------
  # ● 点の描画
  #--------------------------------------------------------------------------
  def draw_pixel(x, y, color)
    buffer = Bitmap.new(1, 1)
    buffer.set_pixel(0, 0, color)
    self.blt(x, y, buffer, buffer.rect)
    buffer.dispose
  rescue => error
    raise error.class, error.message, caller.first
  end
  #--------------------------------------------------------------------------
  # ● 矩形の描画 (塗り潰し)
  #     x, y, width, height, color
  #     rect, color
  #--------------------------------------------------------------------------
  def draw_rect(*args)
    if args.size == 2 && args.first.is_a?(Rect)
      x, y, width, height = args[0].x, args[0].y, args[0].width, args[0].height
      color = args[1]
    elsif args.size == 5
      x, y, width, height, color = args
    else
      msg = "wrong number of arguments (#{args.size} for 5)"
      raise ArgumentError, msg, caller.first
    end
    buffer = Bitmap.new(width, height)
    buffer.fill_rect(0, 0, width, height, color)
    self.blt(x, y, buffer, buffer.rect)
    buffer.dispose
  rescue RGSSError
  rescue ArgumentError, TypeError => error
    raise error.class, error.message, caller.first
  end
  #--------------------------------------------------------------------------
  # ● 矩形の描画 (枠)
  #     x, y, width, height, color[, border]
  #     rect, color[, border]
  #--------------------------------------------------------------------------
  #     border : 枠の太さ (省略時、1)
  #--------------------------------------------------------------------------
  def draw_line_rect(*args)
    if (2..3) === args.size && args.first.is_a?(Rect)
      x, y, width, height = args[0].x, args[0].y, args[0].width, args[0].height
      color, border = args[1], args[2]
    elsif (5..6) === args.size
      x, y, width, height, color, border = args
    else
      msg = "wrong number of arguments (#{args.size} for 6)"
      raise ArgumentError, msg, caller.first
    end
    border = (border ? Integer(border) : 1)
    buffer = Bitmap.new(width, height)
    buffer.fill_rect(0, 0, width, height, color)
    buffer.clear_rect(Rect.new(border,border,width-border*2,height-border*2))
    self.blt(x, y, buffer, buffer.rect)
    buffer.dispose
  rescue RGSSError
  rescue ArgumentError, TypeError => error
    raise error.class, error.message, caller.first
  end
  #--------------------------------------------------------------------------
  # ● 矩形の描画 (グラデーション)
  #     x, y, width, height, color1, color2[, vertical]
  #     rect, color1, color2[, vertical]
  #--------------------------------------------------------------------------
  #     vertical : true で、縦方向のグラデーション。(省略時、横方向)
  #--------------------------------------------------------------------------
  def draw_gradient_rect(*args)
    if (4..5) === args.size && args.first.is_a?(Rect)
      x, y, width, height = args[0].x, args[0].y, args[0].width, args[0].height
      color1, color2, vertical = args[1], args[2], args[3]
    elsif (6..7) === args.size
      x, y, width, height, color1, color2, vertical = args
    else
      msg = "wrong number of arguments (#{args.size} for 7)"
      raise ArgumentError, msg, caller.first
    end
    buffer = Bitmap.new(width, height)
    rect = Rect.new(0, 0, width, height)
    buffer.gradient_fill_rect(rect, color1, color2, vertical) 
    self.blt(x, y, buffer, buffer.rect)
    buffer.dispose
  rescue RGSSError
  rescue ArgumentError, TypeError => error
    raise error.class, error.message, caller.first
  end
end
