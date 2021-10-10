#=============================================================================
#  [RGSS2] モンスター図鑑 #2 - v1.1.1
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

  モンスター図鑑の機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの使用には、基本的なＲＧＳＳ２の知識が必要となります。
  ※ テキストでコメントを設定する場合は、暗号化前に Data フォルダ内に
     MBComments.rvdata ファイルがあることを確認してください。

 -- 画像規格 ----------------------------------------------------------------

  ★ 有効度の詳細画像
   属性・ステートアイコンの上に表示します。有効度を見分けるための画像です。
   144 x 48 の画像（WeakIcon）を "Graphics/System" にご用意ください。

  ★ 図鑑背景画像
   図鑑全体の画像です。
   544 x 416 の画像（BackMBook）を "Graphics/System" にご用意ください。
   ※ ステータス背景を使用する場合は、ステータス部分を透過してください。

  ★ ステータス背景画像
   ステータス部分の背景です。
   左からコメント、ステータス、属性・ステート画面となっています。
   896 x 272 の画像（BackMBookS）を "Graphics/System" にご用意ください。

  ※ 詳細はサイトの説明をご覧ください。
     また、画像を使用しない設定の場合は、必要ありません。
     ユーザー設定で個別に設定できます。

 -- 使用方法 ----------------------------------------------------------------

  ★ 図鑑の起動
   $game_temp.next_scene = "mbook"

  ★ メニューからの起動
   start_mbook

  ★ 閲覧可能範囲の変更
   $game_system.mbook[n].entry = value
     n = エネミーのＩＤ
     value = 0:閲覧不可, 1:遭遇, 2:勝利, 3:解析

  ★ 閲覧の可否の変更
   $game_system.mbook[n].hidden = value
     n = エネミーのＩＤ
     value = true:閲覧不可, false:閲覧可能

  ★ 初期登録
   エネミーのメモ欄に <MB:初期登録○> と記述
     ○ = 初期登録時の閲覧可能範囲。半角数字で記述

  ★ 初期閲覧不可
   エネミーのメモ欄に <MB:閲覧禁止> と記述

  ★ 完全非表示
   エネミーのメモ欄に <MB:図鑑除外> と記述

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================

