#=============================================================================
#  [RGSS2] ＜拡張＞ 名前入力の処理 - v2.0.3
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

  - 漢字、英数、独自定義文字を使用可能
  - 半角カナには対応していません。
  - 定型文によるランダムネーム機能

 -- 注意事項 ----------------------------------------------------------------

  ※ 顔グラを表示する場合、最大文字数は１５文字までとなります。

 -- 使用方法 ----------------------------------------------------------------

  ★ アクターの名前を変更
   イベントコマンド「名前入力の処理」を実行

  ★ アクターの名前を変更（詳細設定）
   イベントコマンド「ラベル」に
     "Ａ名前入力：アクターＩＤ[, 最大文字数][, 歩行グラの有無(o|x)]" と記述

  ★ 変数に文字列を代入
   イベントコマンド「ラベル」に "Ｖ文字入力：変数番号[, 最大文字数]" と記述

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#               このスクリプトの設定は別ファイルで行います。                  #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO
module ExInput
  CMD_DECISION  = 0   # 決定
  CMD_CANCEL    = 1   # キャンセル
  CMD_BACK      = 2   # 一字削除
  CMD_SPACE     = 3   # 空白挿入
  CMD_DEFAULT   = 4   # 元に戻す
  CMD_RANDOM    = 5   # おまかせ
  CMD_NEXT_MODO = 6   # 次の文字種
  CMD_PREV_MODO = 7   # 前の文字種
