#=============================================================================
#  [RGSS2] ＜拡張＞ セーブ画面 - v1.0.6
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

  セーブ画面にセーブ時のマップ画像やアクターの名前を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ Cacao Base Script を導入する必要があります。
  ※ Bitmap Class EX を導入する必要があります。

 -- そ の 他 ----------------------------------------------------------------

  ★ セーブファイルの場所
   実行ファイルと同じフォルダに Save フォルダを作成して保存しています。

=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO::ExSave
  #--------------------------------------------------------------------------
  # ◇ セーブフォルダを隠し属性で作成する
  #--------------------------------------------------------------------------
  #     テストプレイ中は隠し属性にはなりません。
  #--------------------------------------------------------------------------
  HIDDEN_DIRECTORY = true
  #--------------------------------------------------------------------------
  # ◇ 歩行グラフィックの背景色
  #--------------------------------------------------------------------------
  COLOR_CHARA_BACK = Color.new(255, 255, 255)
  #--------------------------------------------------------------------------
  # ◇ マップ画像の背景色
  #--------------------------------------------------------------------------
  COLOR_IMAGE_BACK = Color.new(0, 0, 0)
  #--------------------------------------------------------------------------
  # ◇ システム文字
  #--------------------------------------------------------------------------
  TEXT_MAP = "マップ名"
  #--------------------------------------------------------------------------
  # ◇ 削除ボタン
  #--------------------------------------------------------------------------
  #     削除機能を使用しない場合は nil としてください。
  #--------------------------------------------------------------------------
  DEF_KEY = Input::Y
  #--------------------------------------------------------------------------
  # ◇ 表示されるパーティの人数
  #--------------------------------------------------------------------------
  MAX_MEMBERS = 4
  #--------------------------------------------------------------------------
  # ◇ 削除の確認メッセージ
  #--------------------------------------------------------------------------
  #     ["確認文", "選択項目 はい", "選択項目 いいえ"]
  #--------------------------------------------------------------------------
  DEL_TEXT = ["セーブファイルを削除してもよろしいですか？", "はい", "いいえ"]
  #--------------------------------------------------------------------------
  # ◇ 削除時の効果音
  #--------------------------------------------------------------------------
  FILE_DELETE = "Collapse1"
  #--------------------------------------------------------------------------
  # ◇ 操作説明
  #--------------------------------------------------------------------------
  #     INFO_POS  : 説明文の表示位置 [x, y] の配列で指定
  #     INFO_TEXT : 説明文の文字列 (表示しない場合は、"" としてください。)
  #               : ファイルパスを指定すると 320x20 の画像を使用できます。
  #               : "./Pictures/filename" もしくは、"./System/filename"
  #--------------------------------------------------------------------------
  # 表示位置
  INFO_POS = [220, 396]
  # 説明文
  INFO_TEXT = "Ｙボタン：セーブファイル削除"
  #--------------------------------------------------------------------------
  # ◇ 確認メッセージの行幅 (24 以上)
  #--------------------------------------------------------------------------
  WLH = 32
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


# セーブファイル削除音
CAO::ExSave::SE_DELETE = RPG::SE.new(CAO::ExSave::FILE_DELETE, 80)