module CAO
module MB
  #--------------------------------------------------------------------------
  # ◇ 閲覧可能にする情報（閲覧可能範囲、閲覧レベル）
  #     （:name, :graphics, :params1, :drop, :params2, :weak, :come）
  #--------------------------------------------------------------------------
  ACCESS_PERMIT = [ [], # <= 消さないように注意！
    # 遭遇  Lv 1
    [:name, :graphics],
    # 勝利  Lv 2
    [:name, :graphics, :params1, :drop],
    # 解析  Lv 3
    [:name, :graphics, :params1, :drop, :params2, :weak, :come]
  ]
  #--------------------------------------------------------------------------
  # ◇ 図鑑完成率の算出方法（閲覧レベルで指定）
  #--------------------------------------------------------------------------
  COMPLETE_NUMBER = nil
  #--------------------------------------------------------------------------
  # ◇ 図鑑完成率の色変え（１００％時）
  #--------------------------------------------------------------------------
  COMPLETE_COLOR = true
  #--------------------------------------------------------------------------
  # ◇ 自動登録する
  #--------------------------------------------------------------------------
  AUTO_ENTRY = true
    #--------------------------------------------------------------------------
    # ◇ 敗北しても登録する
    #     true    : 戦闘で負けても、倒した敵の加算と図鑑登録を行います。
    #     false   : 戦闘に負けた場合は、何も行いません。
    #--------------------------------------------------------------------------
    AUTO_ENTRY_LOSE = false
    #--------------------------------------------------------------------------
    # ◇ 倒した敵のみ自動登録する
    #     true    : 敵を倒すと閲覧レベル１
    #     false   : 遭遇でレベル１、倒すとレベル２
    #--------------------------------------------------------------------------
    AUTO_ENTRY_DEFEATED = false
  #--------------------------------------------------------------------------
  # ◇ 表示するステート
  #--------------------------------------------------------------------------
  ACTIVE_STATE = [2, 3, 4, 5, 6, 7, 8]
  #--------------------------------------------------------------------------
  # ◇ 表示する属性
  #--------------------------------------------------------------------------
  ACTIVE_ELEMENT = [9, 10, 11, 12, 13, 14, 15, 16]
  #--------------------------------------------------------------------------
  # ◇ 属性を１文字で表示する
  #     true      : 属性の最初の１文字のみを表示する。
  #     false     : 指定されたアイコンで表示する。
  #--------------------------------------------------------------------------
  ONE_NAME_ELEMENT = false
    #--------------------------------------------------------------------------
    # ◇ 属性のアイコン
    #--------------------------------------------------------------------------
    ICON_ELEMENT = [104, 105, 106, 107, 108, 109, 110, 111]
  #--------------------------------------------------------------------------
  # ◇ 耐性表示の色分けをする
  #     true      : 有効度の画像を使用します。
  #     false     : アイコンのみを表示します。
  #--------------------------------------------------------------------------
  WEAK_PONIT_COLOR = false
  #--------------------------------------------------------------------------
  # ◇ ステータスのスライド速度
  #     0 〜 6    : 数値が小さいほど速くなり、0 でアニメーションなし
  #--------------------------------------------------------------------------
  SLIDE_SPEED = 3
  #--------------------------------------------------------------------------
  # ◇ ウィンドウを消す
  #--------------------------------------------------------------------------
  NO_WINDOW_GRAPHICS = false
  #--------------------------------------------------------------------------
  # ◇ ステータス背景画像を使用する
  #--------------------------------------------------------------------------
  DISPLAY_STATUS_GRAPHICS = false
  #--------------------------------------------------------------------------
  # ◇ システム文字を非表示にする
  #--------------------------------------------------------------------------
  NO_SYSTEM_FONT = false
  #--------------------------------------------------------------------------
  # ◇ モンスター図鑑のタイトル
  #--------------------------------------------------------------------------
  TEXT_MB_TITLE = "モンスター図鑑"
  #--------------------------------------------------------------------------
  # ◇ パラメータの項目
  #     HP, MP, ATK, DEF, SPI, AGI, HIT, EVA, EXP, GOLD, DROPITEM
  #--------------------------------------------------------------------------
  TEXT_STATUS = [ "Ｈ　Ｐ", "Ｍ　Ｐ", "攻撃力", "防御力", "精神力", "俊敏性",
                  "命中力", "回避率", "経験値", "お　金", "ドロップアイテム" ]
  #--------------------------------------------------------------------------
  # ◇ 耐性の項目
  #     有効属性、有効ステート、耐性属性、耐性ステート
  #--------------------------------------------------------------------------
  TEXT_WEAK_POINT = ["有効属性", "有効ステート", "耐性属性", "耐性ステート"]
  #--------------------------------------------------------------------------
  # ◇ 閲覧不可時のパラメータ
  #--------------------------------------------------------------------------
  TEXT_HIDDEN_DATA = {
    :cmd   => "????????????",         # 項目名
    :name  => "????????",             # モンスターの名前
    :para1 => "???",                  # 攻撃力など
    :para2 => "??????",               # 経験値、ゴールド
    :state => "？ ？ ？ ？ ？ ？ ？", # ステート
    :drop1 => "× --------------",    # ドロップアイテム 未設定
    :drop2 => "？ --------------"     # ドロップアイテム 閲覧不可
  }
  #--------------------------------------------------------------------------
  # ◇ ヘルプウィンドウの項目
  #--------------------------------------------------------------------------
  TEXT_HELP = [
    "倒した数", "体",   # 撃退数
    "遭遇率", "％",     # 遭遇率
    "完成率", "％"      # 完成率
  ]
  #--------------------------------------------------------------------------
  # ◇ その他の文章設定
  #--------------------------------------------------------------------------
  # Scene_Battle#display_action_effects   # 解析のメッセージ
end
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


CAO::MB::COMMENT = {}                     # コメントハッシュ
module CAO
class MonsterBook
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :entry                    # 閲覧レベル（０で未登録）
  attr_accessor :hidden                   # 閲覧可否（不可/可能）
  attr_accessor :unread                   # 既読状態（未読/既読）
  attr_accessor :defeat                   # 撃退数
  attr_accessor :encounter                # 遭遇の有無（遭遇済み/未遭遇）
  attr_reader   :id                       # データベースでのＩＤ
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     id : データベースでのエネミーのＩＤ
  #--------------------------------------------------------------------------
  def initialize(id)
    @id = id
    @entry = 0
    @hidden = false
    @unread = true
    @defeat = 0
    @encounter = false
  end
  #--------------------------------------------------------------------------
  # ● データベースの情報を取得
  #--------------------------------------------------------------------------
  def data
    return $data_enemies[@id]
  end
  #--------------------------------------------------------------------------
  # ● エネミーの名前を取得
  #--------------------------------------------------------------------------
  def name
    return $data_enemies[@id].name
  end
  #--------------------------------------------------------------------------
  # ● コメントの取得
  #--------------------------------------------------------------------------
  def comment
    return $data_mbcomments[@id] || $data_mbcomments[0] || [""]
  end
end
end

class Game_System
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :mbook                    # モンスター図鑑の配列
end

class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # ○ コマンド : ニューゲーム
  #--------------------------------------------------------------------------
  alias _cao_command_new_game_mbook command_new_game
  def command_new_game
    _cao_command_new_game_mbook
    CAO::MB::Commands.reset_mbook
  end
  #--------------------------------------------------------------------------
  # ○ データベースのロード
  #--------------------------------------------------------------------------
  alias _cao_mbook_load_database load_database
  def load_database
    _cao_mbook_load_database
    CAO::MB::Commands.load_comment_data
  end
