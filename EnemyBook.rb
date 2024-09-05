#=============================================================================
#  [RGSS2] モンスター図鑑 - v1.1.2
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

  - モンスター図鑑の機能を追加します。
  - 戦闘後にモンスターを自動で登録します。

 -- 使用方法 ----------------------------------------------------------------

 ★ 図鑑にモンスターを登録する。
   ⇒ イベントコマンド「ラベル」に >図鑑登録:[モンスター番号] と記述
   § $cao_enemy[モンスター番号].meet = true

 ★ 図鑑のモンスターを削除する。
   ⇒ イベントコマンド「ラベル」に >図鑑削除:[モンスター番号] と記述
   § $cao_enemy[モンスター番号].meet = false

 ★ 図鑑に全てのモンスターを登録する。
   ⇒ イベントコマンド「ラベル」に <図鑑全登録> と記述

 ★ 図鑑の全てのモンスターを削除する。
   ⇒ イベントコマンド「ラベル」に <図鑑全削除> と記述

 ★ 図鑑を呼び出す。
   ⇒ イベントコマンド「ラベル」に <図鑑表示> と記述
   § $game_temp.next_scene = "ebook"   # 予約
   § start_ebook                       # メニュー専用

 ★ 指定モンスターの自動登録を拒否する。
   ⇒ エネミーのメモ欄に <自動登録禁止> と記述する。

 ★ 指定モンスターを初期登録する。
   ⇒ エネミーのメモ欄に <初期登録> と記述する。

 -- コメントファイル --------------------------------------------------------

  ★ ファイルの導入場所
   Dataフォルダに「EnemyComment.txt」を入れる。
   ※ EnemyComment.rvdata に自動で置き換えられます。＜バックアップ推奨＞

  ★ ファイルの文字コード
   Unicode（UTF-8）

  ★ コメントファイルの変更
   Data/EnemyComment.rvdata を削除し、
   もう一度 EnemyComment.txt を入れてください。

  ★ コメントの書き方
   コメントの行は、５の倍数＋１行からの３行となります。
   他の行は、動作に何の影響も与えません。ですので、自由にお使いください。
   ※ 1行目は無視し、2,3,4行目がコメント行になります。他は前述通りです。

=end


module CAO
class Ebook
#==============================================================================
# ◆ ユーザー設定
#------------------------------------------------------------------------------
# 　デフォルト値でも、正しく動作します。
#==============================================================================

  #--------------------------------------------------------------------------
  # ◇ メニュー項目の追加設定
  #     値（true） ：メニューに追加する
  #     値（false）：メニューに追加しない。（自作メニューを使用している。）
  #--------------------------------------------------------------------------
    ENEMYBOOK_IN_MENU = false
  #--------------------------------------------------------------------------
  # ◇ 初期登録モンスター
  #     値（true） ：最初から全てのモンスターを閲覧可能にする。
  #     値（false）：最初は閲覧できない。
  #--------------------------------------------------------------------------
    DEFAULT_MEET_ALL = false
  #--------------------------------------------------------------------------
  # ◇ 登録のタイミング
  #     値（true） ：勝利したときのみ閲覧可能にする。
  #     値（false）：バトルが終了したら閲覧可能にする。
  #--------------------------------------------------------------------------
    MEET_JUDG_WIN = true
  #--------------------------------------------------------------------------
  # ◇ 完成度の表示
  #     値（ 0 ）：表示しない。
  #     値（ 1 )   ：n/m の形で表示する。
  #     値（ 2 ）  ：n% の形で表示する。
  #--------------------------------------------------------------------------
    W_INFO_MESSAGE = 2
  #--------------------------------------------------------------------------
  # ◇ 線の種類
  #     値（"solid"） ：実線を表示する。
  #     値（"broken"）：破線を表示する。
  #     ※ 上記以外の文字だとそのまま表示します。
  #--------------------------------------------------------------------------
    LINE_KIND = "broken"
  #--------------------------------------------------------------------------
  # ◇ ドロップアイテムの線の有無
  #     値（true） ：ドロップアイテムがない場合、線を引く。
  #     値（false）：ドロップアイテムがない場合、空白にする。
  #--------------------------------------------------------------------------
    DROP_ITEM_LINE = true
  #--------------------------------------------------------------------------
  # ◇ 用語の設定
  #--------------------------------------------------------------------------
    # 閲覧できないモンスターの画面に表示する文字
    NO_MEET_MESSAGE = "Ｎｏ Ｄａｔａ"

    # モンスター図鑑の名前（メニュー項目の名前）
    EBOOK_NAME = "モンスター図鑑"

    # 完成度の文字
    EBOOK_INFO_MESSAGE = "完成度"


