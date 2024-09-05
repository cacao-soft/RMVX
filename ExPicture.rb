#=============================================================================
#  [RGSS2] ＜拡張＞ ピクチャの操作 - v3.4.1
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

  ピクチャを操作する機能を追加します。
   - 反転、空画像生成、顔グラ・モングラなどの表示
   - 文字の描画、アイコンの描画、ウィンドウの描画

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、Cacao Base Script が必要です。
  ※ このスクリプトの実行には、Interpreter 108 EX が必要です。
  ※ このスクリプトの実行には、Bitmap Class EX が必要です。

 -- 使用方法 ----------------------------------------------------------------

  ★ ピクチャ全消去
   ラベルに "Ｐ全消去" と記述
   § screen.pictures[ピクチャ番号].mirror ^= true

  ★ ピクチャを反転する。
   ラベルに "Ｐ反転：ピクチャ番号" と記述
   § screen.pictures[ピクチャ番号].mirror ^= true

  ★ ピクチャを元の向きにする。
   ラベルに "Ｐ正向：ピクチャ番号" と記述
   § screen.pictures[ピクチャ番号].mirror = true

  ★ ピクチャを反対の向きする。
   ラベルに "Ｐ反向：ピクチャ番号" と記述
   § screen.pictures[ピクチャ番号].mirror = false

  ★ ピクチャの画像を更新する。
   ラベルに "Ｐ更新：ピクチャ番号" と記述
   § screen.pictures[ピクチャ番号].need_refresh = true

  ★ ウィンドウの生成
   ラベル「Ｗ表示：ピクチャ番号, (width, height)[, skin]」

  ★ ウィンドウの設定
   ラベル「Ｗ設定：ピクチャ番号, スキン, 背景不透明度」

  ★ 画像の生成
   ラベル「Ｐ画像：ピクチャ番号, (width, height)」

  ★ アイコンの描画
   ラベル「Ｉ描画：ピクチャ番号, (x, y), ○インデックス番号」
   ○：s,アイコンセット i,アイテム w,武器 a,防具

  ★ 画像ファイルの表示
   ラベル/注釈「Ｐ名前：ピクチャ番号, "識別名_ファイル名"[, オプション]」
   識  別  名：M:モングラ, A:歩行グラ, F:顔グラ, P:遠景, S:システム
   オプション：モングラの色調、歩行グラ・顔グラのインデックス
  ※ ホコグラは、正面のみ表示可能

  ★ 文字の描画
   注釈：１行目「Ｐ文字描画：ピクチャ番号[, align[, wlh]]」
   注釈：１行目「Ｐ文字描画：ピクチャ番号[, (x, y, width, wlh)[, align]]」
   注釈：以  降「表示する文章」
   注釈：以  降「[x, y, width, height, align]表示する文章」

   ▼ 制御文字
     \V[n]       : 変数
     \N[n]       : アクター名
     \C[n]       : 文字色
     \S[n]       : 文字サイズ（標準：20）
     \F[ ... ]   : sprintf フォーマット
     $[ ... ]$   : スクリプト

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
module Picture
  #--------------------------------------------------------------------------
  # ◇ ウィンドウピクチャのスキン画像
  #--------------------------------------------------------------------------
  WINDOW_SKIN = []  # この行は、削除・変更しないでください
  WINDOW_SKIN[0] = "Window"
  WINDOW_SKIN[1] = "Window02"
  WINDOW_SKIN[2] = "Window03"

  #--------------------------------------------------------------------------
  # ◇ フォント
  #--------------------------------------------------------------------------
  FONT_NAME = []    # この行は、削除・変更しないでください
  FONT_NAME[0] = Font.default_name
  FONT_NAME[1] = "ＭＳ 明朝"

  #--------------------------------------------------------------------------
  # ◇ 文字描画の余白
  #--------------------------------------------------------------------------
  #   文字ピクチャで描画位置など省略したときに四方に入る余白です。
  #--------------------------------------------------------------------------
  PADDING = 16