end

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_update_scene_change_mbook update_scene_change
  def update_scene_change
    return if $game_player.moving?
    if $game_temp.next_scene == "mbook"
      $game_temp.next_scene = nil
      $scene = Scene_MonsterBook.new
    end
    _cao_update_scene_change_mbook
  end
end

class Scene_Menu < Scene_Base
  #--------------------------------------------------------------------------
  # ● 図鑑を起動する
  #--------------------------------------------------------------------------
  def start_mbook
    $scene = Scene_MonsterBook.new(@command_window.index)
  end
end

module CAO::MB::Commands
  module_function
  #--------------------------------------------------------------------------
  # ● 図鑑に登録できるエネミーの配列
  #--------------------------------------------------------------------------
  def unrestraint_array
    return $game_system.mbook.compact
  end
  #--------------------------------------------------------------------------
  # ● 図鑑に登録できるエネミーの数
  #--------------------------------------------------------------------------
  def unrestraint_number
    return unrestraint_array.size
  end
  #--------------------------------------------------------------------------
  # ● 図鑑に登録できるエネミー
  #--------------------------------------------------------------------------
  def unrestraint_enemy(data_id)
    for enemy in unrestraint_array
      return enemy if enemy.id == data_id
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 除外されたＩＤではないか？
  #--------------------------------------------------------------------------
  def mes_exclusion_enemy?(data_id)
    if $game_system.mbook[data_id].nil?
      print "ID#{id} のエネミーは、除外されています。"
      return true
    else
      return false
    end
  end
  #--------------------------------------------------------------------------
  # ● 図鑑を完全リセット
  #--------------------------------------------------------------------------
  def reset_mbook
    create_comment_data
    $game_system.mbook = []
    for i in 1...$data_enemies.size
      unless /^<MB:図鑑除外>/ =~ $data_enemies[i].note
        $game_system.mbook[i] = CAO::MonsterBook.new($data_enemies[i].id)
      end
    end
    reset_entry
    reset_hidden
    reset_unread
    reset_defeat
  end
  #--------------------------------------------------------------------------
  # ● 登録状況を初期化
  #--------------------------------------------------------------------------
  def reset_entry
    for i in 1...$data_enemies.size
      next if $game_system.mbook[i] == nil
      if /^<MB:初期登録(\d)>/ =~ $data_enemies[i].note
        $game_system.mbook[i].entry = $1.to_i
      else
        $game_system.mbook[i].entry = 0
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 閲覧可否状態を初期化
  #--------------------------------------------------------------------------
  def reset_hidden
    for i in 1...$data_enemies.size
      next if $game_system.mbook[i] == nil
      if /^<MB:閲覧禁止>/ =~ $data_enemies[i].note
        $game_system.mbook[i].hidden = true
      else
        $game_system.mbook[i].hidden = false
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 全て未読状態に変更
  #--------------------------------------------------------------------------
  def reset_unread
    for i in 1...$data_enemies.size
      next if $game_system.mbook[i] == nil
      $game_system.mbook[i].unread = true
    end
  end
  #--------------------------------------------------------------------------
  # ● すべての撃退数を０に
  #--------------------------------------------------------------------------
  def reset_defeat
    for i in 1...$data_enemies.size
      next if $game_system.mbook[i] == nil
      $game_system.mbook[i].defeat = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● コメントデータの作成
  #--------------------------------------------------------------------------
  def create_comment_data
    return if !$TEST || !FileTest.file?("MBComments.txt")
    comments = {}
    File.open("MBComments.txt") do |file|
      strs = file.readlines.collect {|s| NKF.nkf("-w", s) }
      for line in 0...strs.size
        text = strs[line].rstrip
        case text
        when /^@0/
          id = 0
          comments[id] = []
        when /^@(.*)/
          id = nil
          for i in 1...$data_enemies.size
            if $data_enemies[i].name == $1
              id = i
              break
            end
          end
          print "`#{$1}' に対応するエネミーがいません。" unless id
          print "`#{$1}' の設定が重複しています。" if comments[id]
          comments[id] = []
        when "\\"
          id = nil
        else
          next if id == nil || id == ""
          comments[id] << text
        end
      end
    end
    save_data(comments, "Data/MBComments.rvdata")
    load_comment_data
  end
  #--------------------------------------------------------------------------
  # ● コメントデータの読み込み
  #--------------------------------------------------------------------------
  def load_comment_data
    begin
      $data_mbcomments = load_data("Data/MBComments.rvdata")
    rescue Errno::ENOENT
      $data_mbcomments = CAO::MB::COMMENT
    end
  end
  #--------------------------------------------------------------------------
  # ● 全モンスターの登録状態を変更
  #--------------------------------------------------------------------------
  def complete_entry(entry_type)
    unrestraint_array.each {|e| e.entry = entry_type }
  end
  #--------------------------------------------------------------------------
  # ● 全モンスターの登録を解除
  #--------------------------------------------------------------------------
  def clear_entry
    unrestraint_array.each {|e| e.entry = 0 }
  end
  #--------------------------------------------------------------------------
  # ● 閲覧レベルの変更（図鑑登録・削除）
  #--------------------------------------------------------------------------
  def change_entry(data_id, val = nil)
    return if mes_exclusion_enemy?(data_id)
    $game_system.mbook[data_id].entry = val
  end
  #--------------------------------------------------------------------------
  # ● 閲覧の可否を変更
  #--------------------------------------------------------------------------
  def change_hidden(data_id, val = nil)
    return if mes_exclusion_enemy?(id)
    if val.nil?
      $game_system.mbook[data_id].hidden ^= true
    else
      $game_system.mbook[data_id].hidden = val
    end
  end
  #--------------------------------------------------------------------------
  # ● 総撃退数の取得
  #--------------------------------------------------------------------------
  def get_defeat_number(*ary_id)
    count = 0
    if ary_id.empty?
      for enemy in unrestraint_array
        count += enemy.defeat
      end
    else
      for id in ary_id
        count += $game_system.mbook[id].defeat
      end
    end
    return count
  end
  #--------------------------------------------------------------------------
  # ● 遭遇した種類数を取得
  #--------------------------------------------------------------------------
  def get_encounter_number
    count = 0
    for enemy in unrestraint_array
      count += 1 if enemy.encounter
    end
    return count
  end
  #--------------------------------------------------------------------------
  # ● 遭遇した種類を百分率で取得
  #--------------------------------------------------------------------------
  def get_encounter_percent
    return get_encounter_number * 100 / unrestraint_number
  end
  #--------------------------------------------------------------------------
  # ● 各閲覧レベルの数を取得（図鑑登録数）
  #--------------------------------------------------------------------------
  def get_entry_number(entry_type = nil)
    count = 0
    if entry_type
      for enemy in unrestraint_array
        count += 1 if enemy.entry >= entry_type
      end
    else
      for enemy in unrestraint_array
        count += enemy.entry
      end
      count /= 3
    end
    return count
  end
  #--------------------------------------------------------------------------
  # ● 各閲覧レベルの数を百分率で取得（図鑑完成率）
  #--------------------------------------------------------------------------
  def get_entry_percent(entry_type = nil)
    return get_entry_number(entry_type) * 100 / unrestraint_number
  end
  #--------------------------------------------------------------------------
  # ● 図鑑が完成しているかを判定
  #--------------------------------------------------------------------------
  def complete?
    return get_entry_number(3) == unrestraint_number
  end
  #--------------------------------------------------------------------------
  # ● 閲覧可能か判定
  #--------------------------------------------------------------------------
  def enemy_enable?(enemy, param)
    return false if enemy.hidden
    return CAO::MB::ACCESS_PERMIT[enemy.entry].include?(param)
  end