end   # module CAO
end   # class Ebook


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Cao_Enemy
  attr_accessor :meet   # 図鑑に表示（true）
  def initialize
    @meet = false
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ◎ ラベルの処理
  #--------------------------------------------------------------------------
  alias _cao_command_118_ebook command_118
  def command_118
    case @params[0]
    when /^<図鑑表示>/
      $game_temp.next_scene = "ebook"
    when /^>図鑑(登録|削除):\[.+?\]/
      para = @params[0].scan(/\d+/).collect {|s| s.to_i }
      bool = @params[0].include?(">図鑑登録") ? true : false
      for i in para
        $cao_enemy[i].meet = bool
      end
    when /^<図鑑全(登録|削除)>/
      bool = @params[0].include?("<図鑑全登録>") ? true : false
      for n in 1...$cao_enemy.size
        $cao_enemy[n].meet = bool
      end
    else
      return _cao_command_118_ebook
    end
    return true
  end
end

class Window_Selectable < Window_Base
  #--------------------------------------------------------------------------
  # ○ カーソルを下に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    if (@index < @item_max - @column_max) or (wrap and @column_max == 1)
      @index = (@index + @column_max) % @item_max
      $eno = @index
    end
  end
  #--------------------------------------------------------------------------
  # ○ カーソルを上に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
    if (@index >= @column_max) or (wrap and @column_max == 1)
      @index = (@index - @column_max + @item_max) % @item_max
      $eno = @index
    end
  end
  #--------------------------------------------------------------------------
  # ○ カーソルを右に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    if (@column_max >= 2) and
       (@index < @item_max - 1 or (wrap and page_row_max == 1))
      @index = (@index + 1) % @item_max
      $eno = @index
    end
  end
  #--------------------------------------------------------------------------
  # ○ カーソルを左に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    if (@column_max >= 2) and
       (@index > 0 or (wrap and page_row_max == 1))
      @index = (@index - 1 + @item_max) % @item_max
      $eno = @index
    end
  end
end

class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # ● 各種ゲームオブジェクトの作成
  #--------------------------------------------------------------------------
  alias _cao_create_game_objects_enemy create_game_objects
  def create_game_objects
    _cao_create_game_objects_enemy
    $cao_enemy = Array.new($data_enemies.size) {Cao_Enemy.new}
  end
end

class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # ● セーブデータの書き込み
  #     file : 書き込み用ファイルオブジェクト (オープン済み)
  #--------------------------------------------------------------------------
  alias _cao_write_save_data_enemy write_save_data
  def write_save_data(file)
    _cao_write_save_data_enemy(file)
    Marshal.dump($cao_enemy, file)
  end
  #--------------------------------------------------------------------------
  # ● セーブデータの読み込み
  #     file : 読み込み用ファイルオブジェクト (オープン済み)
  #--------------------------------------------------------------------------
  alias _cao_read_save_data_enemy read_save_data
  def read_save_data(file)
    _cao_read_save_data_enemy(file)
    $cao_enemy = Marshal.load(file)
  end
end