end
end # module::CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::Picture
module_function
  #--------------------------------------------------------------------------
  # ● 画面系コマンドの対象取得
  #--------------------------------------------------------------------------
  def screen
    if $game_temp.in_battle
      return $game_troop.screen
    else
      return $game_map.screen
    end
  end
  #--------------------------------------------------------------------------
  # ● 全ピクチャを消去
  #--------------------------------------------------------------------------
  def erase
    for picture in screen.pictures
      picture.erase
    end
  end
end

class Game_Picture
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :name                     # 名前
  attr_accessor :width                    # 横幅
  attr_accessor :height                   # 縦幅
  attr_accessor :data                     # データハッシュ
  attr_accessor :mirror                   # 反転
  attr_accessor :need_refresh             # リフレッシュ要求フラグ
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     number : ピクチャ番号
  #--------------------------------------------------------------------------
  alias _cao_initialize_pic initialize
  def initialize(number)
    _cao_initialize_pic(number)
    clear_picdata
  end
  #--------------------------------------------------------------------------
  # ○ ピクチャの表示
  #     name         : ファイル名
  #     origin       : 原点
  #     x            : X 座標
  #     y            : Y 座標
  #     zoom_x       : X 方向拡大率
  #     zoom_y       : Y 方向拡大率
  #     opacity      : 不透明度
  #     blend_type   : ブレンド方法
  #--------------------------------------------------------------------------
  alias _cao_show_pic show
  def show(name, origin, x, y, zoom_x, zoom_y, opacity, blend_type)
    _cao_show_pic(name, origin, x, y, zoom_x, zoom_y, opacity, blend_type)
    clear_picdata
  end
  #--------------------------------------------------------------------------
  # ● ピクチャのクリア
  #--------------------------------------------------------------------------
  def clear_picdata
    @mirror = false
    @width = 32
    @height = 32
    @data = {}
    @data[:type] = :file      # ピクチャのタイプ
    @data[:text] = []         # 描画文字の配列
    @data[:icon] = []         # アイコン描画の２次元配列 ([icon_index, x, y])
    @data[:rect] = nil        # 文字描画位置の２次元配列 ([x,y,width,wlh,align])
    @data[:skin] = "Window"   # ウィンドウピクチャのファイル名
    @data[:back] = 200        # ウィンドウピクチャの背景の不透明度
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def windowskin
    if @data[:skin].is_a?(String) && @data[:skin].match(/^\d+$/)
      return CAO::Picture::WINDOW_SKIN[@data[:skin].to_i]
    end
    return @data[:skin]
  end
  #--------------------------------------------------------------------------
  # ● 画像の判別
  #--------------------------------------------------------------------------
  def create_grapic
    case @data[:type]
    when :file
      case @name
      when /^"&M_(.+?)"(?:,\s?(\d+))?/
        bitmap = Cache.battler($1, $2 ? $2.to_i : 0)
      when /^"&A_(.+?)"(?:,\s?([0-7]))?/
        cw = Cache.character($1).width / ($2 ? 12 : 3)
        ch = Cache.character($1).height / ($2 ? 8 : 4)
        index = $2 ? $2.to_i : 0
        bitmap = Bitmap.new(cw, ch)
        src_rect = Rect.new((index%4*3+1)*cw, (index/4*4)*ch, cw, ch)
        bitmap.blt(0, 0, Cache.character($1), src_rect)
      when /^"&F_(.+?)",\s?([0-7])/
        bitmap = Bitmap.new(96, 96)
        src_rect = Rect.new($2.to_i % 4 * 96, $2.to_i / 4 * 96, 96, 96)
        bitmap.blt(0, 0, Cache.face($1), src_rect)
      when /^"&P_(.+)"/
        bitmap = Cache.parallax($1)
      when /^"&S_(.+)"/
        bitmap = Cache.system($1)
      else
        bitmap = Cache.picture(@name)
      end
    when :bitmap
      bitmap = Bitmap.new(@width, @height)
      refresh(bitmap)
    when :window
      bitmap = Bitmap.new(@width, @height)
      bitmap.draw_window(windowskin, @data[:back])
    end
    return bitmap
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh(bitmap)
    @under_line = []
    # アイコンの描画
    for i in 0...@data[:icon].size
      icon_index = @data[:icon][i][0]
      x, y = @data[:icon][i][1], @data[:icon][i][2]
      rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
      bitmap.blt(x, y, Cache.system("Iconset"), rect)
    end
    # 文字の描画位置
    for i in 0...@data[:text].size
      next if @data[:text][i] == nil
      text = @data[:text][i].clone
      # 制御文字の変換
      convert_special_characters(text)
      # 文字描画
      draw_text(bitmap, text, get_draw_position(bitmap, text, i))
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def get_draw_position(bitmap, text, index)
    if /\x00/ =~ text
      wlh = text.scan(/\x00\[([0-9]+)\]/).map{ |s| s[0].to_i }.max + 4
    else
      wlh = @data[:rect] ? @data[:rect][3] : 24
    end
    align = @data[:rect] ? @data[:rect][4] : 0
    re = /^\[(\d+)(?:,\s?(\d+)(?:,\s?(\d+)(?:,\s?(\d+)(?:,\s?(\d+))?)?)?)?\]/
    text.gsub!(re) { "" }
    if $5     # x, y, width, wlh, align
      rect = [$1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i]
    elsif $4
      rect = [$1.to_i, $2.to_i]
      if (0..2) === $4.to_i # x, y, wlh, align
        rect.push(bitmap.width - $1.to_i * 2, $3.to_i, $4.to_i)
      else                  # x, y, width, wlh
        rect.push($3.to_i, $4.to_i, align)
      end
    elsif $3
      rect = [$1.to_i, $2.to_i, bitmap.width - $1.to_i * 2]
      if (0..2) === $3.to_i # x, y, align
        rect.push(wlh, $3.to_i)
      else                  # x, y, wlh
        rect.push($3.to_i, align)
      end
    elsif $2  # x, y
      rect = [
        $1.to_i, $2.to_i, bitmap.width - $1.to_i * 2, wlh, align
      ]
    elsif $1  # align or wlh
      wlh = $1.to_i unless (0..2) === $1.to_i
      align = $1.to_i if (0..2) === $1.to_i
      rect = [
        CAO::Picture::PADDING, CAO::Picture::PADDING + wlh * index,
        bitmap.width - CAO::Picture::PADDING * 2, wlh, align
      ]
    else
      if @data[:rect] # x, y, width, wlh, align
        rect = [
          @data[:rect][0], @data[:rect][1] + @data[:rect][3] * index,
          @data[:rect][2], @data[:rect][3], @data[:rect][4]
        ]
      else
        wlh = (bitmap.height - CAO::Picture::PADDING * 2) / @data[:text].size
        rect = [ CAO::Picture::PADDING, CAO::Picture::PADDING + wlh * index,
                 bitmap.width - CAO::Picture::PADDING * 2, wlh, 0 ]
      end
    end
    return rect
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_text(bitmap, text, rect)
    text_bitmap = Bitmap.new([32, rect[2] + 8].max, [32, rect[3] + 8].max)
    c_width = (rect[2] / text_size(text)).truncate
    contents_x = 4
    loop do
      c = text.slice!(/./m)             # 次の文字を取得
      case c
      when nil                          # 描画すべき文字がない
        break
      when "\x00"                       # \S[n]  (文字サイズ変更)
        text.sub!(/\[([0-9]+)\]/, "")
        text_bitmap.font.size = $1.to_i
        next
      when "\x01"                       # \C[n]  (文字色変更)
        if text.sub!(/\[([0-9A-F]{3,8})\]/i, "")
          text_bitmap.font.color = argb_color($1)
        elsif text.sub!(/\[([0-9]+)\]/, "")
          text_bitmap.font.color = text_color($1.to_i)
        end
        next
      when "\x02"                       # \F  (文字フォント変更)
        text.sub!(/\[(\d+)\]/, "")
        font = CAO::Picture::FONT_NAME[$1.to_i]
        if Font.exist?(font)
          text_bitmap.font.name = font
        else
          text_bitmap.font.name = Font.default_name
        end
        next
      when "\x03"                       # \B  (太字設定)
        text_bitmap.font.bold = true
        next
      when "\x04"                       # \/B  (太字解除)
        text_bitmap.font.bold = false
        next
      when "\x05"                       # \I  (斜体設定)
        text_bitmap.font.italic = true
        next
      when "\x06"                       # \/I  (斜体解除)
        text_bitmap.font.italic = false
        next
      when "\x07"                       # \S  (影設定)
        text_bitmap.font.shadow = true
        next
      when "\x08"                       # \/S  (影解除)
        text_bitmap.font.shadow = false
        next
      when "\x09"                       # \I[n]  (アイコン描画)
        text.sub!(/\[([0-9]+)\]/, "")
        unless @under_line.empty?
          x = contents_x
          y = rect[3] - @under_line[0] + 4
          text_bitmap.fill_rect(x, y, 28, @under_line[0], @under_line[1])
        end
        x = contents_x + 2
        y = (rect[3] - 24) / 2 + 4
        icon_rect = Rect.new($1.to_i % 16 * 24, $1.to_i / 16 * 24, 24, 24)
        text_bitmap.blt(x, y, Cache.system("Iconset"), icon_rect)
        contents_x += 28
      when "\x0c"                       # \U[n]  (下線設定)
        text.sub!(/\[([0-9]+)\]/, "")
        @under_line[0] = $1.to_i
        @under_line[1] = text_bitmap.font.color.dup
        next
      when "\x0d"                       # \/U  (下線解除)
        @under_line.clear
        next
      else                              # 普通の文字
        width = [text_bitmap.text_size(c).width, c_width].min
        unless @under_line.empty?
          x = contents_x
          y = rect[3] - @under_line[0] + 4
          text_bitmap.fill_rect(x, y, width, @under_line[0], @under_line[1])
        end
        text_bitmap.draw_text(contents_x, 4, c_width, rect[3], c)
        contents_x += width
      end
    end
    case rect[4]
    when 0
      x = rect[0]
    when 1
      x = rect[0] + (rect[2] - [rect[2], contents_x - 4].min) / 2
    when 2
      x = rect[0] + rect[2] - [rect[2], contents_x - 4].min
    else
      print "ID #{@number} のピクチャのパラメータが不正です。\n",
            "文字描画設定の順番が間違っていないか確認して下さい。"
    end
    bitmap.blt(x - 4, rect[1] - 4, text_bitmap, text_bitmap.rect)
    text_bitmap.dispose
  end
  #--------------------------------------------------------------------------
  # ● １６進カラーの取得
  #--------------------------------------------------------------------------
  #     0xRGB, 0xARGB, "RGB", "ARGB", "RRGGBB", "AARRGGBB"
  #--------------------------------------------------------------------------
  def argb_color(value)
    if String === value
      value.gsub!(/./, '\&\&') if value.split(//).size <= 4
      value = value.to_i(16)
    end
    argb = [value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF]
    argb[0] = 255 unless value > 0xFFFFFF
    return Color.new(argb[1], argb[2], argb[3], argb[0])
  end
  #--------------------------------------------------------------------------
  # ● 特殊文字の変換
  #--------------------------------------------------------------------------
  #     0x0a 改行(\n)、0x0d キャリッジリターン(\r)、 0x20 空白(\s)
  #--------------------------------------------------------------------------
  def convert_special_characters(text)
    text.gsub!(/\$\[(.+?)\]\$/)     { eval($1) }
    text.gsub!(/\\V\[([0-9]+)\]/i)  { $game_variables[$1.to_i] }
    text.gsub!(/\\N\[0\]/i)         { $game_party.members[0].name }
    text.gsub!(/\\N\[([0-9]+)\]/i)  { $game_actors[$1.to_i].name }
    text.gsub!(/\\G/)               { $game_party.gold }
    text.gsub!(/\\S\[([0-9]+)\]/i)  { "\x00[#{$1}]" }
    text.gsub!(/\\C\[([0-9A-F]{3,8})\]/i)  { "\x01[#{$1}]" }
    text.gsub!(/\\C\[([0-9]+)\]/i)  { "\x01[#{$1}]" }
    text.gsub!(/\\F\[(\d+)\]/i)     { "\x02[#{$1}]" }
    text.gsub!(/\\F\[(.+?)\]/)      { eval("sprintf(#{$1})") }
    text.gsub!(/\\U\[(\d+)\]/i)     { "\x0c[#{$1}]" }
    text.gsub!(/\\\/U/i)            { "\x0d" }
    text.gsub!(/\\I\[(\d+)\]/i)     { "\x09[#{$1}]" }
    text.gsub!(/\\B/i)              { "\x03" }
    text.gsub!(/\\\/B/i)            { "\x04" }
    text.gsub!(/\\I/i)              { "\x05" }
    text.gsub!(/\\\/I/i)            { "\x06" }
    text.gsub!(/\\S/i)              { "\x07" }
    text.gsub!(/\\\/S/i)            { "\x08" }
    return text
  end
  #--------------------------------------------------------------------------
  # ● 文字サイズの取得
  #--------------------------------------------------------------------------
  def text_size(text)
    return 1 if text == ""
    text = text.clone
    text.gsub!(/\x00\[\d+\]/, "")
    text.gsub!(/\x01\[[0-9A-F]{3,8}\]/i, "")
    text.gsub!(/\x01\[\d+\]/, "")
    text.gsub!(/\x02\[\d+\]/, "")
    text.gsub!(/\x09\[\d+\]/, "")   # \I[n]
    text.gsub!(/\x03/, "")  # \B
    text.gsub!(/\x04/, "")
    text.gsub!(/\x05/, "")
    text.gsub!(/\x06/, "")
    text.gsub!(/\x07/, "")
    text.gsub!(/\x08/, "")
    text.gsub!(/\x0c\[\d+\]/, "")
    text.gsub!(/\x0d/, "")
    return text == "" ? 1 : text.size / 3.0
  end
  #--------------------------------------------------------------------------
  # ● 文字色取得
  #     n : 文字色番号 (0～31)
  #--------------------------------------------------------------------------
  def text_color(n, skin_name = "Window")
    x = 64 + (n % 8) * 8
    y = 96 + (n / 8) * 8
    return Cache.system(skin_name).get_pixel(x, y)
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_pic command_118
  def command_118
    case @params[0]
    when /^Ｐ全消去/
      CAO::Picture.erase
    when /^Ｐ反転：\s?(\d+)/
      screen.pictures[$1.to_i].mirror ^= true
    when /^Ｐ正向：\s?(\d+)/
      screen.pictures[$1.to_i].mirror = false
    when /^Ｐ反向：\s?(\d+)/
      screen.pictures[$1.to_i].mirror = true
    when /^Ｗ表示：\s?(\d+),\s?\((\d+),\s?(\d+)\)(?:,\s?(\d+))?/
      # num, (w, h)[, skin]
      screen.pictures[$1.to_i].name = "&W_#{"".object_id}"
      screen.pictures[$1.to_i].data[:type] = :window
      screen.pictures[$1.to_i].data[:skin] = $4.to_i if $4
      screen.pictures[$1.to_i].width = $2.to_i
      screen.pictures[$1.to_i].height = $3.to_i
    when /^Ｗ設定：\s?(\d+),\s?(.+?)(?:,\s?(\d+))?/
      # num, skin, back
      id, skin, back = $1.to_i, $2, ($3 ? $3.to_i : 200)
      if screen.pictures[id].data[:type] != :window
        print "ウィンドウピクチャの設定に失敗しました。\n",
              "ID #{id} のピクチャはウィンドウピクチャではありません。"
        exit
      end
      screen.pictures[id].data[:back] = back
      screen.pictures[id].data[:skin] = skin
      screen.pictures[id].need_refresh = true
    when /^Ｐ画像：([12]?[0-9]),\s?\((\d+),\s?(\d+)\)/
      screen.pictures[$1.to_i].name = "&G_#{"".object_id}"
      screen.pictures[$1.to_i].data[:type] = :bitmap
      screen.pictures[$1.to_i].width = $2.to_i
      screen.pictures[$1.to_i].height = $3.to_i
    when /^Ｉ描画：([12]?[0-9]),\s?\((\d+),\s?(\d+)\),\s?([siwa])(\d+)/
      if screen.pictures[$1.to_i].data[:type] != :bitmap
        print "アイコンの描画に失敗しました。\n",
              "ID #{$1.to_i} のピクチャのタイプが不正です。"
        exit
      end
      case $4
      when "s"
        icon_index = $5.to_i
      when "i"
        icon_index = $data_items[$5.to_i].icon_index
      when "w"
        icon_index = $data_weapons[$5.to_i].icon_index
      when "a"
        icon_index = $data_armors[$5.to_i].icon_index
      end
      screen.pictures[$1.to_i].data[:icon] << [icon_index, $2.to_i ,$3.to_i]
      screen.pictures[$1.to_i].need_refresh = true
    when /^Ｐクリア：([12]?[0-9])/
      screen.pictures[$1.to_i].data[:text].clear
      screen.pictures[$1.to_i].data[:icon].clear
      screen.pictures[$1.to_i].need_refresh = true
    when /^Ｐ名前：([12]?[0-9]),\s?"([MAFPS]_.+)/
      screen.pictures[$1.to_i].data[:type] = :file
      screen.pictures[$1.to_i].name = '"&' + $2
    when /^Ｐ更新：([12]?[0-9])/
      if $1.to_i == 0
        for i in 1..20
          screen.pictures[i].need_refresh = true
        end
      else
        screen.pictures[$1.to_i].need_refresh = true
      end
    else
      return _cao_command_118_pic
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● 注釈処理
  #--------------------------------------------------------------------------
  if $CAO_EX108I
  alias _cao_command_108_pic command_108
  def command_108
    case @parameters[0]
    when /^Ｐ文字描画：([12]?[0-9])(?:,\s?(.*))?/
      number = $1.to_i
      if screen.pictures[number].data[:type] != :bitmap
        print "文字の描画に失敗しました。\n",
              "ID #{number} のピクチャのタイプが不正です。"
        exit
      end
      screen.pictures[number].data[:type] = :bitmap
      for i in 1...@parameters.size
        screen.pictures[number].data[:text] << @parameters[i]
      end
      # 文字の描画域 [x, y, width, wlh, align]（上揃えで描画）
      case $2
      when /\((\d+),\s?(\d+),\s?(\d+),\s?(\d+)\)(?:,\s?(\d+))?/
        screen.pictures[number].data[:rect] = [
          $1.to_i, $2.to_i, $3.to_i, $4.to_i, ($5.nil? ? 0 : $5.to_i)
        ]
      when /(\d+)(?:,\s?(\d+))?/
        pic = screen.pictures[number]
        pic.data[:rect] = [
          CAO::Picture::PADDING, CAO::Picture::PADDING,
          pic.width - CAO::Picture::PADDING * 2,
          $2 ? $2.to_i : 24, $1.to_i
        ]
      else
        screen.pictures[number].data[:rect] = nil
      end
      screen.pictures[number].need_refresh = true
    when /^Ｐ名前：([12]?[0-9]),\s?"([MAFPS]_.+)/
      screen.pictures[$1.to_i].data[:type] = :file
      screen.pictures[$1.to_i].name = '"&' + $2
    else
      return _cao_command_108_pic
    end
    return true
  end
  end # $CAO_EX108I
end

class Sprite_Picture < Sprite
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if @picture_name != @picture.name || @picture.need_refresh
      @picture_name = @picture.name
      if @picture_name != ""
        self.bitmap.dispose if self.bitmap != nil
        self.bitmap = @picture.create_grapic
        @picture.need_refresh = false
      end
    end
    update_picture
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update_picture
    if @picture_name == ""
      self.visible = false
    else
      self.visible = true
      if @picture.origin == 0
        self.ox = 0
        self.oy = 0
      else
        self.ox = self.bitmap.width / 2
        self.oy = self.bitmap.height / 2
      end
      self.x = @picture.x
      self.y = @picture.y
      self.z = 100 + @picture.number
      self.zoom_x = @picture.zoom_x / 100.0
      self.zoom_y = @picture.zoom_y / 100.0
      self.opacity = @picture.opacity
      self.blend_type = @picture.blend_type
      self.angle = @picture.angle
      self.tone = @picture.tone
      self.mirror = @picture.mirror
    end
  end
end
