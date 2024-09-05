#=============================================================================
#  [RGSS2] メッセージロール - v2.3.0
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

  文章をスクロールさせる機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、割り込みシーン が別途必要になります。
  ※ メッセージのスクロールが終了するまで、画面は停止します。
  ※ 縦書きの場合、アイコンは横向きで表示されます。
  ※ 太字で増えた幅は、どの処理でも考慮されません。

 -- 使用方法 ----------------------------------------------------------------

  ★ 文章のスクロールを開始（ラベル）
   Ｍロール：key, mode
     key     : テキスト設定で設定したもの（文字列のみ）
     mode    : 横:横書き  縦:縦書き

  ★ 文章のスクロールを開始（スクリプト）
   Scene_Roll.new(key, mode)
     key     : テキスト設定で設定したもの
     mode    : 0:横書き（省略時）  1:縦書き

  ★ 制御文字
   \V[n]     : 変数の値
   \N[0]     : パーティ名
   \N[n]     : アクター名
   \C[n]     : 文字色の変更
   \I[n]     : アイコンの描画
   \L[n]     : アラインメント (0:左揃え、1:中央揃え、2:右揃え)
   \M[n]     : 余白の大きさを変更 (横文字：左右余白、縦文字：上下余白)
   \S[n]     : 次の文字の描画位置をずらす (マイナス値可)
   \B...\/B  : 囲まれた文字を太字

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO_ROLL
  #--------------------------------------------------------------------------
  # ◇ メッセージロールの早送り（Ｃボタン）
  #--------------------------------------------------------------------------
  FAST_FEED = true
  #--------------------------------------------------------------------------
  # ◇ メッセージロールの省略（Ｂボタン）
  #--------------------------------------------------------------------------
  TERMINATION = true
  #--------------------------------------------------------------------------
  # ◇ 移動する距離
  #--------------------------------------------------------------------------
  SPEED = 1
  #--------------------------------------------------------------------------
  # ◇ 移動する間隔
  #--------------------------------------------------------------------------
  WAIT = 2
  #--------------------------------------------------------------------------
  # ◇ 早送りするスピード
  #--------------------------------------------------------------------------
  ADD_SPEED = 5
  #--------------------------------------------------------------------------
  # ◇ フォント設定
  #--------------------------------------------------------------------------
  TEXT_FONT = ["UmePlus Gothic", "@ＭＳ Ｐ明朝"]
  #--------------------------------------------------------------------------
  # ◇ テキスト設定
  #--------------------------------------------------------------------------
  BASE_TEXT = {
    "sample" => [
      '\M[8]１２３４５６７８９1011121314151617181920212223242526',
      '',
      '\L[1]- 描画テスト中 -',
      '\L[2]右寄せだと文字数が多いと最初の文字が消えます。',
      '\L[0]文字寄せ機能を使った後は元に戻してください。',
      '',
      '\L[1]= 文字色変更テスト =',
      '\C[8]◆ \C[9]◆ \C[10]◆ \C[11]◆ \C[12]◆ \C[13]◆ \C[14]◆ \C[15]◆',
      '\L[0]\C[0]',
      '\B太字を使用すると幅が広がりますが、',
      '\L[2]どの処理でも考慮されません。\/B',
      '\L[0]',
      'ああ\B太字\/B\S[2]\I[10] \N[0] : \V[3]',
      'Tset Message. Hello, World!',
      '\I[2]\I[16] \I[133]ABCD\I[169] \I[224]\I[240]\S[-24]\I[112]',
      '',
      'これで、テストを終了いたします。'
    ],
  }

end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


begin
  $data_message_roll = load_data("Data/MessageRoll.rvdata") unless $!
rescue Errno::ENOENT
  $data_message_roll = CAO_ROLL::BASE_TEXT
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● ラベル
  #--------------------------------------------------------------------------
  alias _cao_mroll_command_118 command_118
  def command_118
    if /^Ｍロール："(.+?)",\s?([縦横])/ =~ @params[0]
      return false if $game_message.visible
      Scene_Roll.new($1, $2 == "横" ? 0 : 1)
      return true
    end
    return _cao_mroll_command_118
  end
end