class Window_EnemyStatus < Window_Base
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(180, 0, 364, 310)
    @enemy_no = 1
    $eno = 0
  end
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    enemy_no = $eno + 1 if $eno != nil
    @enemy = $data_enemies[enemy_no]
    if @enemy != nil && $cao_enemy[enemy_no].meet
      x, y, width, height = 64, 26, 48, WLH + 2
      draw_battler(@enemy.battler_name, @enemy.battler_hue)
      self.contents.font.color = normal_color
      self.contents.draw_text(x * 0, y * 0, width * 2.2, height, @enemy.name)
      draw_status(x * 2, y * 0, Vocab::hp, @enemy.maxhp)
      draw_status(x * 3.6, y * 0, Vocab::mp, @enemy.maxmp)
      draw_status(x * 2, y * 1+3, Vocab::atk, @enemy.atk)
      draw_status(x * 3.6, y * 1+3, Vocab::def, @enemy.def)
      draw_status(x * 2, y * 2+3, Vocab::spi, @enemy.spi)
      draw_status(x * 3.6, y * 2+3, Vocab::agi, @enemy.agi)
      draw_status(x * 2, y * 3+3, "命中率", @enemy.hit)
      draw_status(x * 3.6, y * 3+3, "回避率", @enemy.eva)
      draw_status(x * 2, y * 4+4, "経験値", @enemy.exp)
      draw_status(x * 3.6, y * 4+4, "お金", @enemy.gold)
      draw_dropitem(x, y, width, height)
    else
      self.contents.font.color = normal_color
      self.contents.font.size = 32
      self.contents.draw_text(-8, 0, 364, 288, CAO::Ebook::NO_MEET_MESSAGE, 1)
      self.contents.font.size = 20
    end
  end
  #--------------------------------------------------------------------------
  # ◎ モンスターの描画
  #     battler_name : 顔グラフィック ファイル名
  #     battler_hue  : 顔グラフィック インデックス
  #     x            : 描画先 X 座標
  #     y            : 描画先 Y 座標
  #     size         : 表示サイズ
  #--------------------------------------------------------------------------
  def draw_battler(battler_name, battler_hue)
    bitmap = Cache.battler(battler_name, battler_hue)
    x, y, w, h = 2, 32, bitmap.width, bitmap.height
    x = 120/2 - w/2 if w < 120
    y = 192/2 - h/2 + 32 if h < 192
    self.contents.blt(x, y, bitmap, bitmap.rect, 180)
    bitmap.dispose
  end
  #--------------------------------------------------------------------------
  # ◎ ステータスの描画
  #     x            : 描画先 X 座標
  #     y            : 描画先 Y 座標
  #     text         : ステータス名
  #     data         : ステータス値
  #--------------------------------------------------------------------------
  def draw_status(x, y, text, data)
    width, height = 45, WLH + 2
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, width, height, text)
    self.contents.font.color = normal_color
    self.contents.draw_text(x + 48, y, width, height, data, 2)
  end
  #--------------------------------------------------------------------------
  # ◎ ドロップアイテムの描画
  #--------------------------------------------------------------------------
  def draw_dropitem(x, y, width, height)
    item1, item2 = @enemy.drop_item1, @enemy.drop_item2
    case item1.kind
      when 0; item1_name = nil
      when 1; item1_name = $data_items[item1.item_id]
      when 2; item1_name = $data_weapons[item1.weapon_id]
      when 3; item1_name = $data_armors[item1.armor_id]
    end
    case item2.kind
      when 0; item2_name = nil
      when 1; item2_name = $data_items[item2.item_id]
      when 2; item2_name = $data_weapons[item2.weapon_id]
      when 3; item2_name = $data_armors[item2.armor_id]
    end
    self.contents.font.color = system_color
    self.contents.draw_text(x*2, y*5+12, width*3, height, "ドロップアイテム")
    self.contents.font.color = normal_color
    draw_drop_item(item1_name, x * 2+18, y * 6+12)
    draw_drop_item(item2_name, x * 2+18, y * 7+12)
  end
  #--------------------------------------------------------------------------
  # ◎ アイテム名の描画
  #     item    : アイテム (スキル、武器、防具でも可)
  #     x       : 描画先 X 座標
  #     y       : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_drop_item(item, x, y)
    if item != nil
      draw_icon(item.icon_index, x, y)
      self.contents.draw_text(x + 24, y + 2, 148, WLH, item.name)
    elsif CAO::Ebook::DROP_ITEM_LINE
      case CAO::Ebook::LINE_KIND
      when "solid"
        line = "× ???????"
      when "broken"
        line = "× --------------"
      else
        line = CAO::Ebook::LINE_KIND
      end
      self.contents.draw_text(x + 2, y + 2, 170, WLH, line)
    end
  end
end

