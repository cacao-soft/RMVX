#=============================================================================
#  [RGSS2] ＜拡張＞ 名前入力の処理 ＋ マルチインプット - v1.0.4
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

  ★ 名前入力の処理
  ： 漢字、英数、独自定義文字を使用可能
  ： 半角カナには対応しません。
  ： 最大１９文字まで入力可能
  ： 定型文によるランダムネーム機能

  ★ マルチインプット
  ： 全角・半角で入力文字数を制限します。
  ： 半角カナ入力が可能になります。
  ： 最大文字数、全角１９文字・半角３８文字。

 -- 注意事項 ----------------------------------------------------------------

  ※ 旧バージョンにつき、一切のサポートをお断りいたします。
  ※ スクリプト利用者に向けての設定項目はありません。

 -- 使用方法 ----------------------------------------------------------------

  ★ 操作方法
   Ａ：文字選択・メニューの切り替え  ｜  Ｘ：確定
   Ｂ：キャンセル                    ｜  Ｙ：文字種変更
   Ｃ：入力・決定                    ｜  Ｚ：ランダムネーム
   Ｌ・Ｒ：ページ送り

  ★ アクターの名前を変更
   イベントコマンド「名前入力の処理」を実行

  ★ アクターの名前を変更（詳細設定）
   イベントコマンド「ラベル」に
     "Ａ名前入力：アクターＩＤ[, 最大文字数][, 歩行グラの有無(o|x)]" と記述

  ★ アクターの名前を変更
   イベントコマンド「ラベル」に "Ｖ文字入力：変数番号[, 最大文字数]" と記述

  ★ マルチインプットの使用
   すぐ下にある MULTI_INPUT の値を true にすることで使用できます。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   このスクリプトには設定項目はありません。                  #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO
module ExInput
  # マルチインプット
  MULTI_INPUT = false
  # 入力文字の中央揃え
  EDIT_NAME_CENTER = true
  # 名前入力数（省略時）
  DEFAULT_NAME_NUM = 6
  # 文字入力数（省略時）
  DEFAULT_VAR_NUM = 14
  # キー設定
  KEY_DECISION = Input::X   # 確定
  KEY_CAHNGE = Input::Y     # 文字種変更
  KEY_RANDOM = Input::Z     # ランダムネーム
  KEY_OPTION = Input::A     # オプション
  # オプションの項目名
  TEXT_CMD_OPTION = ["決 定", "キャンセル", "おまかせ", "文字種変更"]
end
end