class Scene_Roll < Scene_Interrupt
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  WLH = 24
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     text_key : 
  #     mode     : 
  #--------------------------------------------------------------------------
  def initialize(text_key, mode = 0)
    check_error(text_key)
    @wait = 0
    @roll_mode = mode
    @contents_x = 0
    @contents_y = 0
    @text = $data_message_roll[text_key]
    @align = 0
    @margin = 0
    create_sprite
    @bitmap = Bitmap.new(554, WLH + 4)      # １行単位の文字画像
    @bitmap.font.name = CAO_ROLL::TEXT_FONT[@roll_mode]
    for i in 0...@text.size
      draw_message(i)
    end
    @text_sprite.angle = 270 if @roll_mode == 1
    super()
  end
  #--------------------------------------------------------------------------
  # ● スプライトの作成
  #--------------------------------------------------------------------------
  def create_sprite
    @text_sprite = Sprite.new
    @text_sprite.y = 416 if @roll_mode == 0
    @text_sprite.z = 300
    w = (@roll_mode == 0 ? 544 : 416)
    h = WLH * [1, @text.size].max
    @text_sprite.bitmap = Bitmap.new(w, h)  # 描画内容の画像 (全体)
  end
  #--------------------------------------------------------------------------
  # ● フレームの更新
  #--------------------------------------------------------------------------
  def update
    super
    if @wait == CAO_ROLL::WAIT || CAO_ROLL::WAIT == 0
      @wait = 0
      @text_sprite.oy += CAO_ROLL::SPEED
      if @roll_mode == 0
        @exit = @text_sprite.oy > 416 + @text_sprite.bitmap.height
      else
        @exit = @text_sprite.oy > 544 + @text_sprite.bitmap.height
      end
    end
    @wait += 1
    if CAO_ROLL::FAST_FEED && Input.press?(Input::C)
      @text_sprite.oy += CAO_ROLL::ADD_SPEED
    end
    if CAO_ROLL::TERMINATION && Input.trigger?(Input::B)
      @exit = true
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def terminate
    super
    @bitmap.dispose
    @text_sprite.bitmap.dispose
    @text_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ● 特殊文字の変換
  #--------------------------------------------------------------------------
  def convert_characters(text)
    text.gsub!(/\\V\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    text.gsub!(/\\N\[0\]/i)        { $game_party.name }
    text.gsub!(/\\N\[([0-9]+)\]/i) { $game_actors[$1.to_i].name }
    text.gsub!(/\\C\[([0-9]+)\]/i) { "\x00[#{$1}]" }
    text.gsub!(/\\B/)              { "\x01" }
    text.gsub!(/\\\/B/)            { "\x02" }
    text.gsub!(/\\I/)              { "\x03" }
    text.gsub!(/\\L\[([0-2]+)\]/i) { "\x04[#{$1}]" }
    text.gsub!(/\\M\[([0-9]+)\]/i) { "\x05[#{$1}]" }
    text.gsub!(/\\S\[(-?\d+)\]/i)  { "\x06[#{$1}]" }
    text.gsub!(/\\R\[([0-9]+)\]/i) { "\x07[#{$1}]" }
    return text
  end
  #--------------------------------------------------------------------------
  # ● 文章の描画
  #--------------------------------------------------------------------------
  def draw_message(index)
    text = convert_characters(@text[index].dup)
    loop do
      c = text.slice!(/./m)
      case c
      when nil
        case @align
        when 0
          x = @margin
        when 1
          x = (@text_sprite.bitmap.width - @contents_x) / 2
        when 2
          x = @text_sprite.bitmap.width - @contents_x - @margin
        end
        rect = Rect.new(0, 0, @contents_x + 10, WLH + 4)
        @text_sprite.bitmap.blt(x - 5, @contents_y - 2, @bitmap, rect) 
        @contents_x = 0
        @contents_y += WLH
        @bitmap.clear
        break
      when "\x00"
        text.sub!(/\[([0-9]+)\]/, "")
        @bitmap.font.color = text_color($1.to_i)
        next
      when "\x01"
        @bitmap.font.bold = true
      when "\x02"
        @bitmap.font.bold = false
      when "\x03"
        text.sub!(/\[(\d+)\]/, "")
        bitmap = Cache.system("Iconset")
        rect = Rect.new($1.to_i % 16 * 24, $1.to_i / 16 * 24, 24, 24)
        @bitmap.blt(@contents_x + 5, 2, bitmap, rect)
        @contents_x += 24
      when "\x04"
        text.sub!(/\[([0-2]+)\]/, "")
        @align = $1.to_i
      when "\x05"
        text.sub!(/\[([0-9]+)\]/, "")
        @margin = $1.to_i
      when "\x06"
        text.sub!(/\[(-?\d+)\]/, "")
        @contents_x += $1.to_i
      else
        @bitmap.draw_text(@contents_x + 5, 0, 40, WLH + 4, c)
        @contents_x += @bitmap.text_size(c).width
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 文字色の取得
  #--------------------------------------------------------------------------
  def text_color(n)
    x = 64 + (n % 8) * 8
    y = 96 + (n / 8) * 8
    return  Cache.system("Window").get_pixel(x, y)
  end
  #--------------------------------------------------------------------------
  # ● エラーの表示
  #--------------------------------------------------------------------------
  def check_error(text_key)
    unless $data_message_roll.key?(text_key)
      print "指定されたメッセージが見つかりません。"
      exit
    end
    unless $data_message_roll[text_key].is_a?(Array)
      print "メッセージの定義文が不正です。"
      exit
    end
    unless $data_message_roll[text_key][0].is_a?(String)
      print "メッセージが記述されていません。"
      exit
    end
  end
end
