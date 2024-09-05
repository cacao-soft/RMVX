#=============================================================================
#  [RGSS2] テキストウィンドウ - v1.1.2
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

  カスタムメニューにテキストを表示するウィンドウを追加します。
  ウィンドウは、複数設定する事が出来ます。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの動作には、Custom Menu Base が必要です。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::TEXT_WIN
  #--------------------------------------------------------------------------
  # ◇ 各ウィンドウの設定
  #--------------------------------------------------------------------------
  #   ウィンドウの数だけ、配列にハッシュを追加します。
  #   ハッシュのキーは、以下のようになっています。
  #     :wind => [x, y, width, height]  (ウィンドウの位置とサイズ)
  #     :text => ''                     (表示するテキスト)
  #     :line => 24                     (行幅：省略可能)
  #     :opct => 200                    (ウィンドウの不透明度：省略可能)
  #     :vsbl => true                   (ウィンドウの可視：省略可能)
  #--------------------------------------------------------------------------
  #   テキストは、シングルクォート '...' で囲みます。
  #   記述方法は、イベントコマンド「文章の表示」とほぼ変わりありませんが、
  #   自動で改行を行わないので、\n を記述して改行箇所を指定する必要があります。
  #   この改行 \n は、他の制御文字と違い必ず小文字で記述してください。
  #   ＜使用可能な制御文字＞
  #     \V[n]   : イベント変数 n 番の値を表示
  #     \S[n,on,off] : スイッチ n 番の状態に合わせて、on/off の文字を表示
  #     \S[s,on,off] : スクリプト s の状態に合わせて、on/off の文字を表示
  #     \N[n]   : アクター n 番の名前を表示 ( 0 の場合は、パーティの先頭)
  #     \C[n]   : カラーインデックス n 番の色に変更 (標準色:0, システム色:16)
  #     \I[n]   : アイコンインデックス n 番のアイコンを表示
  #     \S[n]   : 文字サイズを n に変更 (最小 10 : 最大 40 まで)
  #     \X[n]   : 描画ｘ座標を n に変更 (\X+[n] | \X-[n] : 現在の値から増減)
  #     \Y[n]   : 描画ｙ座標を n に変更 (\Y+[n] | \Y-[n] : 現在の値から増減)
  #     \L[n]   : 行幅を n に変更 (最小 10 まで)
  #     \P[n]   : 描画位置を指定するためのブロックを設定 (n:C=中央, L=左, R=右)
  #     \/P     : 例）\P[C]行単位で中央揃え\/P  \P[R100]幅100で右揃え\/P
  #     \B○\/B : \B .. 以降、太字で描画、\/B .. 太字の描画を終了
  #     \I○\/I : \I .. 以降、斜体で描画、\/I .. 斜体の描画を終了
  #     \G      : 所持金を表示
  #     \W      : 歩数を表示
  #     \S      : セーブ回数を表示
  #     \n      : 改行
  #     $[...]$ : ... に記述されたスクリプトを実行(描画)
  #--------------------------------------------------------------------------
  WINDOW_SET = [
    { # ウィンドウ１
      :wind => [216, 96, 272, 224],
      :text => '\S[16]１番のスイッチは、現在 \S[1,ＯＮ,ＯＦＦ] です。\n\n' +
              '\S[$TEST,テストプレイ,通常ゲーム]\n\n' +
              '今日は $[Time.now.mon]$月$[Time.now.day]$日 です。\n' +
              '\N[0]のセーブ回数は、\n　\S 回である。\n' +
              '\I[3]\I[13]\I[23]'
    },
    { # ウィンドウ２
      :wind => [0, 208, 160, 152],
      :text => '\S[10]\P[C]\B中央\/B\/P\n' + '\P[L]左\/P\n' + '\P[R]右\/P\n' +
              '[\P[C60]\S[1,あいう,\Iえお\/I]\/P]\n' +
              '\P[L20]表示\/Pされない'
    },
    { # 所持金ウィンドウ
      :wind => [0, 360, 160, 56],
      :text => '\X[36]$[sprintf("%7d",$game_party.gold)]$\X[110]\C[16]Ｇ'
    }
  ]
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_MenuText < Window_Base
  include CAO::CM::TEXT_WIN
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  LINE_MIN = 10             # 行幅の最小値
  FONT_MAX = 40             # 文字の最大サイズ
  FONT_MIN = 10             # 文字の最小サイズ
  #--------------------------------------------------------------------------
  # ● 正規表現
  #--------------------------------------------------------------------------
  REG_SPT = /\$\[(.+?)\]\$/                     # スクリプト
  REG_V   = /\\V\[([0-9]+)\]/i                  # ＥＶ変数
  REG_SWN = /\\S\[(?!:\d)(\d+),(.*?),(.*?)\]/i  # スイッチ (イベント)
  REG_SWS = /\\S\[(\D.*?),(.*?),(.*?)\]/i       # スイッチ (スクリプト)
  REG_PN  = /\\N\[([0])\]/i                     # パーティ名 (○○たち)
  REG_AN  = /\\N\[([0-9]+)\]/i                  # アクター名
  REG_ICN = /\\I\[([0-9]+)\]/i                  # アイコン
  REG_X   = /\\X([+-]?)\[([0-9]+)\]/i           # ｘ座標
  REG_Y   = /\\Y([+-]?)\[([0-9]+)\]/i           # ｙ座標
  REG_L   = /\\L\[(.+?)\]/i                     # 行幅
  REG_P   = /\\P\[([CLR]\d*)\](.*?\\\/P)/i      # ブロック (アラインメント)
  REG_N   = /\\n/                               # 改行
  REG_FC  = /\\C\[([0-9]+)\]/i                  # 文字色
  REG_FS  = /\\S\[([0-9]+)\]/i                  # サイズ
  REG_FBS = /\\B/i                              # 太字 開始
  REG_FBE = /\\\/B/i                            # 太字 終了
  REG_FIS = /\\I/i                              # 斜体 開始
  REG_FIE = /\\\/I/i                            # 斜体 終了
  REG_GLD = /\\G/i                              # 所持金
  REG_STP = /\\W/i                              # 歩数
  REG_SAV = /\\S/i                              # セーブ回数
  REG_EN  = /\\\\/                              # ￥
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     number :
  #--------------------------------------------------------------------------
  def initialize(number)
    @number = number
    super(*WINDOW_SET[@number][:wind])
    self.visible=WINDOW_SET[@number][:vsbl] if WINDOW_SET[@number].key?(:vsbl)
    self.opacity=WINDOW_SET[@number][:opct] if WINDOW_SET[@number].key?(:opct)
    @line = WINDOW_SET[@number].key?(:line) ? WINDOW_SET[@number][:line] : 24
    @line = [LINE_MIN, @line].max
    @align = -1
    convert_special_characters
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @contents_x = 0
    @contents_y = 0
    self.contents.clear
    loop do
      c = @text.slice!(/./m)            # 次の文字を取得
      case c
      when nil                          # 描画すべき文字がない
        break
      when "\x00", "\n"                 # 改行
        @contents_x = 0
        @contents_y += @line
        break if self.contents.height < @contents_y
      when "\x01"                       # \X  (ｘ座標変更)
        @text.sub!(/([+-]?)\[([0-9]+)\]/, "")
        case $1
        when "+"
          @contents_x += $2.to_i
        when "-"
          @contents_x -= $2.to_i
        else
          @contents_x = $2.to_i
        end
      when "\x02"                       # \Y  (ｙ座標変更)
        @text.sub!(/([+-]?)\[([0-9]+)\]/, "")
        case $1
        when "+"
          @contents_y += $2.to_i
        when "-"
          @contents_y -= $2.to_i
        else
          @contents_y = $2.to_i
        end
      when "\x03"                       # \L  (行幅)
        @text.sub!(/\[([0-9]+)\]/, "")
        @line = [LINE_MIN, $1.to_i].max
      when "\x04"                       # \P  (アラインメント)
        @text.sub!(/\[([CLR])(\d+)?\](.+?)\\\/P/i, "")
        @text = $3 + "\x05" + @text
        create_block($1, ($2 ? $2.to_i : contents.width), $3)
      when "\x05"                       # \/P  (アラインメント)
        contents.blt(@contents_x - 4, @contents_y - 4, @bitmap, @bitmap.rect)
        @align = -1
        @contents_x += @bitmap.width - 8
        @bitmap.dispose
      when "\x80"                       # \C[n]  (文字色変更)
        @text.sub!(/\[([0-9]+)\]/, "")
        self.contents.font.color = text_color($1.to_i)
      when "\x81"                       # \S  (文字サイズ変更)
        @text.sub!(/\[([0-9]+)\]/, "")
        self.contents.font.size = [FONT_MIN, [$1.to_i, FONT_MAX].min].max
      when "\x82"                       # \B  (太字)
        self.contents.font.bold = true
      when "\x83"                       # \/B  (太字)
        self.contents.font.bold = false
      when "\x84"                       # \I  (太字)
        self.contents.font.italic  = true
      when "\x85"                       # \/I  (太字)
        self.contents.font.italic  = false
      when "\x90"                       # \I  (アイコン)
        @text.sub!(/\[([0-9]+)\]/, "")
        draw_icon($1.to_i, @contents_x, @contents_y)
        @contents_x += 24
      else                              # 普通の文字
        if @align < 0
          contents.draw_text(@contents_x, @contents_y, 40, @line, c)
          @contents_x += contents.text_size(c).width
        else
          @bitmap.font.color = contents.font.color
          @bitmap.font.size = contents.font.size
          @bitmap.font.bold = contents.font.bold
          @bitmap.font.italic = contents.font.italic
          @bitmap.draw_text(@bitmap_x + 4, 4, 40, @line, c)
          @bitmap_x += contents.text_size(c).width
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 特殊文字の変換
  #--------------------------------------------------------------------------
  def convert_special_characters
    @text = WINDOW_SET[@number][:text].dup
    @text.gsub!(REG_SPT) { script($1) }
    @text.gsub!(REG_V)   { $game_variables[$1.to_i] }
    @text.gsub!(REG_SWN) { $game_switches[$1.to_i] ? $2 : $3 }
    @text.gsub!(REG_SWS) { script_sw($1, $2, $3) }
    @text.gsub!(REG_PN)  { $game_party.name }
    @text.gsub!(REG_AN)  { $game_actors[$1.to_i].name }
    @text.gsub!(REG_X)   { "\x01#{$1}[#{$2}]" }
    @text.gsub!(REG_Y)   { "\x02#{$1}[#{$2}]" }
    @text.gsub!(REG_L)   { "\x03[#{$1}]" }
    @text.gsub!(REG_P)   { "\x04[#{$1}]#{$2}" } # \x05 定義済み
    @text.gsub!(REG_FC)  { "\x80[#{$1}]" }
    @text.gsub!(REG_FS)  { "\x81[#{$1}]" }
    @text.gsub!(REG_ICN) { "\x90[#{$1}]" }
    @text.gsub!(REG_N)   { "\x00" }
    @text.gsub!(REG_FBS) { "\x82" }
    @text.gsub!(REG_FBE) { "\x83" }
    @text.gsub!(REG_FIS) { "\x84" }
    @text.gsub!(REG_FIE) { "\x85" }
    @text.gsub!(REG_GLD) { $game_party.gold }
    @text.gsub!(REG_STP) { $game_party.steps }
    @text.gsub!(REG_SAV) { $game_system.save_count }
    @text.gsub!(REG_EN)  { "\\" }
  end
  #--------------------------------------------------------------------------
  # ● $[...]$
  #--------------------------------------------------------------------------
  def script(str)
    begin
      result = eval(str)
    rescue Exception => error
      msg = "#{@number+1} 番目のウィンドウの制御文字 $[...]$ の\n"\
            "使用方法が間違っている可能性があります。\n\n#{error}"
      raise CustomizeError, msg, __FILE__
    end
    return result ? result : ""
  end
  #--------------------------------------------------------------------------
  # ● \S[script,on,off]
  #--------------------------------------------------------------------------
  def script_sw(str, t, f)
    begin
      result = eval(str)
    rescue Exception => error
      msg = "#{@number+1} 番目のウィンドウの制御文字 \\S[script,on,off] の\n"\
            "使用方法が間違っている可能性があります。\n\n#{error}"
      raise CustomizeError, msg, __FILE__
    end
    return result ? t : f
  end
  #--------------------------------------------------------------------------
  # ● \P[n] ... \/P
  #--------------------------------------------------------------------------
  def create_block(align, width, text)
    @align = ['L', 'C', 'R'].index(align.upcase)
    @bitmap_x = 0
    @bitmap = Bitmap.new(width + 8, @line + 8)
    if @align > 0
      text.gsub!(/[\x00-\x1F]\[.+?\]/, "")
      text.gsub!(/./m) {|c| (c.size == 1 && /[\x20-\x7e]/ !~ c) ? "" : c }
      text_size = contents.text_size(text).width
      @bitmap_x = (width - text_size)
      @bitmap_x /= 2 if @align == 1
    end
  end
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_create_option_window_cm_text create_option_window
  def create_option_window
    _cao_create_option_window_cm_text
    @text_windows = []
    for i in 0...TEXT_WIN::WINDOW_SET.size
      @text_windows[i] = Window_MenuText.new(i)
    end
    @component[:opt_text] = @text_windows
  end
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの解放
  #--------------------------------------------------------------------------
  alias _cao_dispose_option_window_cm_text dispose_option_window
  def dispose_option_window
    _cao_dispose_option_window_cm_text
    for i in 0...TEXT_WIN::WINDOW_SET.size
      @text_windows[i].dispose
    end
  end
end