class Window_NameInput < Window_Base
  #--------------------------------------------------------------------------
  # ○ 文字表
  #--------------------------------------------------------------------------
  HIRAGANA = [ 'あ','い','う','え','お',  'が','ぎ','ぐ','げ','ご',
               'か','き','く','け','こ',  'ざ','じ','ず','ぜ','ぞ',
               'さ','し','す','せ','そ',  'だ','ぢ','づ','で','ど',
               'た','ち','つ','て','と',  'ば','び','ぶ','べ','ぼ',
               'な','に','ぬ','ね','の',  'ぱ','ぴ','ぷ','ぺ','ぽ',
               'は','ひ','ふ','へ','ほ',  'ぁ','ぃ','ぅ','ぇ','ぉ',
               'ま','み','む','め','も',  'っ','ゃ','ゅ','ょ','ゎ',
               'や', '' ,'ゆ', '' ,'よ',  'わ','を','ん','ゔ','☆',
               'ら','り','る','れ','ろ',  'ー','～','・',' ','　']
  KATAKANA = [ 'ア','イ','ウ','エ','オ',  'ガ','ギ','グ','ゲ','ゴ',
               'カ','キ','ク','ケ','コ',  'ザ','ジ','ズ','ゼ','ゾ',
               'サ','シ','ス','セ','ソ',  'ダ','ヂ','ヅ','デ','ド',
               'タ','チ','ツ','テ','ト',  'バ','ビ','ブ','ベ','ボ',
               'ナ','ニ','ヌ','ネ','ノ',  'パ','ピ','プ','ペ','ポ',
               'ハ','ヒ','フ','ヘ','ホ',  'ァ','ィ','ゥ','ェ','ォ',
               'マ','ミ','ム','メ','モ',  'ッ','ャ','ュ','ョ','ヮ',
               'ヤ', '' ,'ユ', '' ,'ヨ',  'ワ','ヲ','ン','ヴ','＝',
               'ラ','リ','ル','レ','ロ',  'ー','～','・',' ','　']
  TABLE = [HIRAGANA, KATAKANA]
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_ExInput command_118
  def command_118
    case @params[0]
    when /^Ａ名前入力：\s?(\d+)(?:,\s?([1]?\d))?(?:,\s?([ox]))?/i
      $game_temp.next_scene = "name"
      $game_temp.name_actor_id = $1.to_i
      $game_temp.name_max_char = $2 ? $2.to_i : CAO::ExInput::DEFAULT_NAME_NUM
      $game_temp.name_type = :actor
      $game_temp.name_walk = $3 == "o" ? true : false if $3
      return true
    when /^Ｖ文字入力：\s?(\d+)(?:,\s?([1]?\d))?/i
      $game_temp.next_scene = "name"
      $game_temp.name_actor_id = $1.to_i
      $game_temp.name_max_char = $2 ? $2.to_i : CAO::ExInput::DEFAULT_VAR_NUM
      $game_temp.name_type = :variable
      $game_temp.name_walk = false
      return true
    end
    _cao_command_118_ExInput
  end
end

class Game_Temp
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :name_type
  attr_accessor :name_walk
  attr_accessor :name_nothing
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_name initialize
  def initialize
    @name_type = :actor
    @name_walk = true
    @name_nothing = false
    _cao_initialize_name
  end
  #--------------------------------------------------------------------------
  # ◎ 名前入力の初期化
  #--------------------------------------------------------------------------
  def initialize_name
    @name_type = :actor
    @name_walk = true
    @name_nothing = false
  end
end

