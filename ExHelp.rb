#=============================================================================
#  [RGSS2] ＜拡張＞ ヘルプウィンドウ - v1.1.0
# ---------------------------------------------------------------------------
#  Copyright (c) 2022 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/mit-license.php
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- 概    要 ----------------------------------------------------------------

  ヘルプウィンドウで使用できる制御文字を追加します。

 -- 使用方法 ----------------------------------------------------------------

  ★ 追加された制御文字
   改行              ： \n か \|
   アラインメント    ： \L[0-2]
   太字色            ： \C[n]
   太字              ： \B ... \/B
   斜体              ： \I ... \/I
   下線              ： \U[n] ... \/U
   イベント変数      ： \V[n]
   イベント変数の配列： \V[m][n]
   先頭のアクター名  ： \N[0]
   アクター名        ： \N[n]
   sprintf           ： \F[フォーマット, 引数]
   アイコン          ： \I[n]
   所持金            ： \$
   頭文字反復        ： \S[テキスト,句点]
   スクリプト        ： $[ ... ]$

  ★ 各名前のデータベース参照
   データベース名    ： \D[kind+n,param]
   kind (i:アイテム, w:武器, a:防具, c:クラス, s:スキル, e:エネミー)
   n (データベースの番号)
   param (データ構造のプロパティ名 RPG::*) ※ 省略時 name
   例）\D[i16]   # １６番のアイテム名
   例）\D[s16,mp_cost]   # １６番のアイテム名
   
  ★ 各情報の参照
   パーティの情報    ： \P[n, param]
   アクターの情報    ： \A[n, param]
   n (調べる ID)
   param (Game_Actor のプロパティ名) ※ class のみ .class.name
   例）\P[0]  # パーティの先頭のアクター名
   例）\A[3,hp]  # アクターID 3 の現在の HP

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#



