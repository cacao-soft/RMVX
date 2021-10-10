#=============================================================================
#  [RGSS2] ＜拡張＞ 文章の表示 - v1.1.1
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

  イベントコマンド「文章の表示」で使用できる制御文字を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を多用しています。他スクリプトよりも上に設置してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ 追加された制御文字
   アラインメント    ： \L[0-2]
   太字              ： \B ... \/B
   斜体              ： \I ... \/I
   下線              ： \U[n] ... \/U
   イベント変数の配列： \V[m][n]
   先頭のアクター名  ： \N[0]
   実行中のイベント名： \N[EV]
   パーティの情報    ： \P[n, params]
   アクターの情報    ： \A[n, params]
   エネミーの情報    ： \E[n, params]
   sprintf           ： \F[フォーマット, 引数]
   どもり表現        ： \S[文字[, 区切り]]
   アイコン          ： \I[n]
   吹き出し          ： \B[n]
   所持金            ： \$
   パーティの人数    ： $Pcount
   歩数              ： $Step
   セーブ回数        ： $Save
   スクリプト        ： $[ ... ]$

  ★ 各名前のデータベース参照
   データベース名    ： \D[kind+n]
   kind (i:アイテム, w:武器, a:防具, c:クラス)
   n (データベースの番号)
   例）\D[i16]   # １６番のアイテム名

  ★ Cacao Base Script 導入時に使用可能
   プレイ時間        ： \T[n]
   現在地            ： $Map

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_Message < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  BALLOON_WAIT = 12
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_exmes initialize
  def initialize
    _cao_initialize_exmes
    @balloon_duration = 0
    @balloon_id = 0
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_update_exmes update
  def update
    _cao_update_exmes
    update_balloon unless @opening or @closing  # ウィンドウの開閉中以外
    dispose_balloon if @closing
  end
  #--------------------------------------------------------------------------
  # ○ 特殊文字の変換
  #--------------------------------------------------------------------------
  #     0x0a 改行(\n)、0x0d キャリッジリターン(\r)、 0x20 空白(\s)
  #--------------------------------------------------------------------------
  def convert_special_characters
    # スクリプト (最優先)
    @text.gsub!(/\$\[(.*?)\]\$/i)   { eval($1) }
    # 置換処理
    @text.gsub!(/\$Map/i)           { $game_map.name }
    @text.gsub!(/\$Pcount/i)        { $game_party.members.size }
    @text.gsub!(/\$Step/i)          { $game_party.steps }
    @text.gsub!(/\$Save/i)          { $game_system.save_count }
    @text.gsub!(/\\\$/)             { $game_party.gold }
    @text.gsub!(/\\V\[(\d+)\]\[(\d+)\]/i) { $game_variables[$1.to_i][$2.to_i] }
    @text.gsub!(/\\V\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    @text.gsub!(/\\V\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    @text.gsub!(/\\D\[I(\d+)\]/i)   { $data_items[$1.to_i].name }
    @text.gsub!(/\\D\[W(\d+)\]/i)   { $data_weapons[$1.to_i].name }
    @text.gsub!(/\\D\[A(\d+)\]/i)   { $data_armors[$1.to_i].name }
    @text.gsub!(/\\D\[C(\d+)\]/i)   { $data_classes[$1.to_i].name }
    @text.gsub!(/\\P\[(\d+),\s*(\w+)\]/i) { get_party_parameters($1.to_i, $2) }
    @text.gsub!(/\\A\[(\d+),\s*(\w+)\]/i) { get_actor_parameters($1.to_i, $2) }
    @text.gsub!(/\\E\[(\d+),\s*(\w+)\]/i) { get_enemy_parameters($1.to_i, $2) }
    @text.gsub!(/\\N\[EV\]/i)       { event_name }
    @text.gsub!(/\\N\[0\]/i)        { $game_party.name }
    @text.gsub!(/\\N\[([0-9]+)\]/i) { $game_actors[$1.to_i].name }
    @text.gsub!(/\\T\[h\]/i)        { RPG::Time.to_a[0] }
    @text.gsub!(/\\T\[m\]/i)        { RPG::Time.to_a[1] }
    @text.gsub!(/\\T\[s\]/i)        { RPG::Time.to_a[2] }
    @text.gsub!(/\\\\/)             { "\\" }
    # 置換後処理 (\V[n] の値を使いたい場合など)
    @text.gsub!(/\\F\[(.+?)\]/i)    { eval("sprintf(#{$1})") }
    @text.gsub!(/\\C\[([0-9]+)\]/i) { "\x01[#{$1}]" }   # 文字色
    @text.gsub!(/\\L\[([0-2]+)\]/i) { "\x13[#{$1}]" }
    @text.gsub!(/\\S\[(.+?)\]/i)    { stutter($1) }#"\x13[#{$1}]" }   # どもり
    # 描画効果・その他
    @text.gsub!(/\\U\[([0-9]+)\]/i) { "\x10[#{$1}]" }
    @text.gsub!(/\\\/U/i)           { "\x11" }
    @text.gsub!(/\\I\[([0-9]+)\]/i) { "\x09[#{$1}]" }   # アイコン
    @text.gsub!(/\\I/i)             { "\x0e" }
    @text.gsub!(/\\\/I/i)           { "\x0f" }
    @text.gsub!(/\\B\[([0-9]+)\]/i) { "\x12[#{$1}]" }   # 吹き出し
    @text.gsub!(/\\B/i)             { "\x0b" }
    @text.gsub!(/\\\/B/i)           { "\x0c" }
    @text.gsub!(/\\G/i)             { "\x02" }
    @text.gsub!(/\\\./)             { "\x03" }
    @text.gsub!(/\\\|/)             { "\x04" }
    @text.gsub!(/\\!/)              { "\x05" }
    @text.gsub!(/\\>/)              { "\x06" }
    @text.gsub!(/\\</)              { "\x07" }
    @text.gsub!(/\\\^/)             { "\x08" }
  end
  #--------------------------------------------------------------------------
  # ○ メッセージの更新
  #--------------------------------------------------------------------------
  def update_message
    loop do
      c = @text.slice!(/./m)            # 次の文字を取得
      case c
      when nil                          # 描画すべき文字がない
        finish_message                  # 更新終了
        break
      when "\x00"                       # 改行
        new_line
        if @line_count >= MAX_LINE      # 行数が最大のとき
          unless @text.empty?           # さらに続きがあるなら
            self.pause = true           # 入力待ちを入れる
            break
          end
        end
      when "\x01"                       # \C[n]  (文字色変更)
        @text.sub!(/\[([0-9]+)\]/, "")
        contents.font.color = text_color($1.to_i)
        next
      when "\x02"                       # \G  (所持金表示)
        @gold_window.refresh
        @gold_window.open
      when "\x03"                       # \.  (ウェイト 1/4 秒)
        @wait_count = 15
        break
      when "\x04"                       # \|  (ウェイト 1 秒)
        @wait_count = 60
        break
      when "\x05"                       # \!  (入力待ち)
        self.pause = true
        break
      when "\x06"                       # \>  (瞬間表示 ON)
        @line_show_fast = true
      when "\x07"                       # \<  (瞬間表示 OFF)
        @line_show_fast = false
      when "\x08"                       # \^  (入力待ちなし)
        @pause_skip = true
      when "\x09"                       # \I[n]  (アイコンの描画)
        @text.sub!(/\[([0-9]+)\]/, "")
        index = $1.to_i
        rect = Rect.new(index % 16 * 24, index / 16 * 24, 24, 24)
        contents.blt(@contents_x, @contents_y, Cache.system("Iconset"), rect)
        @contents_x += 24
      when "\x0b"                       # \B  (太字)
        contents.font.bold = true
        next
      when "\x0c"                       # \/B  (太字終)
        contents.font.bold = false
        next
      when "\x0e"                       # \I  (斜体)
        contents.font.italic = true
        next
      when "\x0f"                       # \/I  (斜体終)
        contents.font.italic = false
        next
      when "\x10"                       # \U[n]  (下線)
        @under_line = true
        @text.sub!(/\[([0-9]+)\]/, "")
        @line_color = text_color($1.to_i)
        next
      when "\x11"                       # \/U  (下線終)
        @under_line = false
        next
      when "\x12"                       # \/B[n]  (吹き出し)
        @text.sub!(/\[([0-9]+)\]/, "")
        @balloon_id = $1.to_i
        start_balloon
        next
      when "\x13"                       # \L[0-2]  (アラインメント)
        @text.sub!(/\[([0-2]+)\]/, "")
        align = $1.to_i
        @text.match(/\x00/)
        text = $`
        if align > 0
          @text.match(/\x00/)
          text = $`
          text.gsub!(/[\x00-\x1F]\[.+?\]/, "")
          text.gsub!(/[\x80-\xFF]\[.+?\]/, "")
          text.gsub!(/./m) {|c| (c.size == 1 && /[\x20-\x7e]/ !~ c) ? "" : c }
          width = contents.width - @contents_x - contents.text_size(text).width
          width /= 2 if align == 1
          @contents_x += width
        end
        next
      else                              # 普通の文字
        c_width = contents.text_size(c).width
        if @under_line
          rect = Rect.new(@contents_x-2, @contents_y+WLH-1, c_width+4, 1)
          contents.fill_rect(rect, @line_color)
        end
        contents.draw_text(@contents_x, @contents_y, 40, WLH, c)
        @contents_x += c_width
      end
      break unless @show_fast or @line_show_fast
    end
  end
  #--------------------------------------------------------------------------
  # ○ 改ページ処理
  #--------------------------------------------------------------------------
  alias _cao_new_page_exmes new_page
  def new_page
    _cao_new_page_exmes
    dispose_balloon
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def event_name
    id = $game_map.interpreter.instance_variable_get(:@event_id)
    event = $game_map.events[id].instance_variable_get(:@event)
    return event.name
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def stutter(text)
    if /(.+?)(?:,\s*\"(.+?)\"|$)/ =~ text
      text, ten = $1, ($2 == nil ? "、" : $2)
      return text.split(//u)[0] + ten + text
    end
    return ""
  end
  #--------------------------------------------------------------------------
  # ● フキダシアイコン表示の開始
  #--------------------------------------------------------------------------
  def start_balloon
    dispose_balloon
    @balloon_duration = 8 * 8 + BALLOON_WAIT
    @balloon_sprite = Sprite.new
    @balloon_sprite.bitmap = Cache.system("Balloon")
    @balloon_sprite.x = self.x + 96
    @balloon_sprite.y = self.y
    @balloon_sprite.z = self.y + 200
    update_balloon
  end
  #--------------------------------------------------------------------------
  # ● フキダシアイコンの更新
  #--------------------------------------------------------------------------
  def update_balloon
    return unless @balloon_sprite
    if @balloon_duration > 0
      @balloon_duration -= 1
      if @balloon_duration == 0
        dispose_balloon
      else
        if @balloon_duration < BALLOON_WAIT
          sx = 7 * 32
        else
          sx = (7 - (@balloon_duration - BALLOON_WAIT) / 8) * 32
        end
        sy = (@balloon_id - 1) * 32
        @balloon_sprite.src_rect.set(sx, sy, 32, 32)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● フキダシアイコンの解放
  #--------------------------------------------------------------------------
  def dispose_balloon
    if @balloon_sprite != nil
      @balloon_sprite.dispose
      @balloon_sprite = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● パーティのパラメータを取得
  #--------------------------------------------------------------------------
  def get_party_parameters(id, params)
    actor = $game_party.members[id]
    case params.upcase
    when "MAXHP"
      return actor.maxhp
    when "MAXMP"
      return actor.maxmp
    when "HP"
      return actor.hp
    when "MP"
      return actor.mp
    when "ATK"
      return actor.atk
    when "DEF"
      return actor.def
    when "SPI"
      return actor.spi
    when "AGI"
      return actor.agi
    when "NAME"
      return actor.name
    when "CLASS"
      return $data_classes[actor.class_id].name
    end
  end
  #--------------------------------------------------------------------------
  # ● アクターのパラメータを取得
  #--------------------------------------------------------------------------
  def get_actor_parameters(id, params)
    return "" if id == 0
    case params.upcase
    when "MAXHP"
      return $game_actors[id].maxhp
    when "MAXMP"
      return $game_actors[id].maxmp
    when "HP"
      return $game_actors[id].hp
    when "MP"
      return $game_actors[id].mp
    when "ATK"
      return $game_actors[id].atk
    when "DEF"
      return $game_actors[id].def
    when "SPI"
      return $game_actors[id].spi
    when "AGI"
      return $game_actors[id].agi
    when "NAME"
      return $game_actors[id].name
    when "CLASS"
      return $data_classes[$game_actors[id].class_id].name
    end
  end
  #--------------------------------------------------------------------------
  # ● エネミーのパラメータを取得
  #--------------------------------------------------------------------------
  def get_enemy_parameters(id, params)
    return "" if id == 0
    case params.upcase
    when "NAME"
      return $data_enemies[id].name
    when "MAXHP"
      return $data_enemies[id].maxhp
    when "MAXMP"
      return $data_enemies[id].maxmp
    when "ATK"
      return $data_enemies[id].atk
    when "DEF"
      return $data_enemies[id].def
    when "SPI"
      return $data_enemies[id].spi
    when "AGI"
      return $data_enemies[id].agi
    when "HIT"
      return $data_enemies[id].hit
    when "EVA"
      return $data_enemies[id].eva
    when "EXP"
      return $data_enemies[id].exp
    when "GOLD"
      return $data_enemies[id].gold
    end
  end
end
