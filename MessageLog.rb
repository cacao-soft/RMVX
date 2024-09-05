#=============================================================================
#  [RGSS2] メッセージログ - v1.0.2
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

  「文章の表示」で表示された文を記録・確認する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 制御文字の変換処理は２度実行されます。

 -- 使用方法 ----------------------------------------------------------------

  ★ ログに文章を追加
   注釈の１行目に <メッセージログ> と記述すると以降の文が記録されます。

  ★ ログに文章を追加 (隠しメッセージ)
   注釈の１行目に <秘密ログ> と記述すると以降の文が記録されます。

  ★ ログに文章を追加 (スクリプト)
   $game_message.set_log(text[, color])
     text  : 文字列もしくは配列
     color : ウィンドウスキンのカラー番号 (\C[n] の番号と同じ) 省略可


=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module Log

  # ログ記録の禁止スイッチの番号
  OFF_SW_NUM = 5

  # ログ表示の禁止スイッチの番号
  DISABLE_SW_NUM = 6

  # 記録する行数
  MAX_LOG = 100

  # 除外文字
  EXCEPTS_TEXT = []

  # ログを表示するボタン
  SHOW_BUTTON = Input::Y

  # 文字色の設定
  COL_SECRET = Color.new(255, 200, 0)         # 隠しメッセージ
  COL_NUMBER = Color.new(64, 200, 255)        # 数値入力：入力した数字
  COL_SELECT_O = Color.new(32, 240, 32)       # 選択肢：選択した項目
  COL_SELECT_X = Color.new(32, 240, 32, 128)  # 選択肢：選択しなかった項目

end
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::Log
  REG_LOG = /^<メッセージログ>/
  REG_SECRET_LOG = /^<秘密ログ>/
end

class Game_Message
  #--------------------------------------------------------------------------
  # ● ログの配列 (行単位)
  #--------------------------------------------------------------------------
  def logs
    @logs ||= []
  end
  #--------------------------------------------------------------------------
  # ● 古いログを削除
  #--------------------------------------------------------------------------
  def adjust_log
    @logs.shift while @logs.size > CAO::Log::MAX_LOG
  end
  #--------------------------------------------------------------------------
  # ● ログの記録
  #--------------------------------------------------------------------------
  def set_log(text, color = nil)
    if text.is_a?(Array)
      @logs.concat(color ? text.map {|s| "\\C[#{color}]#{s}" } : text)
    else
      @logs.push(color ? "\\C[#{color}]#{text}" : text)
    end
    adjust_log
  end
end

if $CAO_EX108I
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ 注釈の処理
  #--------------------------------------------------------------------------
  alias _cao_log_command_108 command_108
  def command_108
    case @parameters.first
    when CAO::Log::REG_LOG
      $game_message.set_log(@parameters[1...@parameters.size])
    when CAO::Log::REG_SECRET_LOG
      for text in @parameters[1...@parameters.size]
        $game_message.set_log("\\S#{text}")
      end
    else
      return _cao_log_command_108
    end
  end
end
end # if $CAO_EX108I

class Window_Message
  #--------------------------------------------------------------------------
  # ○ メッセージの終了
  #--------------------------------------------------------------------------
  alias _cao_log_terminate_message terminate_message
  def terminate_message
    unless $game_switches[CAO::Log::OFF_SW_NUM] || $game_temp.in_battle
      # 制御文字と除外文字の削除
      texts = []
      for text in Marshal.load(Marshal.dump($game_message.texts))
        @text = text
        CAO::Log::EXCEPTS_TEXT.each {|r| @text.gsub!(r, "") }
        convert_special_characters
        @text.gsub!(/[\x00-\x1F\x7F-\xBF](?:\[.+?\])?/, "")
        texts << @text
      end
      @text = nil
      # 文章を保存
      if $game_message.choice_proc != nil
        for i in 0...texts.size
          if i < $game_message.choice_start
            $game_message.set_log(texts[i])
          elsif Input.trigger?(Input::C)
            text = (i - $game_message.choice_start == self.index) ? '\O':'\X'
            $game_message.set_log("#{text}  #{texts[i]}")
          else
            if $game_message.choice_cancel_type == 5
              text = '\X'
            else
              cmd = i - $game_message.choice_start
              text = (cmd == $game_message.choice_cancel_type + 1) ? '\O':'\X'
            end
            $game_message.set_log("#{text}  #{texts[i]}")
          end
        end
      else
        $game_message.set_log(texts)
      end
      if @number_input_window.active
        $game_message.set_log("\\N  #{@number_input_window.number}")
      end
    end
    _cao_log_terminate_message
  end