end

class Window_MbookCommand < Window_Selectable
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #     width  : ウィンドウの幅
  #     height : ウィンドウの高さ
  #--------------------------------------------------------------------------
  def initialize
    super(8, 72, 200, 272)
    self.opacity = CAO::MB::NO_WINDOW_GRAPHICS ? 0 : 255
    @enemy = CAO::MB::Commands.unrestraint_array
    @item_max = CAO::MB::Commands.unrestraint_number
    refresh
    self.index = 0
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の作成
  #--------------------------------------------------------------------------
  def create_contents
    self.contents.dispose
    h = [height - 32, $game_system.mbook.size * WLH].max
    self.contents = Bitmap.new(width - 32, h)
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
    self.contents.draw_text(rect, sprintf("%03d", index + 1))
    if @enemy[index].hidden || @enemy[index].entry == 0
      self.contents.draw_text(rect, CAO::MB::TEXT_HIDDEN_DATA[:cmd], 2)
    else
      rect.x = 32
      rect.width -= 28
      self.contents.font.color = Color.new(102,204,64) if @enemy[index].unread
      self.contents.draw_text(rect, @enemy[index].name, 2)
    end
  end
end

class Window_MbookStatus < Window_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  SLIDE_SPEED = 288 / [1, 2, 4, 8, 16, 32, 48][CAO::MB::SLIDE_SPEED]
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #     width  : ウィンドウの幅
  #     height : ウィンドウの高さ
  #--------------------------------------------------------------------------
  def initialize
    super(216, 72, 320, 272)
    @enemy = CAO::MB::Commands.unrestraint_array[0]
    self.opacity = CAO::MB::NO_WINDOW_GRAPHICS ? 0 : 255
    self.ox = 288
    @page = 1
    @slide_left = false
    @slide_right = false
    refresh
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の作成
  #--------------------------------------------------------------------------
  def create_contents
    self.contents.dispose
    self.contents = Bitmap.new((width - 32) * 3, height - 32)
    if CAO::MB::DISPLAY_STATUS_GRAPHICS || CAO::MB::NO_SYSTEM_FONT
      @back_sprite = Sprite.new
      @back_sprite.bitmap = Cache.system("BackMBookS")
      @back_sprite.x = 216
      @back_sprite.y = 72
      @back_sprite.z = 0
      @back_sprite.ox = 288
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目を許可状態で表示するかどうか
  #--------------------------------------------------------------------------
  def enable?(param)
    return CAO::MB::Commands.enemy_enable?(@enemy, param)
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @enemy.unread = false if @enemy.entry > 0
    self.contents.clear_rect(288 * @page, 0, 288, 240)
    case @page
    when 0
      draw_comments
    when 1
      x = 288
      self.contents.font.color = normal_color
      t = enable?(:name) ? @enemy.name : CAO::MB::TEXT_HIDDEN_DATA[:name]
      self.contents.draw_text(x + 4, 0, 280, WLH, t)
      draw_enemy_parameter(x, 33)
      unless CAO::MB::NO_SYSTEM_FONT
        self.contents.font.color = system_color
        self.contents.draw_text(x, 168, 160, WLH, CAO::MB::TEXT_STATUS[10])
      end
      draw_drop_item(@enemy.data.drop_item1, x + 24, 192)
      draw_drop_item(@enemy.data.drop_item2, x + 24, 216)
    when 2
      draw_weak_point(576)
    end
  end
  #--------------------------------------------------------------------------
  # ● コメントの描画
  #--------------------------------------------------------------------------
  def draw_comments
    self.contents.font.color = normal_color
    text = enable?(:come) ? @enemy.comment : $data_mbcomments[0] || [""]
    for i in 0...text.size
      draw_message(text[i], WLH * i)
    end
    self.contents.font.size = 20
  end
  #--------------------------------------------------------------------------
  # ● メッセージの描画
  #--------------------------------------------------------------------------
  def draw_message(text, y)
    text = text.clone
    # 制御文字の変換
    text.gsub!(/\\V\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
    text.gsub!(/\\N\[([0-9]+)\]/i) { $game_actors[$1.to_i].name }
    text.gsub!(/\\C\[([0-9]+)\]/i) { "\x01[#{$1}]" }
    text.gsub!(/\\X\[(-?\d+)\]/i)  { "\x02[#{$1}]" }
    text.gsub!(/\\S\[([0-9]+)\]/i) { "\x03[#{$1}]" }
    text.gsub!(/\\\\/)             { "\\" }
    x = 0   # 最初の文字のｘ座標
    loop do
      c = text.slice!(/./m)
      case c
      when nil      # 文字が無い場合は戻る
        break
      when "\x01"   # 描画色の変更
        text.sub!(/\[([0-9]+)\]/, "")
        contents.font.color = text_color($1.to_i)
        next
      when "\x02"   # ｘ座標を変更
        text.sub!(/\[(-?[0-9]+)\]/, "")
        x = $1.to_i
        next
      when "\x03"   # 文字サイズを変更
        text.sub!(/\[([0-9]+)\]/, "")
        self.contents.font.size = [[10, $1.to_i].max, 20].min
        next
      else
        # 表示域からはみ出ていれば処理を中断
        break if 288 < (x + contents.text_size(c).width)
        # 文字の描画
        contents.draw_text(x, y, 40, WLH, c)
        x += contents.text_size(c).width
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● モンスターのステータスの描画
  #--------------------------------------------------------------------------
  def draw_enemy_parameter(x, y)
    params = [  @enemy.data.maxhp, @enemy.data.maxmp,
                @enemy.data.atk, @enemy.data.def, @enemy.data.spi,
                @enemy.data.agi, @enemy.data.hit, @enemy.data.eva  ]
    for i in 0...8
      xx = x + i % 2 * 152
      yy = y + i / 2 * WLH
      unless CAO::MB::NO_SYSTEM_FONT
        self.contents.font.color = system_color
        self.contents.draw_text(xx, yy, 60, WLH, CAO::MB::TEXT_STATUS[i])
      end
      self.contents.font.color = normal_color
      t = enable?(:params1) ? params[i] : CAO::MB::TEXT_HIDDEN_DATA[:para1]
      self.contents.draw_text(xx + 60, yy, 72, WLH, t, 2)
    end
    unless CAO::MB::NO_SYSTEM_FONT
      self.contents.font.color = system_color
      self.contents.draw_text(x, 135, 60, WLH, CAO::MB::TEXT_STATUS[8])
      self.contents.draw_text(x + 152, 135, 60, WLH, CAO::MB::TEXT_STATUS[9])
    end
    self.contents.font.color = normal_color
    if enable?(:params2)
      self.contents.draw_text(x + 60, 135, 72, WLH, @enemy.data.exp, 2)
      self.contents.draw_text(x + 212, 135, 72, WLH, @enemy.data.gold, 2)
    else
      t = CAO::MB::TEXT_HIDDEN_DATA[:para2]
      self.contents.draw_text(x + 60, 135, 72, WLH, t, 2)
      self.contents.draw_text(x + 212, 135, 72, WLH, t, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの描画
  #--------------------------------------------------------------------------
  def draw_drop_item(drop_item, x, y)
    case drop_item.kind
    when 0
      item = nil
    when 1
      item = $data_items[drop_item.item_id]
    when 2
      item = $data_weapons[drop_item.weapon_id]
    when 3
      item = $data_armors[drop_item.armor_id]
    end
    self.contents.font.color = normal_color
    if enable?(:drop)
      if item == nil
        t = CAO::MB::TEXT_HIDDEN_DATA[:drop1]
        self.contents.draw_text(x + 2, y, 230, WLH, t)
      else
        draw_icon(item.icon_index, x, y)
        self.contents.draw_text(x + 26, y, 230, WLH, item.name)
      end
    else
      t = CAO::MB::TEXT_HIDDEN_DATA[:drop2]
      self.contents.draw_text(x, y, 230, WLH, t)
    end
  end
  #--------------------------------------------------------------------------
  # ● 弱点の描画
  #--------------------------------------------------------------------------
  def draw_weak_point(x)
    unless CAO::MB::NO_SYSTEM_FONT
      self.contents.font.color = system_color
      for i in 0...4
        self.contents.draw_text(x+4,60*i,280,WLH,CAO::MB::TEXT_WEAK_POINT[i])
      end
    end
    if enable?(:weak)
      draw_element_icon(x + 28, 24)
      draw_state_icon(x + 28, 84)
    else
      self.contents.font.color = normal_color
      for i in 0...4
        t = CAO::MB::TEXT_HIDDEN_DATA[:state]
        self.contents.draw_text(x+36,60*i+24,240,WLH, t)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 属性アイコンの描画
  #--------------------------------------------------------------------------
  def draw_element_icon(x, y)
    count = 0
    for i in 0...CAO::MB::ACTIVE_ELEMENT.size
      if @enemy.data.element_ranks[CAO::MB::ACTIVE_ELEMENT[i]] < 3
        if CAO::MB::ONE_NAME_ELEMENT
          rank = @enemy.data.element_ranks[CAO::MB::ACTIVE_ELEMENT[i]]
          text = $data_system.elements[CAO::MB::ACTIVE_ELEMENT[i]][/./]
          draw_weak_icon(text, x + 26 * count, y, rank)
        else
          icon_index = CAO::MB::ICON_ELEMENT[i]
          rank = @enemy.data.element_ranks[CAO::MB::ACTIVE_ELEMENT[i]]
          draw_weak_icon(icon_index, x + 26 * count, y, rank)
        end
        count += 1
      end
    end
    count = 0
    for i in 0...CAO::MB::ACTIVE_ELEMENT.size
      if @enemy.data.element_ranks[CAO::MB::ACTIVE_ELEMENT[i]] > 3
        if CAO::MB::ONE_NAME_ELEMENT
          rank = @enemy.data.element_ranks[CAO::MB::ACTIVE_ELEMENT[i]]
          text = $data_system.elements[CAO::MB::ACTIVE_ELEMENT[i]][/./]
          draw_weak_icon(text, x + 26 * count, y + 120, rank)
        else
          icon_index = CAO::MB::ICON_ELEMENT[i]
          rank = @enemy.data.element_ranks[CAO::MB::ACTIVE_ELEMENT[i]]
          draw_weak_icon(icon_index, x + 26 * count, y + 120, rank)
        end
        count += 1
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● ステートアイコンの描画
  #--------------------------------------------------------------------------
  def draw_state_icon(x, y)
    weak_ranks = []
    strong_ranks = []
    for en in CAO::MB::ACTIVE_STATE
      if @enemy.data.state_ranks[en] < 3
        weak_ranks << en
      elsif @enemy.data.state_ranks[en] > 3
        strong_ranks << en
      end
    end
    self.contents.font.color = normal_color
    for i in 0...weak_ranks.size
      icon_index = $data_states[weak_ranks[i]].icon_index
      rank = @enemy.data.state_ranks[weak_ranks[i]] + 6
      draw_weak_icon(icon_index, x + 26 * i, y, rank)
    end
    for i in 0...strong_ranks.size
      icon_index = $data_states[strong_ranks[i]].icon_index
      rank = @enemy.data.state_ranks[strong_ranks[i]] + 6
      draw_weak_icon(icon_index, x + 26 * i, y + 120, rank)
    end
  end
  #--------------------------------------------------------------------------
  # ● 弱点アイコンの描画
  #--------------------------------------------------------------------------
  def draw_weak_icon(icon_index, x, y, rank = 0)
    if icon_index.class == String
      case rank
      when 1
        self.contents.font.color = Color.new(240, 32, 8)
      when 5
        self.contents.font.color = Color.new(48, 128, 248)
      when 6
        self.contents.font.color = Color.new(200, 64, 200)
      else
        self.contents.font.color = normal_color
      end
      self.contents.draw_text(x, y, 24, WLH, icon_index, 1)
    else
      bitmap = Cache.system("Iconset")
      rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
      self.contents.blt(x, y, bitmap, rect)
      if CAO::MB::WEAK_PONIT_COLOR
        rect.set((rank - 1) % 6 * 24, (rank - 1) / 6 * 24, 24, 24)
        self.contents.blt(x, y, Cache.system("WeakIcon"), rect)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def enemy=(enemy_id)
    @enemy = CAO::MB::Commands.unrestraint_array[enemy_id]
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    super
    if CAO::MB::DISPLAY_STATUS_GRAPHICS || CAO::MB::NO_SYSTEM_FONT
      @back_sprite.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if !@slide_left && !@slide_right
      last_index = @page
      if Input.trigger?(Input::RIGHT)
        @page = [@page + 1, 2].min
        @slide_right = @page != last_index
      end
      if Input.trigger?(Input::LEFT)
        @page = [@page - 1, 0].max
        @slide_left = @page != last_index
      end
      if @page != last_index
        Sound.play_cursor
        refresh
      end
    end
    update_page
  end
  #--------------------------------------------------------------------------
  # ● ページ更新
  #--------------------------------------------------------------------------
  def update_page
    if @slide_left
      self.ox -= SLIDE_SPEED
      if CAO::MB::DISPLAY_STATUS_GRAPHICS || CAO::MB::NO_SYSTEM_FONT
        @back_sprite.ox -= SLIDE_SPEED
      end
      @slide_left = !(self.ox == (288 * @page))
    end
    if @slide_right
      self.ox += SLIDE_SPEED
      if CAO::MB::DISPLAY_STATUS_GRAPHICS || CAO::MB::NO_SYSTEM_FONT
        @back_sprite.ox += SLIDE_SPEED
      end
      @slide_right = !(self.ox == (288 * @page))
    end
  end
end

class Window_MBookHelp < Window_Base
  include CAO::MB::Commands
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #     width  : ウィンドウの幅
  #     height : ウィンドウの高さ
  #--------------------------------------------------------------------------
  def initialize
    super(8, 352, 528, 56)
    self.opacity = CAO::MB::NO_WINDOW_GRAPHICS ? 0 : 255
    @enemy = unrestraint_array
    @item_max = unrestraint_number
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    unless CAO::MB::NO_SYSTEM_FONT
      self.contents.font.color = system_color
      self.contents.draw_text(7, 0, 100, WLH, CAO::MB::TEXT_HELP[0])
      self.contents.draw_text(147, 0, 30, WLH, CAO::MB::TEXT_HELP[1], 2)
      self.contents.draw_text(193, 0, 70, WLH, CAO::MB::TEXT_HELP[2])
      self.contents.draw_text(303, 0, 30, WLH, CAO::MB::TEXT_HELP[3], 2)
      self.contents.draw_text(349, 0, 70, WLH, CAO::MB::TEXT_HELP[4])
      self.contents.draw_text(459, 0, 30, WLH, CAO::MB::TEXT_HELP[5], 2)
    end
    self.contents.font.color = normal_color
    draw_defeated_number(107, 0, 40, WLH, 0)
    self.contents.draw_text(263, 0, 40, WLH, get_encounter_percent, 2)
    text = get_entry_percent(CAO::MB::COMPLETE_NUMBER)
    if text == 100 && CAO::MB::COMPLETE_COLOR
      self.contents.font.color.set(240, 36, 12)
    end
    self.contents.draw_text(419, 0, 40, WLH, text, 2)
  end
  #--------------------------------------------------------------------------
  # ● 倒した数の描画
  #--------------------------------------------------------------------------
  def draw_defeated_number(x, y, w, h, enemy_id)
    self.contents.clear_rect(x, y, w, h)
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, w, h, @enemy[enemy_id].defeat, 2)
  end
end

class Scene_MonsterBook < Scene_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(menu_index = -1)
    @menu_index = menu_index
  end
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    create_title_window
    create_command_window
    create_graphic_sprite
    @status_window = Window_MbookStatus.new
    @help_window = Window_MBookHelp.new
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    @command_window.dispose
    @title_window.dispose
    @status_window.dispose
    @help_window.dispose
    @graphic_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if @graphic_sprite.visible
      if Input.trigger?(Input::C) || Input.trigger?(Input::B)
        Sound.play_cancel
        @graphic_sprite.visible = false
        @command_window.active = true
      end
    else
      if Input.trigger?(Input::B)
        Sound.play_cancel
        $scene = @menu_index < 0 ? Scene_Map.new : Scene_Menu.new(@menu_index)
      elsif Input.trigger?(Input::C)
        Sound.play_decision
        draw_enemy_graphics
        @graphic_sprite.visible = true
        @command_window.active = false
      end
    end
    if @command_window.active
      current_id = @command_window.index
      @command_window.update
      @status_window.update
      if @command_window.index != current_id
        @status_window.enemy = @command_window.index
        @help_window.draw_defeated_number(107,0,40,24, @command_window.index)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● メニュー画面系の背景作成
  #--------------------------------------------------------------------------
if CAO::MB::NO_WINDOW_GRAPHICS
  def create_menu_background
    @menuback_sprite = Sprite.new
    @menuback_sprite.bitmap = Cache.system("BackMBook")
    @menuback_sprite.z = 1
    update_menu_background
  end
end # if CAO::MB::NO_WINDOW_GRAPHICS
  #--------------------------------------------------------------------------
  # ● タイトルウィンドウの作成
  #--------------------------------------------------------------------------
  def create_title_window
    @title_window = Window_Base.new(0, 8, 180, 56)
    @title_window.opacity = CAO::MB::NO_WINDOW_GRAPHICS ? 0 : 255
    unless CAO::MB::NO_SYSTEM_FONT
      @title_window.contents.font.color = @title_window.normal_color
      @title_window.contents.draw_text(0,0,148,24, CAO::MB::TEXT_MB_TITLE, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_MbookCommand.new
    @command_window.index = 0
  end
  #--------------------------------------------------------------------------
  # ● モンスター画像を表示するスプライトを作成
  #--------------------------------------------------------------------------
  def create_graphic_sprite
    @graphic_sprite = Sprite.new
    @graphic_sprite.visible = false
    @graphic_sprite.bitmap = Bitmap.new(512, 384)
    @graphic_sprite.x = 16
    @graphic_sprite.y = 16
    @graphic_sprite.z = 200
  end
  #--------------------------------------------------------------------------
  # ● モンスター画像の描画
  #--------------------------------------------------------------------------
  def draw_enemy_graphics
    enemy = CAO::MB::Commands.unrestraint_array[@command_window.index]
    @graphic_sprite.bitmap.clear
    @graphic_sprite.bitmap.fill_rect(0, 0, 512, 384, Color.new(0, 0, 0, 128))
    bitmap = Cache.battler(enemy.data.battler_name, enemy.data.battler_hue)
    if CAO::MB::Commands.enemy_enable?(enemy, :graphics)
      @graphic_sprite.color = Color.new(0, 0, 0, 0)
    else
      @graphic_sprite.color = Color.new(0, 0, 0)
    end
    x = (512 - bitmap.width) / 2
    y = (384 - bitmap.height) / 2
    @graphic_sprite.bitmap.blt( x, y, bitmap, bitmap.rect)
  end
end

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 戦闘終了
  #     result : 結果 (0:勝利 1:逃走 2:敗北)
  #--------------------------------------------------------------------------
  alias _cao_battle_end_mbook battle_end
  def battle_end(result)
    if !$BTEST && (result != 2 || CAO::MB::AUTO_ENTRY_LOSE)
      for en in $game_troop.members
        next if $game_system.mbook[en.enemy_id].nil?
        enemy = CAO::MB::Commands.unrestraint_enemy(en.enemy_id)
        enemy.defeat += 1 if en.dead?   # 倒した数を増加
        enemy.encounter = true          # 遭遇済み
        if CAO::MB::AUTO_ENTRY && enemy.entry < 2
          if CAO::MB::AUTO_ENTRY_DEFEATED
            enemy.entry = 1 if en.dead?
          else
            enemy.entry = en.dead? ? 2 : 1
          end
        end
      end
    end
    _cao_battle_end_mbook(result)
  end
  #--------------------------------------------------------------------------
  # ○ 行動結果の表示
  #     target : 対象者
  #     obj    : スキルまたはアイテム
  #--------------------------------------------------------------------------
  alias _cao_display_action_effects_mbook display_action_effects
  def display_action_effects(target, obj = nil)
    if obj && /^<MB:解析>/ =~ obj.note
      unless target.skipped
        line_number = @message_window.line_number
        wait(5)
        display_critical(target, obj)
        display_damage(target, obj)
        display_state_changes(target, obj)
        if line_number == @message_window.line_number
          $game_system.mbook[target.enemy_id].entry = 3
          @message_window.add_instant_text("#{target.name}を解析した。")
        end
        if line_number != @message_window.line_number
          wait(30)
        end
        @message_window.back_to(line_number)
      end
    else
      _cao_display_action_effects_mbook(target, obj)
    end
  end
end