class Window_SaveFile < Window_Base
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :pngname                  # 画像ファイル名
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     file_index : セーブファイルのインデックス (0〜3)
  #     filename   : ファイル名
  #     pngname    : 画像ファイル名
  #--------------------------------------------------------------------------
  def initialize(file_index, filename, pngname)
    super(file_index % 2 * 272, 56 + file_index / 2 * 180, 272, 180)
    self.contents.font.size = 16
    @file_index = file_index
    @filename = filename
    @pngname = pngname
    load_gamedata
    refresh
    @selected = false
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = normal_color
    name = Vocab::File + " #{@file_index + 1}"
    self.contents.draw_text(4, 0, 112, WLH, name)
    @name_width = contents.text_size(name).width
    if @file_exist
      draw_image(0, WLH + 2)
      draw_playtime(124, 2, 112, 2)
      draw_party_characters(128, WLH + 2)
      draw_mapname(0, WLH * 5 + 4)
    end
  end
  #--------------------------------------------------------------------------
  # ○ パーティキャラの描画
  #     x : 描画先 X 座標
  #     y : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_party_characters(x, y)
    for i in 0...@characters.size
      break unless i < CAO::ExSave::MAX_MEMBERS
      dy = y + i * WLH
      name = @characters[i][0]
      index = @characters[i][1]
      self.contents.fill_rect(x+1, dy+1, 22, 22, CAO::ExSave::COLOR_CHARA_BACK)
      draw_character(name, index, x + 2, dy + 2)
      self.contents.draw_text(x + 26, dy, 86, WLH, character_name(i))
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 歩行グラフィックの描画
  #     character_name  : 歩行グラフィック ファイル名
  #     character_index : 歩行グラフィック インデックス
  #     x               : 描画先 X 座標
  #     y               : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_character(character_name, character_index, x, y)
    return if character_name == nil
    bitmap = Cache.character(character_name)
    sign = character_name[/^[\!\$]./]
    if sign != nil and sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    n = character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch + 4, 20, 20)
    src_rect.x += (cw - 20) / 2
    self.contents.blt(x, y, bitmap, src_rect)
  end
  #--------------------------------------------------------------------------
  # ● マップの描画
  #--------------------------------------------------------------------------
  def draw_image(x, y)
    if FileTest.exist?(@pngname)
      bitmap = Bitmap.new(@pngname)
      self.contents.blt(x, y, bitmap, bitmap.rect)
    else
      self.contents.fill_rect(x, y, 120, 96, CAO::ExSave::COLOR_IMAGE_BACK)
    end
  end
  #--------------------------------------------------------------------------
  # ● マップ名の描画
  #--------------------------------------------------------------------------
  def draw_mapname(x, y)
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 64, 20, CAO::ExSave::TEXT_MAP)
    self.contents.font.color = normal_color
    self.contents.draw_text(x+70, y, 170, 20, self.map_name)
  end
  #--------------------------------------------------------------------------
  # ● キャラクター名の取得
  #--------------------------------------------------------------------------
  def character_name(index)
    return "" unless @game_system.save_data[:party]
    return @game_system.save_data[:party][index] || ""
  end
  #--------------------------------------------------------------------------
  # ● マップ名の取得
  #--------------------------------------------------------------------------
  def map_name
    return @game_system.save_data[:map] || ""
  end
end

class Window_ExSaveCommand < Window_Selectable
  include CAO::ExSave
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  WLH = CAO::ExSave::WLH    # 行の高さ基準値 (Window Line Height)
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x       : ウィンドウの X 座標
  #     y       : ウィンドウの Y 座標
  #     width   : ウィンドウの幅
  #     height  : ウィンドウの高さ
  #     spacing : 横に項目が並ぶときの空白の幅
  #--------------------------------------------------------------------------
  def initialize
    super(72, 158, 420, WLH * 2 + 36)
    self.active = false
    self.openness = 0
    @opening = false            # ウィンドウのオープン中フラグ
    @closing = false            # ウィンドウのクローズ中フラグ
    @item_max = 2
    @column_max = 2
    @index = -1
    @spacing = 16
    refresh
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    self.active = self.openness != 0
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = normal_color
    self.contents.draw_text(0, 0, contents.width, WLH, DEL_TEXT[0], 1)
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index   : 項目番号
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item(index, enabled = true)
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    self.contents.clear_rect(rect)
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = enabled ? 255 : 128
    self.contents.draw_text(rect, DEL_TEXT[index + 1], 1)
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
    rect.y = index / @column_max * WLH + WLH + 4
    return rect
  end
end