end

class Window_MessageLog < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, 544, 416)
    self.z = 10100
    self.active = false
    self.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の作成
  #--------------------------------------------------------------------------
  def create_contents
    @item_max = $game_message.logs.size
    self.contents.dispose
    self.contents = Bitmap.new(width - 32, [height - 32, row_max * WLH].max)
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    create_contents
    self.bottom_row = self.row_max - 1
    self.top_row = 0 if self.row_max < self.page_row_max
    $game_message.logs.each_with_index do |s,i|
      text = s.sub(/^\\([SNOXC])/, "")
      case $1
      when "S"
        self.contents.font.color = CAO::Log::COL_SECRET
      when "N"
        self.contents.font.color = CAO::Log::COL_NUMBER
      when "O"
        self.contents.font.color = CAO::Log::COL_SELECT_O
      when "X"
        self.contents.font.color = CAO::Log::COL_SELECT_X
      when "C"
        text.sub!(/^\[(\d+)\]/, "")
        self.contents.font.color = text_color($1.to_i)
      else
        self.contents.font.color = normal_color
      end
      self.contents.draw_text(0, WLH * i, self.contents.width, WLH, text)
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    return unless self.active
    last_oy = self.oy
    if Input.repeat?(Input::DOWN)
      cursor_down
    end
    if Input.repeat?(Input::UP)
      cursor_up
    end
    if Input.repeat?(Input::R)
      cursor_pagedown
    end
    if Input.repeat?(Input::L)
      cursor_pageup
    end
    if self.oy != last_oy
      Sound.play_cursor
    end
  end
  #--------------------------------------------------------------------------
  # ● 行数の取得
  #--------------------------------------------------------------------------
  def row_max
    return [1, @item_max].max
  end
  #--------------------------------------------------------------------------
  # ● 先頭の行の取得
  #--------------------------------------------------------------------------
  def top_row
    return self.oy / WLH
  end
  #--------------------------------------------------------------------------
  # ● 先頭の行の設定
  #     row : 先頭に表示する行
  #--------------------------------------------------------------------------
  def top_row=(row)
    row = 0 if row < 0
    row = final_top_row if row > final_top_row
    self.oy = row * WLH
  end
  #--------------------------------------------------------------------------
  # ● 1 ページに表示できる行数の取得
  #--------------------------------------------------------------------------
  def page_row_max
    return (self.height - 32) / WLH
  end
  #--------------------------------------------------------------------------
  # ● 最終先頭行の取得
  #--------------------------------------------------------------------------
  def final_top_row
    return [0, row_max - page_row_max].max
  end
  #--------------------------------------------------------------------------
  # ● 末尾の行の取得
  #--------------------------------------------------------------------------
  def bottom_row
    return top_row + page_row_max - 1
  end
  #--------------------------------------------------------------------------
  # ● 末尾の行の設定
  #     row : 末尾に表示する行
  #--------------------------------------------------------------------------
  def bottom_row=(row)
    self.top_row = row - (page_row_max - 1)
  end
  #--------------------------------------------------------------------------
  # ● カーソルを下に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_down
    self.bottom_row = self.bottom_row + 1
  end
  #--------------------------------------------------------------------------
  # ● カーソルを上に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_up
    self.top_row = self.top_row - 1
  end
  #--------------------------------------------------------------------------
  # ● カーソルを 1 ページ後ろに移動
  #--------------------------------------------------------------------------
  def cursor_pagedown
    self.top_row += page_row_max if top_row + page_row_max < row_max
  end
  #--------------------------------------------------------------------------
  # ● カーソルを 1 ページ前に移動
  #--------------------------------------------------------------------------
  def cursor_pageup
    self.top_row -= page_row_max if top_row > 0
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  alias _cao_log_start start
  def start
    _cao_log_start
    @log_window = Window_MessageLog.new
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  alias _cao_log_terminate terminate
  def terminate
    _cao_log_terminate
    @log_window.dispose
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_log_update update
  def update
    if Input.trigger?(CAO::Log::SHOW_BUTTON) &&
                                    !$game_switches[CAO::Log::DISABLE_SW_NUM]
      @log_window.active ^= true
      if @log_window.active
        @log_window.open
        @log_window.refresh
      else
        @log_window.close
      end
    end
    @log_window.update
    _cao_log_update if @log_window.openness == 0
  end
end