end
end # module CAO

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
    when /^Ｖ文字入力：\s?(\d+)(?:,\s?([1]?\d))?/i
      $game_temp.next_scene = "name"
      $game_temp.name_actor_id = $1.to_i
      $game_temp.name_max_char = $2 ? $2.to_i : CAO::ExInput::DEFAULT_VAR_NUM
      $game_temp.name_type = :variable
      $game_temp.name_walk = false
    else
      return _cao_command_118_ExInput
    end
    return true
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
  #--------------------------------------------------------------------------
  def initialize(actor)
    case CAO::ExInput::EDIT_TYPE
    when 0  # 歩行グラ（中）
      super(22, 44, 500, 64)
    when 1  # 歩行グラ（下）
      super(22, 52, 500, 64)
    else    # 顔グラ
      super(22, 20, 500, 128)
    end
    self.active = false
    self.opacity = 0 unless CAO::ExInput::WINDOW_VISIBLE
    if actor.is_a?(Game_Actor)
      @actor = actor
      @name = actor.name
    else
      @actor = $game_variables[$game_temp.name_actor_id]
      @name = @actor.is_a?(String) ? @actor : ""
    end
    @max_char = $game_temp.name_max_char        # 最大入力文字数
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
      if $game_temp.name_walk
        if CAO::ExInput::EDIT_TYPE < 2
          return (self.contents.width - @max_char * 24 - 36) / 2
        else
          return (self.contents.width - @max_char * 24 - 100) / 2
        end
      end
      return (self.contents.width - @max_char * 24) / 2
    end
    return 0
  end
  #--------------------------------------------------------------------------
  # ○ 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    if CAO::ExInput::EDIT_TYPE < 2
      gw = ($game_temp.name_walk ? 36 : 0)
    else
      gw = ($game_temp.name_walk ? 100 : 0)
    end
    rect = Rect.new(0, 0, 0, 0)
    rect.x = index * 24 + gw + margin_graphics
    rect.y = (CAO::ExInput::EDIT_TYPE < 2) ? 6 : 38
    rect.width = 24
    rect.height = WLH
    return rect
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    if $game_temp.name_walk
      if CAO::ExInput::EDIT_TYPE < 2
        draw_actor_graphic(@actor, 16, 32)
      else
        draw_actor_face(@actor, 0, 0)
        draw_actor_graphic(@actor, 20, 92) if CAO::ExInput::EDIT_TYPE == 3
      end
    end
    self.contents.font.color = normal_color
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
  attr_reader   :index                    # カーソル位置
  attr_accessor :setect_key               # ハッシュキー
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(x, y)
    x += 116 if CAO::ExInput::POS_MENU_LEFT
    super(x, y, 368, 248)
    self.viewport = viewport
    self.active = !CAO::ExInput::POS_MENU_LEFT
    self.opacity = 0
    @index = 0 unless CAO::ExInput::POS_MENU_LEFT
    @mode = 0     # 入力中の文字種類
    @screen = []  # 
    refresh
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウ内容の作成
  #--------------------------------------------------------------------------
  def create_contents
    self.contents.dispose
    @mode = 0 unless @mode
    @setect_key = "" unless mode_hash?
    @item_max = (mode_hash? ? TABLE[@mode][@setect_key] : TABLE[@mode]).size
    @index = 0 if (@index && @index >= @item_max) || setect_key != ""
    self.oy = 0 if @item_max <= 90
    row = @item_max / 10 + (@item_max % 10 == 0 ? 0 : 1)
    self.contents = Bitmap.new(width - 32, row * WLH)
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
      if mode_hash? && @setect_key != "" && text.match(/[あ-ん]/)
        if CAO::ExInput::COLOR_KEY_HIRAGANA.is_a?(Integer)
          color = text_color(CAO::ExInput::COLOR_KEY_HIRAGANA)
        elsif CAO::ExInput::COLOR_KEY_HIRAGANA.is_a?(Color)
          color = CAO::ExInput::COLOR_KEY_HIRAGANA
        else
          color = system_color
        end
      else
        color = normal_color
      end
      self.contents.font.color = color
      self.contents.draw_text(rect, text, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 表示文字の変換
  #--------------------------------------------------------------------------
  def convert_text(text)
    case text
    when " "
      text = CAO::ExInput::TEXT_HALF_SPACE
    when "　"
      text = CAO::ExInput::TEXT_FULL_SPACE
    when "BS"
      text = CAO::ExInput::TEXT_BACK_SPACE
    end
    return text
  end
  #--------------------------------------------------------------------------
  # ◎ 文字種を変更
  #--------------------------------------------------------------------------
  def change_mode(value)
    @mode = value
    @table = TABLE[@mode].class == Hash ? TABLE[@mode][0] : TABLE[@mode]
    refresh
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
    @index += 1 if @index % 10 < 9
    @index = [0, [@index, @item_max - 1].min].max
  end
  #--------------------------------------------------------------------------
  # ◎ カーソルを左に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_left(wrap)
    @index -= 1 if @index % 10 > 0
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
      cursor_pageup if CAO::ExInput::IPT_BOTTON_L.nil?
    end
    if Input.trigger?(Input::R)
      cursor_pagedown if CAO::ExInput::IPT_BOTTON_R.nil?
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
  include CAO::ExInput
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
  def initialize(x, y)
    x += 352 unless CAO::ExInput::POS_MENU_LEFT
    super(x, y, 132, 248)
    self.viewport = viewport
    self.active = CAO::ExInput::POS_MENU_LEFT
    self.opacity = 0
    @commands = []
    for i in 0...9
      @commands << TEXT_CMD_OPTION[COMMAND_OPTIONS[i]] if COMMAND_OPTIONS[i]
    end
    @item_max = @commands.size
    refresh
    self.index = CAO::ExInput::POS_MENU_LEFT ? 0 : -1
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
    self.contents.draw_text(rect, @commands[index], 1)
  end
  #--------------------------------------------------------------------------
  # ● 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new(0, 0, 0, 0)
    rect.width = (contents.width + @spacing) / @column_max - @spacing
    rect.height = WLH
    rect.x = index % @column_max * (rect.width + @spacing)
    rect.y = index_to_line(index) / @column_max * WLH
    return rect
  end
  #--------------------------------------------------------------------------
  # ◎ wndOptionIndex to wndInputIndex
  #--------------------------------------------------------------------------
  def index_to_line(index)
    return COMMAND_OPTIONS.index(TEXT_CMD_OPTION.index(@commands[index]))
  end
  #--------------------------------------------------------------------------
  # ◎ wndInputIndex to wndOptionIndex
  #--------------------------------------------------------------------------
  def line_to_index(index)
    num = nil
    until num
      num = COMMAND_OPTIONS[index]
      index += 1
    end
    return @commands.index(TEXT_CMD_OPTION[num])
  end
  #--------------------------------------------------------------------------
  # ◎ 決定項目の行番号
  #--------------------------------------------------------------------------
  def get_decision_line
    return @commands.index(TEXT_CMD_OPTION[0])
  end
end

class Scene_Name < Scene_Base
  include CAO::ExInput
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    create_background
    # 文字数の調整
    num = $game_temp.name_max_char
    $game_temp.name_max_char = [num, (EDIT_TYPE < 2 ? 16 : 15)].min
    # 入力モードの判定
    if $game_temp.name_type == :actor   # 名前入力モード
      @actor = $game_actors[$game_temp.name_actor_id]
      @edit_window = Window_NameEdit.new(@actor)
    else  # 変数代入モード
      @edit_window = Window_NameEdit.new(0)
    end
    # ウィンドウ位置の調整
    case EDIT_TYPE
    when 0  # 歩行グラ（中）
      @dummy_window = Window_Base.new(22, 124, 500, 248) if WINDOW_VISIBLE
      @input_window = Window_NameInput.new(30, 124)
      @option_window = Window_NameOption.new(30, 124)
    when 1  # 歩行グラ（下）
      @dummy_window = Window_Base.new(22, 116, 500, 248) if WINDOW_VISIBLE
      @input_window = Window_NameInput.new(30, 116)
      @option_window = Window_NameOption.new(30, 116)
    else    # 顔グラ
      @dummy_window = Window_Base.new(22, 148, 500, 248) if WINDOW_VISIBLE
      @input_window = Window_NameInput.new(30, 148)
      @option_window = Window_NameOption.new(30, 148)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    @back_sprite.dispose if FILE_BACKIMAGE_NAME
    @front_sprite.dispose if FILE_FRONTIMAGE_NAME
    @edit_window.dispose
    @dummy_window.dispose if WINDOW_VISIBLE
    @input_window.dispose
    @option_window.dispose
  end
  #--------------------------------------------------------------------------
  # ◎ 各背景画像の作成
  #--------------------------------------------------------------------------
  def create_background
    # 背景画像の設定
    if FILE_BACKGROUND_NAME
      @menuback_sprite.bitmap = Cache.picture(FILE_BACKGROUND_NAME)
      @menuback_sprite.color.set(0, 0, 0, 0)
    end
    # ウィンドウ背景の設定
    if FILE_BACKIMAGE_NAME
      @back_sprite = Sprite.new
      @back_sprite.bitmap = Cache.picture(FILE_BACKIMAGE_NAME)
    end
    # 最前面画像の設定
    if FILE_FRONTIMAGE_NAME
      @front_sprite = Sprite.new
      @front_sprite.z = 210
      @front_sprite.bitmap = Cache.picture(FILE_FRONTIMAGE_NAME)
    end
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
    if @option_window.active
      @option_window.update
      update_option
    elsif @input_window.active
      if (Input.trigger?(Input::LEFT) && @input_window.index % 10 == 0) ||
              (Input.trigger?(Input::RIGHT) && @input_window.index % 10 == 9)
        @input_window.active = false
        @option_window.active = true
        index = @input_window.index / 10 - @input_window.top_row
        @option_window.index = @option_window.line_to_index(index)
      end
      @input_window.update
      update_input
      unless @input_window.active
        @input_window.cursor_rect.empty
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ オプションウィンドウの更新
  #--------------------------------------------------------------------------
  def update_option
    if Input.trigger?(Input::C)
      key = @option_window.commands[@option_window.index]
      case TEXT_CMD_OPTION.index(key)
      when CMD_DECISION   # 決定
        decision
      when CMD_CANCEL     # キャンセル
        cancel
      when CMD_BACK       # 一字削除
        back_character
      when CMD_SPACE      # 空白挿入
        add_character(ADD_SPACE)
      when CMD_DEFAULT    # 元に戻す
        push_key(:default)
      when CMD_RANDOM     # おまかせ
        random_name
      when CMD_NEXT_MODO  # 次の文字種
        push_key(:next_mode)
      when CMD_PREV_MODO  # 前の文字種
        push_key(:prev_mode)
      else                # 文字種変更
        Sound.play_decision
        @input_window.change_mode(TEXT_CMD_OPTION.index(key) - 10)
      end
    elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      @option_window.active = false
      @option_window.cursor_rect.empty
      @input_window.active = true
      option_index = @option_window.index_to_line(@option_window.index)
      now_row = [@input_window.row_max - @input_window.top_row, 9].min
      if option_index + 1 > now_row
        input_index = (now_row + @input_window.top_row - 1) * 10
      else
        input_index = (option_index + @input_window.top_row) * 10
      end
      @input_window.index = input_index + (Input.trigger?(Input::LEFT) ? 9 : 0)
    elsif Input.trigger?(Input::A)
      push_key(OPN_BOTTON_A)
    elsif Input.trigger?(Input::B)
      push_key(OPN_BOTTON_B)
     elsif Input.trigger?(Input::L)
       push_key(OPN_BOTTON_L)
     elsif Input.trigger?(Input::R)
       push_key(OPN_BOTTON_R)
     elsif Input.trigger?(Input::X)
       push_key(OPN_BOTTON_X)
     elsif Input.trigger?(Input::Y)
       push_key(OPN_BOTTON_Y)
     elsif Input.trigger?(Input::Z)
       push_key(OPN_BOTTON_Z)
     end
  end
  #--------------------------------------------------------------------------
  # ◎ 文字入力の更新
  #--------------------------------------------------------------------------
  def update_input
    if Input.repeat?(Input::B)
      if @input_window.setect_key != ""
        @input_window.clear_key
      else
        push_key(IPT_BOTTON_B)
      end
    elsif Input.trigger?(Input::C)
      if @input_window.setect_key == "" && @input_window.mode_hash?
        @input_window.get_key
        @input_window.refresh
      else
        add_character(@input_window.character)
      end
    elsif Input.trigger?(Input::A)
      push_key(IPT_BOTTON_A)
     elsif Input.trigger?(Input::L)
       push_key(IPT_BOTTON_L)
     elsif Input.trigger?(Input::R)
       push_key(IPT_BOTTON_R)
     elsif Input.trigger?(Input::X)
       push_key(IPT_BOTTON_X)
     elsif Input.trigger?(Input::Y)
       push_key(IPT_BOTTON_Y)
     elsif Input.trigger?(Input::Z)
       push_key(IPT_BOTTON_Z)
     end
  end
  #--------------------------------------------------------------------------
  # ◎ ショートカット処理
  #--------------------------------------------------------------------------
  def push_key(key)
    case key
    when :decision    # 決定項目へカーソル移動
      Sound.play_decision
      @input_window.cursor_rect.empty
      @input_window.active = false
      @option_window.active = true
      @option_window.index = @option_window.get_decision_line
    when :cancel      # 名前を元に戻して終了
      cancel
    when :back        # 一字削除
      back_character
    when :space       # 空白挿入
      add_character(ADD_SPACE)
    when :random      # ランダムネーム
      random_name
    when :default     # 入力前の名前に戻す
      Sound.play_cancel
      @edit_window.restore_default
    when :next_mode   # 次の文字種に変更
      Sound.play_decision
      @input_window.next_mode
    when :prev_mode   # 前の文字種に変更
      Sound.play_decision
      @input_window.prev_mode
    when /change_mode\((\d)\)/  # 指定した文字種に変更
      Sound.play_decision
      @input_window.change_mode($1.to_i)
    when /add_char\(\"(.)\"\)/  # 指定した１文字を入力
      add_character($1)
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
    if @edit_window.name == "" && !$game_temp.name_nothing
      Sound.play_buzzer
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
  # ◎ 入力処理の中断
  #--------------------------------------------------------------------------
  def cancel
    @edit_window.restore_default
    if @edit_window.name != "" || $game_temp.name_nothing
      Sound.play_cancel
      return_scene
    else
      Sound.play_buzzer
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