class Window_EnemyComment < Window_Base
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(180, 310, 364, 106)
    road_file
  end
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    enemy_no = $eno + 1 if $eno != nil
    if $data_enemies[enemy_no] != nil && $cao_enemy[enemy_no].meet
      l = 5 * ( enemy_no - 1 )
      self.contents.font.color = normal_color
      for i in 1...4
        self.contents.draw_text(0, WLH * (i - 1)+2, 336, WLH, @comment[l+i])
      end
    else
      self.contents.font.color = normal_color
      self.contents.font.size = 32
      self.contents.draw_text(-8, -24, 364, 128, CAO::Ebook::NO_MEET_MESSAGE,1)
      self.contents.font.size = 20
    end
  end
  #--------------------------------------------------------------------------
  # ◎ ファイルの読み込み
  #--------------------------------------------------------------------------
  def road_file
    begin
      @comment = load_data("Data/EnemyComment.rvdata")
    rescue
      begin
        unless File.exist?("Data/EnemyComment.rvdata")
          comfile = File.open("Data/EnemyComment.txt")
        end
      rescue
        save_data([], "Data/EnemyComment.rvdata")
        retry
      else
        if File.exist?("Data/EnemyComment.txt")
          @comment = comfile.readlines
          save_data(@comment, "Data/EnemyComment.rvdata")
          comfile.close
        end
      end
      if File.exist?("Data/EnemyComment.txt")
        File.delete("Data/EnemyComment.txt") rescue nil
      end
      retry
    else
      for i in 0...@comment.size
        @comment[i].strip!
      end
    end
  end
end

class Window_EnemyInfo < Window_Base
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, 180, 72)
    refresh
  end
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    emax = $data_enemies.size - 1
    c = 0
    for i in 1..emax
      c += 1 if $cao_enemy[i].meet
    end
    case CAO::Ebook::W_INFO_MESSAGE
    when 1
      text = "#{c}/#{emax}"
    when 2
      per = c * 100 / emax
      text = "#{per} ％"
    end
    self.contents.font.color = system_color
    self.contents.draw_text(0, 8, 74, WLH, CAO::Ebook::EBOOK_INFO_MESSAGE)
    color = c == emax ? Color.new(240, 60, 120) : normal_color
    self.contents.font.color = color
    self.contents.draw_text(74, 8, 74, WLH, text, 2)
  end
end

class Window_EnemySelect < Window_Selectable
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #     width  : ウィンドウの幅
  #     height : ウィンドウの高さ
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super(x, y, width, height)
    @column_max = 1
    self.index = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @data = []
    @item_max = $data_enemies.size - 1
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 項目の描画
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    enemy_no = index + 1
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    if $cao_enemy[enemy_no].meet && enemy_no > 0
      self.contents.draw_text(rect, $data_enemies[enemy_no].name)
    elsif !$cao_enemy[enemy_no].meet && enemy_no > 0
      case CAO::Ebook::LINE_KIND
      when "solid"
        line = " ???????"
      when "broken"
        line = " ----------------"
      else
        line = CAO::Ebook::LINE_KIND
      end
      self.contents.draw_text(rect, line)
    end
  end
end

class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  alias _start_ebook start
  def start
    _start_ebook
    default_meet    # 登録モンスターの初期設定
  end
  #--------------------------------------------------------------------------
  # ◎ 登録モンスターの初期設定
  #--------------------------------------------------------------------------
  def default_meet
    for i in 1...$cao_enemy.size
      if CAO::Ebook::DEFAULT_MEET_ALL
        $cao_enemy[i].meet = true
      elsif $data_enemies[i].note.include?("<初期登録>")
        $cao_enemy[i].meet = true
      end
    end
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_ebook_update_scene_change update_scene_change
  def update_scene_change
    return if $game_player.moving?    # プレイヤーの移動中？
    if $game_temp.next_scene == "ebook"
      $game_temp.next_scene = nil
      $scene = Scene_EnemyBook.new
    else
      _cao_ebook_update_scene_change
    end
  end
end

class Scene_Menu < Scene_Base
  #--------------------------------------------------------------------------
  # ◎ モンスター図鑑を起動
  #--------------------------------------------------------------------------
  def start_ebook
    $scene = Scene_EnemyBook.new(@command_window.index)
  end