class Window_Help
  #--------------------------------------------------------------------------
  # ○ テキスト設定
  #     text  : ウィンドウに表示する文字列
  #     align : アラインメント (0..左揃え、1..中央揃え、2..右揃え)
  #--------------------------------------------------------------------------
  def set_text(text, align = 0)
    if text != @text or align != @align
      @text = text
      @align = align
      draw_styled_text
    end
  end
  #--------------------------------------------------------------------------
  # ● 特殊文字の変換
  #--------------------------------------------------------------------------
  #     0x0a 改行(\n)、0x0d キャリッジリターン(\r)、 0x20 空白(\s)
  #--------------------------------------------------------------------------
  def convert_special_characters
    text = @text.dup
    # スクリプト (最優先)
    text.gsub!(/\$\[(.*?)\]\$/i)   { eval($1) }
    # 置換処理
    text.gsub!(/\\[\$G]/)          { $game_party.gold }
    text.gsub!(/\\V\[(\d+)\]\[(\d+)\]/i) { $game_variables[$1.to_i][$2.to_i] }
    text.gsub!(/\\V\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    text.gsub!(/\\V\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    text.gsub!(/\\D\[I(\d+)(?:,\s*(\w+))?\]/i) { param($data_items, $1, $2) }
    text.gsub!(/\\D\[W(\d+)(?:,\s*(\w+))?\]/i) { param($data_weapons, $1, $2) }
    text.gsub!(/\\D\[A(\d+)(?:,\s*(\w+))?\]/i) { param($data_armors, $1, $2) }
    text.gsub!(/\\D\[C(\d+)(?:,\s*(\w+))?\]/i) { param($data_classes, $1, $2) }
    text.gsub!(/\\D\[S(\d+)(?:,\s*(\w+))?\]/i) { param($data_skills, $1, $2) }
    text.gsub!(/\\D\[E(\d+)(?:,\s*(\w+))?\]/i) { param($data_enemies, $1, $2) }
    text.gsub!(/\\P\[(\d+),\s*(\w+)\]/i) { param($game_party.members, $1, $2) }
    text.gsub!(/\\A\[(\d+),\s*(\w+)\]/i) { param($game_actors, $1, $2) }
    text.gsub!(/\\N\[0\]/i)        { $game_party.name }
    text.gsub!(/\\N\[(\d+)\]/i)    { $game_actors[$1.to_i].name }
    text.gsub!(/\\\\/)             { "\\" }
    # 置換後処理 (\V[n] の値を使いたい場合など)
    text.gsub!(/\\F\[(.+?)\]/i)    { eval("sprintf(#{$1})") }
    text.gsub!(/\\C\[([0-9]+)\]/i) { "\x01[#{$1}]" }   # 文字色
    text.gsub!(/\\L\[([0-2]+)\]/i) { "\x13[#{$1}]" }   # Alignment
    text.gsub!(/\\S\[(.+?)\]/i)    { stutter($1) }     # 頭文字反復
    # 描画効果・その他
    text.gsub!(/\\U\[([0-9]+)\]/i) { "\x10[#{$1}]" }
    text.gsub!(/\\\/U/i)           { "\x11" }
    text.gsub!(/\\I\[([0-9]+)\]/i) { "\x02[#{$1}]" }   # アイコン
    text.gsub!(/\\I/i)             { "\x05" }
    text.gsub!(/\\\/I/i)           { "\x06" }
    text.gsub!(/\\B/i)             { "\x03" }
    text.gsub!(/\\\/B/i)           { "\x04" }
    #
    text.gsub!(/\\[n|]|\r?\n/)     { "\x00" }         # 改行
    return text
  end
  #--------------------------------------------------------------------------
  # ● 書式付きテキストの描画
  #--------------------------------------------------------------------------
  def draw_styled_text
    self.contents.clear
    self.contents.font.color = normal_color
    self.contents.font.bold = false
    self.contents.font.italic = false
    text = convert_special_characters
    x = start_line_x(text)
    y = 0
    while c = text.slice!(/./m)         # 次の文字を取得
      case c
      when "\x00","\r","\n"
        x = start_line_x(text)
        y += WLH
      when "\x01"                       # \C[n]  (文字色変更)
        text.sub!(/\[([0-9]+)\]/, "")
        contents.font.color = text_color($1.to_i)
      when "\x02"                       # \I[n]  (アイコンの描画)
        text.sub!(/\[([0-9]+)\]/, "")
        index = $1.to_i
        rect = Rect.new(index % 16 * 24, index / 16 * 24, 24, 24)
        contents.blt(x, y, Cache.system("Iconset"), rect)
        x += 24
      when "\x03"                       # \B  (太字)
        contents.font.bold = true
      when "\x04"                       # \/B  (太字終)
        contents.font.bold = false
      when "\x05"                       # \I  (斜体)
        contents.font.italic = true
      when "\x06"                       # \/I  (斜体終)
        contents.font.italic = false
      when "\x10"                       # \U[n]  (下線)
        @under_line = true
        text.sub!(/\[([0-9]+)\]/, "")
        @line_color = text_color($1.to_i)
      when "\x11"                       # \/U  (下線終)
        @under_line = false
      when "\x13"                       # \L[0-2]  (アラインメント)
        text.sub!(/\[([0-2]+)\]/, "")
      else                              # 普通の文字
        c_width = contents.text_size(c).width
        if @under_line
          rect = Rect.new(x-2, y+WLH-1, c_width+4, 1)
          contents.fill_rect(rect, @line_color)
        end
        contents.draw_text(x, y, 40, WLH, c)
        x += c_width
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 開始 x 座標を取得
  #--------------------------------------------------------------------------
  def start_line_x(text)
    line = text.match(/[\x00\r\n]/) ? $` : text.dup
    x = 0
    align = (line[/\x13\[([0-2]+)\]/i, 1] || @align).to_i
    if align > 0
      line.gsub!(/[\x00-\x1F\x80-\xFF]\[.+?\]/, "")
      line.gsub!(/./m) {|c| (c.size == 1 && /[\x20-\x7e]/ !~ c) ? "" : c }
      width = contents.width - x - contents.text_size(line).width
      width /= 2 if align == 1
      x += width
    end
    return x
  end
  #--------------------------------------------------------------------------
  # ● 頭文字の反復
  #--------------------------------------------------------------------------
  def stutter(text)
    if /(.+?)(?:,\s*\"(.+?)\"|$)/ =~ text
      text, ten = $1, ($2 == nil ? "、" : $2)
      return text.split(//u)[0] + ten + text
    end
    return ""
  end
  #--------------------------------------------------------------------------
  # ● パラメータを取得
  #--------------------------------------------------------------------------
  def param(data_list, str_id, param)
    data = data_list[str_id.to_i]
    param = "name" if param == nil || param == ""
    if data && data.respond_to?(param)
      data = data.__send__(param)
      if param == "class" && data.respond_to?("name")
        return data.name
      else
        return data.to_s
      end
    end
    return "????"
  end
end