class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  SAVE_DIRECTORY = 'Save'
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  alias _cao_start_exsave start
  def start
    _cao_start_exsave
    @command_window = Window_ExSaveCommand.new
    create_info_sprite
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  alias _cao_terminate_exsave terminate
  def terminate
    _cao_terminate_exsave
    @command_window.dispose
    dispose_info_sprite
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_update_exsave update
  def update
    if @command_window.active
      update_menu_background
      @command_window.update
      update_command_input
    else
      _cao_update_exsave
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def update_command_input
    if Input.trigger?(Input::C)
      Sound.play_decision
      if @command_window.index == 0
        CAO::ExSave::SE_DELETE.play unless CAO::ExSave::FILE_DELETE.empty?
        delete_file(@index)
        @savefile_windows[@index].load_gamedata
        @savefile_windows[@index].refresh
        return_scene if !@saving && !savefile_exist?
      end
      @command_window.close
    elsif Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.close
    end
  end
  #--------------------------------------------------------------------------
  # ● 説明文の生成
  #--------------------------------------------------------------------------
  def create_info_sprite
    @info_sprite = Sprite.new
    @info_sprite.x = CAO::ExSave::INFO_POS[0]
    @info_sprite.y = CAO::ExSave::INFO_POS[1]
    @info_sprite.z = 100
    @info_sprite.bitmap = Bitmap.new(320, 20)
    if /^\.\/(Pictures|System)\/(.+)/i =~ CAO::ExSave::INFO_TEXT
      directory, filename = $1, $2
      case directory.downcase
      when "pictures"
        bmp = Cache.picture(filename)
      when "system"
        bmp = Cache.system(filename)
      end
      @info_sprite.bitmap.blt(0, 0, bmp, bmp.rect)
    else
      @info_sprite.bitmap.font.size = 14
      @info_sprite.bitmap.draw_text(0, 0, 320, 20, CAO::ExSave::INFO_TEXT, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● 説明文の解放
  #--------------------------------------------------------------------------
  def dispose_info_sprite
    @info_sprite.bitmap.dispose
    @info_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ○ セーブファイルウィンドウの作成
  #--------------------------------------------------------------------------
  def create_savefile_windows
    @savefile_windows = []
    for i in 0..3
      obj = Window_SaveFile.new(i, make_filename(i), make_pngname(i))
      @savefile_windows.push(obj)
    end
    @item_max = 4
  end
  #--------------------------------------------------------------------------
  # ○ セーブファイル選択の更新
  #--------------------------------------------------------------------------
  def update_savefile_selection
    if Input.trigger?(Input::C)
      determine_savefile
    elsif Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene
    elsif CAO::ExSave::DEF_KEY && Input.trigger?(CAO::ExSave::DEF_KEY)
      if @savefile_windows[@index].file_exist
        Sound.play_decision
        @command_window.open
        @command_window.active = true
        @command_window.index = 0
      else
        Sound.play_buzzer
      end
    else
      last_index = @index
      if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
        @index = (@index + 2) % @item_max
      end
      if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
        @index += (@index % 2 == 0 ? 1 : -1)
      end
      if @index != last_index
        Sound.play_cursor
        @savefile_windows[last_index].selected = false
        @savefile_windows[@index].selected = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● セーブファイルの有無判定
  #--------------------------------------------------------------------------
  def savefile_exist?
    return Dir.glob(SAVE_DIRECTORY + '/*.rvdata').size > 0
  end
  #--------------------------------------------------------------------------
  # ○ セーブファイル名の作成
  #     file_index : セーブファイルのインデックス (0〜3)
  #--------------------------------------------------------------------------
  def make_filename(file_index)
    return SAVE_DIRECTORY + "/#{file_index + 1}.rvdata"
  end
  #--------------------------------------------------------------------------
  # ● 画像ファイル名の作成
  #     file_index : セーブファイルのインデックス (0〜3)
  #--------------------------------------------------------------------------
  def make_pngname(file_index)
    return SAVE_DIRECTORY + "/#{file_index + 1}.cdat"
  end
  #--------------------------------------------------------------------------
  # ● セーブファイルの削除
  #     file_index : セーブファイルのインデックス (0〜3)
  #--------------------------------------------------------------------------
  def delete_file(file_index)
    for filename in [make_filename(file_index), make_pngname(file_index)]
      if FileTest.exist?(filename)
        File.delete(filename) rescue print $!
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ セーブの実行
  #--------------------------------------------------------------------------
  SetFileAttributes = Win32API.new('Kernel32', 'SetFileAttributes', 'pi', 'i')
  def do_save
    Dir::mkdir(SAVE_DIRECTORY) unless FileTest.directory?(SAVE_DIRECTORY)
    if $TEST
      SetFileAttributes.call(SAVE_DIRECTORY, 0x80)  # 隠し属性解除
    elsif CAO::ExSave::HIDDEN_DIRECTORY
      SetFileAttributes.call(SAVE_DIRECTORY, 0x02)  # 隠し属性設定
    end
    $game_temp.save_bitmap.save_png(@savefile_windows[@index].pngname)
    $game_system.save_data[:map] = $game_map.name
    $game_system.save_data[:party] =
      $game_party.members.map {|a| a.name }[0, CAO::ExSave::MAX_MEMBERS]
    file = File.open(@savefile_windows[@index].filename, "wb")
    write_save_data(file)
    file.close
    return_scene
  end
end

class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :save_bitmap              # 背景ビットマップ
  attr_accessor :playing_data_index       # プレイ中のセーブファイル
end

class Game_System
  #--------------------------------------------------------------------------
  # ● 拡張したセーブ内容の取得
  #--------------------------------------------------------------------------
  def save_data
    @save_data ||= {}
    return @save_data
  end
end

class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # ○ コンティニュー有効判定
  #--------------------------------------------------------------------------
  def check_continue
    filename = Scene_File::SAVE_DIRECTORY + '/*.rvdata'
    @continue_enabled = (Dir.glob(filename).size > 0)
  end
end

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ○ メニュー画面への切り替え
  #--------------------------------------------------------------------------
  alias _cao_exsave_call_menu call_menu
  def call_menu
    snap_to_save
    _cao_exsave_call_menu
  end
  #--------------------------------------------------------------------------
  # ○ セーブ画面への切り替え
  #--------------------------------------------------------------------------
  alias _cao_exsave_call_save call_save
  def call_save
    snap_to_save
    _cao_exsave_call_save
  end
  #--------------------------------------------------------------------------
  # ● マップ画像を保存
  #--------------------------------------------------------------------------
  def snap_to_save
    if $game_map.loop_horizontal?
      cut_x = 152
    else
      cut_x = ($game_player.real_x - $game_map.display_x) / 8 - 104
      cut_x = 0 if cut_x < 0
    end
    if $game_map.loop_vertical?
      cut_y = 112
    else
      cut_y = ($game_player.real_y - $game_map.display_y) / 8 - 80
      cut_y = 0 if cut_y < 0
    end
    $game_temp.save_bitmap = Graphics.snap_to_bitmap
    bmp_blur = $game_temp.save_bitmap.dup
    bmp_blur.blur
    bitmap = Bitmap.new(120, 96)
    src_rect = Rect.new(cut_x, cut_y, 240, 192)
    bitmap.stretch_blt(bitmap.rect, bmp_blur, src_rect)
    bitmap.stretch_blt(bitmap.rect, $game_temp.save_bitmap, src_rect, 48)
    $game_temp.save_bitmap = bitmap
    bmp_blur.dispose
  end
end

# KAMESOFT『カーソルアニメーション』対策
if $imported && $imported["CursorAnimation"]
class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_exsave_update update
  def update
    _cao_exsave_update
    @savefile_windows[@index].active = !@command_window.active
  end
end
# KGC_CursorAnimation   ◇ Last update : 2009/02/15 ◇
class Cursor_Animation
  #--------------------------------------------------------------------------
  # ○ ウィンドウの可視・アクティブ状態判定
  #--------------------------------------------------------------------------
  def window_active?(window)
    return false if window == nil
    return false if window.disposed?
    return false unless window.visible

    if window.is_a?(Window_Selectable)
      return true if window.active
    elsif window.is_a?(Window_SaveFile)
      return true if window.active && window.selected
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ○ アクティブウィンドウを探す
  #--------------------------------------------------------------------------
  def search_active_window
    return @windows.find { |w|
      if !w.visible
        false
      elsif w.is_a?(Window_Selectable)
        w.active && w.index >= 0
      elsif w.is_a?(Window_SaveFile)
        w.active && w.selected
      else
        false
      end
    }
  end
end
end # if $imported && $imported["CursorAnimation"]