end
if CAO::Ebook::ENEMYBOOK_IN_MENU
class Scene_Menu < Scene_Base
  #--------------------------------------------------------------------------
  # ○ コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    s1 = Vocab::item
    s2 = Vocab::skill
    s3 = Vocab::equip
    s4 = Vocab::status
    s5 = Vocab::save
    s6 = Vocab::game_end
    s7 = CAO::Ebook::EBOOK_NAME
    @command_window = Window_Command.new(160, [s1, s2, s3, s4, s7, s5, s6])
    @command_window.index = @menu_index
    if $game_party.members.size == 0          # パーティ人数が 0 人の場合
      @command_window.draw_item(0, false)     # アイテムを無効化
      @command_window.draw_item(1, false)     # スキルを無効化
      @command_window.draw_item(2, false)     # 装備を無効化
      @command_window.draw_item(3, false)     # ステータスを無効化
    end
    if $game_system.save_disabled             # セーブ禁止の場合
      @command_window.draw_item(5, false)     # セーブを無効化
    end
  end
  #--------------------------------------------------------------------------
  # ○ コマンド選択の更新
  #--------------------------------------------------------------------------
  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      if $game_party.members.size == 0 and @command_window.index < 4
        Sound.play_buzzer
        return
      elsif $game_system.save_disabled and @command_window.index == 4
        Sound.play_buzzer
        return
      end
      Sound.play_decision
      case @command_window.index
      when 0      # アイテム
        $scene = Scene_Item.new
      when 1,2,3  # スキル、装備、ステータス
        start_actor_selection
      when 4      # モンスター図鑑
        start_ebook
      when 5      # セーブ
        $scene = Scene_File.new(true, false, false)
      when 6      # ゲーム終了
        $scene = Scene_End.new
      end
    end
  end
end
end   # ENEMYBOOK_IN_MENU の条件分岐のend

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 戦闘終了
  #     result : 結果 (0:勝利 1:逃走 2:敗北)
  #--------------------------------------------------------------------------
  def battle_end(result)
    enemy_meet(result)
    if result == 2 and not $game_troop.can_lose
      call_gameover
    else
      $game_party.clear_actions
      $game_party.remove_states_battle
      $game_troop.clear
      if $game_temp.battle_proc != nil
        $game_temp.battle_proc.call(result)
        $game_temp.battle_proc = nil
      end
      unless $BTEST
        $game_temp.map_bgm.play
        $game_temp.map_bgs.play
      end
      $scene = Scene_Map.new
      @message_window.clear
      Graphics.fadeout(30)
    end
    $game_temp.in_battle = false
  end
  #--------------------------------------------------------------------------
  # ◎ 図鑑登録
  #     result : 結果 (0:勝利 1:逃走 2:敗北)
  #--------------------------------------------------------------------------
  def enemy_meet(result)
    for i in 0...8
      break if $game_troop.members[i] == nil
      enemy_no = $game_troop.members[i].enemy_id
      next if $data_enemies[enemy_no].note.include?("<自動登録禁止>")
      unless CAO::Ebook::MEET_JUDG_WIN && result != 0
        $cao_enemy[enemy_no].meet = true
      end
    end
  end
end

class Scene_EnemyBook < Scene_Base
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #     from : 図鑑の呼び出し元（-1：マップ, 0~：メニュー）
  #--------------------------------------------------------------------------
  def initialize(from = -1)
    @from = from
    @ca = 1
  end
  #--------------------------------------------------------------------------
  # ◎ 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    @e_status_window = Window_EnemyStatus.new
    if CAO::Ebook::W_INFO_MESSAGE == 0
      @e_select_window = Window_EnemySelect.new(0, 0, 180, 416)
    else
      @e_info_window = Window_EnemyInfo.new
      @e_select_window = Window_EnemySelect.new(0, 72, 180, 344)
    end
    @e_comment_window = Window_EnemyComment.new
  end
  #--------------------------------------------------------------------------
  # ◎ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    @e_status_window.dispose
    @e_info_window.dispose if CAO::Ebook::W_INFO_MESSAGE != 0
    @e_select_window.dispose
    @e_comment_window.dispose
    dispose_menu_background
  end
  #--------------------------------------------------------------------------
  # ◎ 元の画面へ戻る
  #--------------------------------------------------------------------------
  def return_scene
    @from < 0 ? $scene = Scene_Map.new : $scene = Scene_Menu.new(@from)
  end
  #--------------------------------------------------------------------------
  # ◎ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    @e_status_window.update
    @e_select_window.update
    @e_comment_window.update
    update_graphics
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene
    end
  end
  #--------------------------------------------------------------------------
  # ◎ ステータスとコメントの更新
  #--------------------------------------------------------------------------
  def update_graphics
    if $eno != @ca
      @ca = $eno
      @e_status_window.refresh
      @e_comment_window.refresh
    end
  end
end