class Window_NameEdit < Window_Base
  #--------------------------------------------------------------------------
  # ◎ 定数
  #--------------------------------------------------------------------------
  FIXED_PHRASE = []                       # 定型名
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     actor    : アクター
  #     max_char : 最大文字数
  #--------------------------------------------------------------------------
  def initialize(actor, max_char)
    w = [max_char * 24 + ($game_temp.name_walk ? 68 : 32), 368].max
    super((544 - w) / 2, 16, w, 64)
    self.active = false
    if actor.is_a?(Game_Actor)
      @actor = actor
      @name = actor.name
    else
      @actor = $game_variables[$game_temp.name_actor_id]
      @name = @actor.is_a?(String) ? @actor : ""
    end
    @max_char = max_char        # 最大入力文字数
    name_array = @name.split(//)[0...@max_char]
    @name = name_array.to_s     # 入力文字
    @default_name = @name       # 最初の入力文字
    @index = name_array.size
    refresh
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ◎ 入力可能判定
  #     text : 入力する文字
  #--------------------------------------------------------------------------
  def can_input?(text = "")
    return @index < @max_char
  end
  #--------------------------------------------------------------------------
  # ◎ 歩行グラを表示した際のズレ幅
  #--------------------------------------------------------------------------
  def margin_graphics
    if CAO::ExInput::EDIT_NAME_CENTER
      gw = ($game_temp.name_walk ? 36 : 0)
      return (self.contents.width - @max_char * 24 - gw) / 2
    else
      return 0
    end
  end
  #--------------------------------------------------------------------------
  # ○ 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new(0, 0, 0, 0)
    gw = ($game_temp.name_walk ? 36 : 0)
    rect.x = index * 24 + gw + margin_graphics
    rect.y = 6
    rect.width = 24
    rect.height = WLH
    return rect
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    draw_actor_graphic(@actor, 16, 32) if $game_temp.name_walk
    name_array = @name.split(//)
    for i in 0...@max_char
      c = name_array[i]
      c = '_' if c == nil
      self.contents.draw_text(item_rect(i), c, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ○ カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    if @index < 0 || !can_input?
      self.cursor_rect.empty
    else
      self.cursor_rect = item_rect(@index)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 定型名のランダム取得
  #--------------------------------------------------------------------------
  def random_name
    if FIXED_PHRASE != []
      @name = FIXED_PHRASE[rand(FIXED_PHRASE.size)]
      if @name.split(//).size > @max_char
        @name = @name.split(//)[0, @max_char].join
      end
      @index = @name.split(//).size
      refresh
      return true
    end
    return false
  end
end

class Window_NameInput < Window_Base
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :setect_key
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     mode : 初期入力モード (0 = ひらがな、1 = カタカナ)
  #--------------------------------------------------------------------------
  def initialize(mode = 0)
    super(88, 96, 368, 248)
    @mode = mode
    @screen = []
    @index = 0
    refresh
    update_cursor
  end
  def create_contents
    self.contents.dispose
    @mode = 0 unless @mode
    @setect_key = "" unless mode_hash?
    @item_max = (mode_hash? ? TABLE[@mode][@setect_key] : TABLE[@mode]).size
    @index = 0 if (@index && @index >= @item_max) || setect_key != ""
    self.oy = 0 if @item_max <= 90
    row = @item_max / 10 + (@item_max % 10 == 0 ? 0 : 1)
    self.contents = Bitmap.new(width - 32, row * WLH)
    update_cursor if @index
  end
  #--------------------------------------------------------------------------
  # ○ 文字の取得
  #--------------------------------------------------------------------------
  def character
    if mode_hash?
      if @setect_key == ""
        @setect_key = TABLE[@mode][@setect_key][@index]
        return ""
      else
        return TABLE[@mode][@setect_key][@index]
      end
    else
      return TABLE[@mode][@index]
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 漢字モードか判定
  #--------------------------------------------------------------------------
  def mode_hash?
    return TABLE[@mode].class == Hash
  end
  #--------------------------------------------------------------------------
  # ◎ キーの選択
  #--------------------------------------------------------------------------
  def get_key
    @screen = [@index, self.oy]
    @setect_key = TABLE[@mode][0][@index]
  end
  #--------------------------------------------------------------------------
  # ◎ キーを解除
  #--------------------------------------------------------------------------
  def clear_key
    @setect_key = ""
    if mode_hash?
      @index = @screen[0]
      self.oy = @screen[1]
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    create_contents
    table = mode_hash? ? TABLE[@mode][@setect_key] : TABLE[@mode]
    for i in 0...@item_max
      rect = item_rect(i)
      rect.x += 2
      rect.width -= 4
      text = convert_text(table[i])
      self.contents.draw_text(rect, text, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 表示文字の変換
  #--------------------------------------------------------------------------
  def convert_text(text)
      case text
      when " "
        text = "半空"
      when "　"
        text = "全空"
      when "BS"##
        text = "消去"
      end
    return text
  end
  #--------------------------------------------------------------------------
  # ◎ 次の文字種へ
  #--------------------------------------------------------------------------
  def next_mode
    @mode = (@mode + 1) % TABLE.size
    @table = TABLE[@mode].class == Hash ? TABLE[@mode][0] : TABLE[@mode]
    refresh
  end
  #--------------------------------------------------------------------------
  # ◎ カーソルを下に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_down(wrap)
    if @index < @item_max - 10
      @index += 10
    elsif wrap
      @index -= @item_max - 10
    end
    @index = [0, [@index, @item_max - 1].min].max
  end
  #--------------------------------------------------------------------------
  # ◎ カーソルを上に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_up(wrap)
    if @index >= 10
      @index -= 10
    elsif wrap
      @index += @item_max - 10
    end
    @index = [0, [@index, @item_max - 1].min].max
  end
  #--------------------------------------------------------------------------
  # ◎ カーソルを右に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_right(wrap)
    if @index % 10 < 9
      @index += 1
    elsif wrap
      @index -= 9
    end
    @index = [0, [@index, @item_max - 1].min].max
  end
  #--------------------------------------------------------------------------
  # ◎ カーソルを左に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_left(wrap)
    if @index % 10 > 0
      @index -= 1
    elsif wrap
      @index += 9
    end
    @index = [0, [@index, @item_max - 1].min].max
  end
  #--------------------------------------------------------------------------
  # ◎ カーソルを 1 ページ後ろに移動
  #--------------------------------------------------------------------------
  def cursor_pagedown
    if top_row + 9 < row_max
      @index = [@index + 90, @item_max - 1].min
      self.top_row += 9
    end
  end
  #--------------------------------------------------------------------------
  # ◎ カーソルを 1 ページ前に移動
  #--------------------------------------------------------------------------
  def cursor_pageup
    if top_row > 0
      @index = [@index - 90, 0].max
      self.top_row -= 9
    end
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    last_mode = @mode
    last_index = @index
    if Input.trigger?(CAO::ExInput::KEY_CAHNGE)
      next_mode
    end
    if Input.repeat?(Input::DOWN)
      cursor_down(Input.trigger?(Input::DOWN))
    end
    if Input.repeat?(Input::UP)
      cursor_up(Input.trigger?(Input::UP))
    end
    if Input.repeat?(Input::RIGHT)
      cursor_right(Input.trigger?(Input::RIGHT))
    end
    if Input.repeat?(Input::LEFT)
      cursor_left(Input.trigger?(Input::LEFT))
    end
    if Input.trigger?(Input::L)
      cursor_pageup
    end
    if Input.trigger?(Input::R)
      cursor_pagedown
    end
    if @index != last_index or @mode != last_mode
      Sound.play_cursor
    end
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    row = @index / 10
    self.top_row = row if row < top_row
    self.bottom_row = row if row > bottom_row
    rect = item_rect(@index)
    rect.y -= self.oy
    self.cursor_rect = rect
  end
  #--------------------------------------------------------------------------
  # ● カーソル位置の設定
  #     index : 新しいカーソル位置
  #--------------------------------------------------------------------------
  def index=(index)
    @index = [index, @item_max - 1].min
    update_cursor
    call_update_help
  end
  #--------------------------------------------------------------------------
  # ● 行数の取得
  #--------------------------------------------------------------------------
  def row_max
    return (@item_max + 9) / 10
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
    row = row_max - 1 if row > row_max - 1
    self.oy = row * WLH
  end
  #--------------------------------------------------------------------------
  # ● 末尾の行の取得
  #--------------------------------------------------------------------------
  def bottom_row
    return top_row + 8
  end
  #--------------------------------------------------------------------------
  # ● 末尾の行の設定
  #     row : 末尾に表示する行
  #--------------------------------------------------------------------------
  def bottom_row=(row)
    self.top_row = row - 8
  end
end

class Window_NameOption < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :commands
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x       : ウィンドウの X 座標
  #     y       : ウィンドウの Y 座標
  #     width   : ウィンドウの幅
  #     height  : ウィンドウの高さ
  #     spacing : 横に項目が並ぶときの空白の幅
  #--------------------------------------------------------------------------
  def initialize
    super(88, 344, 368, 56, 8)
    @commands = CAO::ExInput::TEXT_CMD_OPTION
    @item_max = @commands.size
    @column_max = 4
    refresh
    self.active = false
    self.index = 0
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index   : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    self.contents.clear_rect(rect)
    self.contents.font.color = normal_color
    if index == 2 && Window_NameEdit::FIXED_PHRASE.empty?
      self.contents.font.color.alpha = 128
    end
    self.contents.draw_text(rect, @commands[index], 1)
  end
end

class Scene_Name < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    @actor = $game_actors[$game_temp.name_actor_id]
    if $game_temp.name_type == :actor
      @edit_window = Window_NameEdit.new(@actor, $game_temp.name_max_char)
    else
      @edit_window = Window_NameEdit.new(0, $game_temp.name_max_char)
    end
    @input_window = Window_NameInput.new
    @option_window = Window_NameOption.new
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    @edit_window.dispose
    @input_window.dispose
    @option_window.dispose
  end
  #--------------------------------------------------------------------------
  # ○ 元の画面へ戻る
  #--------------------------------------------------------------------------
  def return_scene
    $game_temp.initialize_name
    $scene = Scene_Map.new
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    @edit_window.update
    if @input_window.active
      @input_window.update
      update_input
    elsif @option_window.active
      @option_window.update
      update_option
    end
    if Input.trigger?(CAO::ExInput::KEY_DECISION)
      decision
    elsif Input.trigger?(CAO::ExInput::KEY_RANDOM)
      random_name
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 文字入力の更新
  #--------------------------------------------------------------------------
  def update_input
    if Input.trigger?(CAO::ExInput::KEY_OPTION)
      @input_window.active = false
      @option_window.active = true
    elsif Input.repeat?(Input::B)
      if @input_window.setect_key != ""
        @input_window.clear_key
      else
        back_character
      end
    elsif Input.trigger?(Input::C)
      if @input_window.setect_key == "" && @input_window.mode_hash?
        @input_window.get_key
        @input_window.refresh
      else
        add_character(@input_window.character)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ オプションウィンドウの更新
  #--------------------------------------------------------------------------
  def update_option
    if Input.trigger?(CAO::ExInput::KEY_OPTION) || Input.trigger?(Input::B)
      @option_window.active = false
      @input_window.active = true
    elsif Input.trigger?(Input::C)
      case @option_window.index
      when 0
        decision
      when 1
        @edit_window.restore_default
        if @edit_window.name != "" || $game_temp.name_nothing
          Sound.play_decision
          return_scene
        else
          Sound.play_buzzer
        end
      when 2
        random_name
      when 3
        Sound.play_decision
        @input_window.next_mode
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 文字入力
  #--------------------------------------------------------------------------
  def add_character(text)
    case text
    when "BS"
      back_character
    else
      if @edit_window.can_input?(text)
        Sound.play_decision
        @edit_window.add(text)
        @input_window.clear_key
      else
        Sound.play_buzzer
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 一文字削除
  #--------------------------------------------------------------------------
  def back_character
    if @edit_window.index > 0
      Sound.play_cancel
      @edit_window.back
    else
      Sound.play_buzzer
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 文字の決定
  #--------------------------------------------------------------------------
  def decision
    if @edit_window.name == ""
      @edit_window.restore_default
      if @edit_window.name != "" || $game_temp.name_nothing
        Sound.play_decision
        return_scene
      else
        Sound.play_buzzer
      end
    else
      Sound.play_decision
      if $game_temp.name_type == :actor
        @actor.name = @edit_window.name
      else
        $game_variables[$game_temp.name_actor_id] = @edit_window.name
      end
      return_scene
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 名前に定型名を設定
  #--------------------------------------------------------------------------
  def random_name
    if $game_temp.name_max_char > 3
      @edit_window.random_name ? Sound.play_decision : Sound.play_buzzer
    else
      Sound.play_buzzer
    end
  end
end


if CAO::ExInput::MULTI_INPUT
class Window_NameEdit < Window_Base
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     actor    : アクター
  #     max_char : 最大文字数
  #--------------------------------------------------------------------------
  def initialize(actor, max_char)
    w = [max_char * 24 + ($game_temp.name_walk ? 68 : 32), 368].max
    super((544 - w) / 2, 16, w, 64)
    if actor.is_a?(Game_Actor)
      @actor = actor
      @name = actor.name
    else
      @actor = $game_variables[$game_temp.name_actor_id]
      @name = @actor.is_a?(String) ? @actor : ""
    end
    @max_char = max_char        # 最大入力文字数
    @max_half = @max_char * 2   # 最大入力文字数（半角）
    name_array = []
    size = 0
    for s in @name.split(//)
      size += char_size(s)
      break if @max_half < size
      name_array.push(s)
    end
    @name = name_array.to_s
    @default_name = @name
    @index = name_array.size
    self.active = false
    refresh
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ○ 文字の追加
  #     character : 追加する文字
  #--------------------------------------------------------------------------
  def add(character)
    if can_input?(character) and character != ""
      @name += character
      @index += character.split(//).size
      refresh
      update_cursor
    end
  end
  #--------------------------------------------------------------------------
  # ○ 文字の削除
  #--------------------------------------------------------------------------
  def back
    if @index > 0
      name_array = @name.split(//)          # 一字削除
      @name = ""
      for i in 0...name_array.size-1
        @name += name_array[i]
      end
      @index -= 1
      refresh
      update_cursor
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 全角・半角の判定（サイズ）
  #--------------------------------------------------------------------------
  def char_size(str)
    return (str.nil? || str.size == 1 || str.match(/^[｡-ﾟ]$/)) ? 1 : 2
  end
  #--------------------------------------------------------------------------
  # ◎ 半角に換算した場合の文字列のサイズ
  #--------------------------------------------------------------------------
  def half_size(name)
    size = 0
    name_array = name.split(//)
    for c in name_array
      size += char_size(c)
    end
    return size
  end
  #--------------------------------------------------------------------------
  # ◎ 半角に換算した場合の文字配列
  #--------------------------------------------------------------------------
  def half_array
    name_array = @name.split(//)
    half_array = []
    for c in name_array
      half_array.push(c)
      half_array.push(c) if char_size(c) == 2
    end
    return half_array
  end
  #--------------------------------------------------------------------------
  # ◎ 入力可能判定
  #--------------------------------------------------------------------------
  def can_input?(str = "")
    if str && str != ""
      return char_size(str) <= (@max_half - half_size(@name))
    else
      return half_size(@name) < @max_half
    end
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    draw_actor_graphic(@actor, 16, 32) if $game_temp.name_walk
    name_array = @name.split(//)
    gw = ($game_temp.name_walk ? 36 : 0)
    rect = Rect.new(0, 6, 12, WLH)
    last_name = ""
    for i in 0...name_array.size
      rect.x = 12 * half_size(last_name) + gw + margin_graphics
      rect.width = 12 * char_size(name_array[i])
      self.contents.draw_text(rect, name_array[i], 1)
      last_name += name_array[i]
    end
    rect.width = 12
    for i in 0...((@max_char * 2) - half_size(last_name))
      rect.x = 12 * (i + half_size(last_name)) + gw + margin_graphics
      self.contents.draw_text(rect, '_', 1)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    name_array = @name.split(//)
    lw = 0
    for i in 0...index
      lw += 12 * char_size(name_array[i])
    end
    rect = Rect.new(0, 0, 0, 0)
    rect.x = lw + ($game_temp.name_walk ? 36 : 0) + margin_graphics
    rect.y = 6
    rect.width = 12 * char_size(name_array[index])
    rect.height = WLH
    return rect
  end
  #--------------------------------------------------------------------------
  # ○ カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    if @index < 0 || !can_input?
      self.cursor_rect.empty
    else
      self.cursor_rect = item_rect(@index)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 定型名のランダム取得
  #--------------------------------------------------------------------------
  def random_name
    if FIXED_PHRASE != []
      name = FIXED_PHRASE[rand(FIXED_PHRASE.size)]
      @name = ""
      size = 0
      for s in name.split(//)
        size += char_size(s)
        break if @max_half < size
        @name.concat(s)
      end
      @index = @name.split(//).size
      refresh
      return true
    end
    return false
  end
end
end   # if CAO::ExInput::MULTI_INPUT
