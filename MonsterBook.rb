#=============================================================================
#  [RGSS2] モンスター図鑑 #2 - v2.0.1
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

  モンスター図鑑の機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

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
   CAO::MB::Commands.set_entry_item(enemy_id, params)
     params: "START","ENCOUNT","WINNER","ANALYZE","COMPLETE"

  ★ 閲覧の可否の変更
   $game_mbook.enemy(enemy_id).secret = value
     value = true:閲覧不可, false:閲覧可能

  ★ 初期登録
   エネミーのメモ欄に @MB_ENTRY[○] と記述
     ○ = 初期登録時の閲覧可能範囲。半角数字で記述

  ★ 初期閲覧不可
   エネミーのメモ欄に @MB_SECRET と記述

  ★ 完全非表示
   エネミーのメモ欄に @MB_DESELECTION と記述

=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module MB
  #--------------------------------------------------------------------------
  # ◇ 解析ステートの番号
  #--------------------------------------------------------------------------
  ID_ANALYZE = 17

  #--------------------------------------------------------------------------
  # ◇ 表示する項目
  #     (:name, :graphics, :status, :params, :drop, :weak, :come)
  #--------------------------------------------------------------------------
  # 初期
  ENTRY_START = []
  # 遭遇
  ENTRY_ENCOUNT = [:name, :graphics]
  # 勝利
  ENTRY_WINNER = [:name, :graphics, :status, :drop]
  # 解析
  ENTRY_ANALYZE = [:name, :graphics, :status, :drop, :params, :weak]
  # 完成
  ENTRY_COMPLETE = [:name, :graphics, :status, :drop, :params, :weak, :come]
  # 独自
  ENTRY_LIST = {}
  ENTRY_LIST[:name] = [:name]
  ENTRY_LIST[:graphics] = [:name, :graphics]

  #--------------------------------------------------------------------------
  # ◇ 自動登録する
  #--------------------------------------------------------------------------
  AUTO_ENTRY = true
    #--------------------------------------------------------------------------
    # ◇ 敗北しても登録する
    #     true  : 戦闘で負けても、倒した敵の加算と図鑑登録を行います。
    #     false : 戦闘に負けた場合は、何も行いません。
    #--------------------------------------------------------------------------
    AUTO_ENTRY_LOSE = false
    #--------------------------------------------------------------------------
    # ◇ 倒した敵のみ自動登録する
    #     true  : 敵を倒すと閲覧レベル１
    #     false : 遭遇でレベル１、倒すとレベル２
    #--------------------------------------------------------------------------
    AUTO_ENTRY_DEFEATED = false
  #--------------------------------------------------------------------------
  # ◇ ドロップ時にのみ表示
  #--------------------------------------------------------------------------
  AUTO_ENTRY_DROP = false

  #--------------------------------------------------------------------------
  # ◇ 命中率・回避率の項目の有無
  #--------------------------------------------------------------------------
  USABLE_HITEVA = true
  #--------------------------------------------------------------------------
  # ◇ 経験値・お金の項目の有無
  #--------------------------------------------------------------------------
  USABLE_EXPGOLD = true

  #--------------------------------------------------------------------------
  # ◇ 表示するステート
  #--------------------------------------------------------------------------
  USABLE_STATE = [2, 3, 4, 5, 6, 7, 8]
  #--------------------------------------------------------------------------
  # ◇ 表示する属性
  #--------------------------------------------------------------------------
  USABLE_ELEMENT = [9, 10, 11, 12, 13, 14, 15, 16]
  #--------------------------------------------------------------------------
  # ◇ 属性を１文字で表示する
  #     true  : 属性の最初の１文字のみを表示する。
  #     false : 指定されたアイコンで表示する。
  #--------------------------------------------------------------------------
  ONE_NAME_ELEMENT = false
    #------------------------------------------------------------------------
    # ◇ 属性のアイコン
    #------------------------------------------------------------------------
    ICON_ELEMENT = [104, 105, 106, 107, 108, 109, 110, 111]

  #--------------------------------------------------------------------------
  # ◇ 完成度を平均から求める
  #     true  : 表示されている項目数から算出
  #     false : すべての項目が表示されているエネミーをカウント
  #--------------------------------------------------------------------------
  COMPRATE_AVERAGE = true
  #--------------------------------------------------------------------------
  # ◇ ページ切り替えの速度
  #     0 〜 6 : 0 .. アニメーションなし, 1-6 .. 数値が大きいほど速い
  #--------------------------------------------------------------------------
  SLIDE_SPEED = 4

  #--------------------------------------------------------------------------
  # ◇ ウィンドウの表示
  #--------------------------------------------------------------------------
  BACK_WINDOW = true
  #--------------------------------------------------------------------------
  # ◇ 弱点画像をアイコンの後ろに表示
  #--------------------------------------------------------------------------
  BACK_WEAKICON = false
  #--------------------------------------------------------------------------
  # ◇ 各画像のファイル名
  #     画像ファイル名を設定 (nil で画像を使用しない)
  #--------------------------------------------------------------------------
  IMAGE_BACKGROUND = nil    # 全体の背景
  IMAGE_BACKSTATUS = nil    # ステータスの背景
  IMAGE_WEAK_PONIT = nil    # 弱点
  #--------------------------------------------------------------------------
  # ◇ システム文字の表示
  #--------------------------------------------------------------------------
  SYSTEM_TEXT = true
  #--------------------------------------------------------------------------
  # ◇ カラー
  #     COLOR_xxx : nil で色を変えない。
  #     ALPHA_xxx : 不透明度を 0-255 の数値で指定
  #--------------------------------------------------------------------------
  COLOR_UNREAD   = Color.new(102, 204, 64)    # 未読の項目名
  COLOR_COMPLETE = Color.new(240,  32, 12)    # 完成時
  # 不透明度の設定のみ
  ALPHA_SECRET = 128    # 非表示の名前一覧
  ALPHA_NODROP = 128    # 未設定のドロップアイテム
  #--------------------------------------------------------------------------
  # ◇ コメントのデフォルト文字サイズ
  #--------------------------------------------------------------------------
  COME_FONT_SIZE = 20

  #--------------------------------------------------------------------------
  # ◇ タイトル
  #--------------------------------------------------------------------------
  TEXT_TITLE = "モンスター図鑑"
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
  # ◇ ヘルプウィンドウの項目
  #--------------------------------------------------------------------------
  TEXT_HELP = [
    "倒した数", "体",   # 撃破数
    "遭遇率",   "％",   # 遭遇率
    "完成率",   "％"    # 完成率
  ]
  #--------------------------------------------------------------------------
  # ◇ 閲覧不可のパラメータ項目
  #--------------------------------------------------------------------------
  TEXT_SECRET = {
    :cmd    => "????????????",          # 項目名
    :name   => "????????",              # モンスターの名前
    :status => "???",                   # 攻撃力など
    :param  => "??????",                # 経験値、ゴールド
    :state  => "？ ？ ？ ？ ？ ？ ？",  # ステート
    :drop   => "？ --------------",     # ドロップアイテム 閲覧不可
  }
  #--------------------------------------------------------------------------
  # ◇ 未設定のドロップアイテム項目
  #--------------------------------------------------------------------------
  TEXT_NONDROP = "× --------------"
end
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


CAO::MB::COMMENT = {}

CAO::MB::ENTRY_START.freeze
CAO::MB::ENTRY_ENCOUNT.freeze
CAO::MB::ENTRY_WINNER.freeze
CAO::MB::ENTRY_ANALYZE.freeze
CAO::MB::ENTRY_COMPLETE.freeze
CAO::MB::ENTRY_LIST.freeze

module CAO::MB::Commands
  module_function
  #--------------------------------------------------------------------------
  # ● 表示項目を設定
  #--------------------------------------------------------------------------
  def set_entry_item(enemy_id, params)
    enemy = $game_mbook.enemy(enemy_id)
    return unless enemy
    enemy.entry = get_entry_parameters(params)
  end
  #--------------------------------------------------------------------------
  # ● 表示項目を追加
  #--------------------------------------------------------------------------
  def add_entry_item(enemy_id, *params)
    enemy = $game_mbook.enemy(enemy_id)
    return unless enemy
    enemy.entry |= get_entry_parameters(params)
  end
  #--------------------------------------------------------------------------
  # ● 表示項目を削除
  #--------------------------------------------------------------------------
  def remove_entry_item(enemy_id, *params)
    enemy = $game_mbook.enemy(enemy_id)
    return unless enemy
    enemy.entry -= get_entry_parameters(params)
  end
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの表示状況を変更
  #--------------------------------------------------------------------------
  def set_drop_item(enemy_id, index, value)
    enemy = $game_mbook.enemy(enemy_id)
    return unless enemy
    return if enemy.drop_item_max == 0
    return unless (0...enemy.drop_item_max) === index
    enemy.drop_items[index] = value
  end
  #--------------------------------------------------------------------------
  # ● 識別子ごとの表示項目を取得
  #--------------------------------------------------------------------------
  def get_entry_parameters(name)
    case name
    when Array
      entry = CAO::MB::ENTRY_COMPLETE & name
    when Symbol
      entry = CAO::MB::ENTRY_LIST[name]
    when /^START$/i
      entry = CAO::MB::ENTRY_START
    when /^ENCOUNT$/i
      entry = CAO::MB::ENTRY_ENCOUNT
    when /^WINNER$/i
      entry = CAO::MB::ENTRY_WINNER
    when /^ANALYZE$/i
      entry = CAO::MB::ENTRY_ANALYZE
    when /^COMPLETE$/i
      entry = CAO::MB::ENTRY_COMPLETE
    end
    return (entry || []).dup
  end
end

class RPG::Enemy
  #--------------------------------------------------------------------------
  # ● ドロップアイテムを配列で取得
  #--------------------------------------------------------------------------
  def drop_items
    if @drop_items == nil
      @drop_items = []
      @drop_items.push(@drop_item1) if @drop_item1.kind != 0
      @drop_items.push(@drop_item2) if @drop_item2.kind != 0
    end
    return @drop_items
  end
end

class RPG::Enemy::DropItem
  #--------------------------------------------------------------------------
  # ● アイテムの取得
  #--------------------------------------------------------------------------
  def item
    case @kind
    when 0; nil
    when 1; $data_items[@item_id]
    when 2; $data_weapons[@weapon_id]
    when 3; $data_armors[@armor_id]
    end
  end
end

class Game_Troop
  #--------------------------------------------------------------------------
  # ○ ドロップアイテムの配列作成
  #--------------------------------------------------------------------------
  def make_drop_items
    drop_items = []
    for enemy in dead_members
      enemy.enemy.drop_items.each_with_index do |di,i|
        next if di.kind == 0
        next if rand(di.denominator) != 0
        case di.kind
        when 1
          drop_items.push($data_items[di.item_id])
        when 2
          drop_items.push($data_weapons[di.weapon_id])
        when 3
          drop_items.push($data_armors[di.armor_id])
        end
        $game_mbook.enemy(enemy.enemy.id).drop_items[i] = true
      end
    end
    return drop_items
  end
end

class Game_MbookEnemy
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :id                       # ＩＤ
  attr_reader   :enemy                    # エネミーのオブジェクト
  attr_accessor :entry                    #
  attr_accessor :secret                   # 閲覧可否 (不可/可能)
  attr_accessor :unread                   # 既読状態 (未読/既読)
  attr_accessor :defeat                   # 撃退数
  attr_accessor :encount                  # 遭遇の有無 (遭遇済み/未遭遇)
  attr_accessor :drop_items               # ドロップアイテム (表示/非表示)
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     id    : ＩＤ
  #     enemy : エネミー
  #--------------------------------------------------------------------------
  def initialize(id, enemy)
    @id = id
    @enemy = enemy
    reset
  end
  #--------------------------------------------------------------------------
  # ● 登録情報のクリア
  #--------------------------------------------------------------------------
  def clear
    @entry = []
    @secret = false
    @unread = true
    @defeat = 0
    @encount = false
    @drop_items = Array.new(@enemy.drop_items.size, false)
  end
  #--------------------------------------------------------------------------
  # ● 登録情報の初期化
  #--------------------------------------------------------------------------
  def reset
    clear
    reset_entry
    reset_secret
  end
  #--------------------------------------------------------------------------
  # ● 表示項目を初期化
  #--------------------------------------------------------------------------
  def reset_entry
    case self.note[/^@MB_ENTRY\[\s*([A-Z]+)\s*\]/i, 1]
    when /ENCOUNT/i
      @entry = CAO::MB::ENTRY_ENCOUNT
    when /WINNER/i
      @entry = CAO::MB::ENTRY_WINNER
    when /ANALYZE/i
      @entry = CAO::MB::ENTRY_ANALYZE
    when /COMPLETE/i
      complete
    else
      if self.note[/^@MB_ENTRY\[\s*:([_a-z]\w*)\s*\]/i, 1]
        @entry = CAO::MB::ENTRY_LIST[$1.to_sym]
      else
        @entry = CAO::MB::ENTRY_START
      end
    end
    @entry = @entry.dup
  end
  #--------------------------------------------------------------------------
  # ● 非表示設定を初期化
  #--------------------------------------------------------------------------
  def reset_secret
    @secret = /^@MB_SECRET/ === self.note
  end

  #--------------------------------------------------------------------------
  # ● 項目が有効か判定
  #--------------------------------------------------------------------------
  def enable?(param)
   return false if @secret
   return @entry.include?(param)
  end
  #--------------------------------------------------------------------------
  # ● 完成しているか判定 (非表示かどうかは考慮しない)
  #--------------------------------------------------------------------------
  def complete?
#~     return false if @secret
    return false if CAO::MB::AUTO_ENTRY_DROP && !@drop_items.all?
    return (CAO::MB::ENTRY_COMPLETE - @entry).empty?
  end

  #--------------------------------------------------------------------------
  # ● 敵キャラオブジェクト取得
  #--------------------------------------------------------------------------
  alias data enemy
  #--------------------------------------------------------------------------
  # ● エネミーの名前を取得
  #--------------------------------------------------------------------------
  def name
    return @enemy.name
  end
  #--------------------------------------------------------------------------
  # ● コメントの取得
  #--------------------------------------------------------------------------
  def comment
    return $data_mbcomments[@enemy.id] || $data_mbcomments[0] || [""]
  end
  #--------------------------------------------------------------------------
  # ● メモの取得
  #--------------------------------------------------------------------------
  def note
    return @enemy.note
  end
  #--------------------------------------------------------------------------
  # ● 戦闘グラフィックのファイル名の取得
  #--------------------------------------------------------------------------
  def battler_name
    return @enemy.battler_name
  end
  #--------------------------------------------------------------------------
  # ● 戦闘グラフィックの色相の取得
  #--------------------------------------------------------------------------
  def battler_hue
    return @enemy.battler_hue
  end
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの最大数の取得
  #--------------------------------------------------------------------------
  def drop_item_max
    return @enemy.drop_items.size
  end

  #--------------------------------------------------------------------------
  # ● 図鑑を完成させる
  #--------------------------------------------------------------------------
  def complete
    @entry = CAO::MB::ENTRY_COMPLETE.dup
    @drop_items.map! { true }
    @secret = false
  end
end

class Game_MonsterBook
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @data = []
  end
  #--------------------------------------------------------------------------
  # ● エネミーの図鑑情報を取得
  #--------------------------------------------------------------------------
  def [](book_id = nil)
    return (book_id == nil) ? @data : @data[book_id]
  end
  #--------------------------------------------------------------------------
  # ● エネミーの図鑑情報を設定
  #--------------------------------------------------------------------------
  def []=(book_id, value)
    @data[book_id] = value
  end
  #--------------------------------------------------------------------------
  # ● エネミーのゲームオブジェクトを取得
  #--------------------------------------------------------------------------
  def enemy(enemy_id)
    return @data.detect {|e| enemy_id == e.enemy.id }
  end
  #--------------------------------------------------------------------------
  # ● エネミーのゲームオブジェクトを取得
  #--------------------------------------------------------------------------
  def enemies(*enemies_id)
    if enemies_id.empty?
      return @data
    else
      return @data.select {|e| enemies_id.include?(e.enemy.id) }
    end
  end
  #--------------------------------------------------------------------------
  # ● 図鑑に登録できるエネミーの数
  #--------------------------------------------------------------------------
  def size
    return @data.size
  end

  #--------------------------------------------------------------------------
  # ● 図鑑を完全リセット
  #--------------------------------------------------------------------------
  def reset
    @data.clear
    id = 0
    for i in 1...$data_enemies.size
      next if $data_enemies[i].note[/^@MB_DESELECTION/i]
      @data[id] = Game_MbookEnemy.new(id, $data_enemies[i])
      id += 1
    end
  end

  #--------------------------------------------------------------------------
  # ● 除外されたエネミーか判定
  #--------------------------------------------------------------------------
  def include?(enemy_id)
    return enemy(enemy_id) != nil
  end
  #--------------------------------------------------------------------------
  # ● 図鑑が完成しているか判定 (すべて表示されているか)
  #--------------------------------------------------------------------------
  def complete?
    return false if @data.any? {|e| e.secret }
    return @data.size == self.completion_count
  end
  #--------------------------------------------------------------------------
  # ● 図鑑を完成させる
  #--------------------------------------------------------------------------
  def complete
    @data.each {|e| e.complete }
  end

  #--------------------------------------------------------------------------
  # ● 総完成数の取得
  #--------------------------------------------------------------------------
  def completion_count
    return @data.select {|e| e.complete? }.size
  end
  #--------------------------------------------------------------------------
  # ● 総登録数の取得
  #--------------------------------------------------------------------------
  def entry_count(*params)
    if params.empty?
      return @data.select {|e| !e.entry.empty? }.size
    else
      return @data.select {|e| params.size < (e.entry & params).size }.size
    end
  end
  #--------------------------------------------------------------------------
  # ● 総撃退数の取得
  #--------------------------------------------------------------------------
  def defeat_count(*list_id)
    if list_id.empty?
      return @data.inject(0) {|c, e| c + e.defeat }
    else
      return list_id.inject(0) {|c, id| c + @data[id].defeat }
    end
  end
  #--------------------------------------------------------------------------
  # ● 遭遇した種類数を取得
  #--------------------------------------------------------------------------
  def encount_count
    return @data.select {|e| e.encount }.size
  end

  #--------------------------------------------------------------------------
  # ● 図鑑の完成度の取得
  #--------------------------------------------------------------------------
  def completion_rate
    if CAO::MB::COMPRATE_AVERAGE
      count = 0.0
      for e in @data
        next if e.secret
        count += e.entry.size
        if CAO::MB::AUTO_ENTRY_DROP && e.drop_item_max != 0
          count -= 1
          count += e.drop_items.select {|r| r }.size / e.drop_item_max
        end
      end
      return Integer(count / CAO::MB::ENTRY_COMPLETE.size * 100 / @data.size)
    else
      return completion_count * 100 / @data.size
    end
  end
  #--------------------------------------------------------------------------
  # ● 遭遇した種類を百分率で取得
  #--------------------------------------------------------------------------
  def encount_rate
    return encount_count * 100 / @data.size
  end

#~   #--------------------------------------------------------------------------
#~   # ● 配列の操作ができるようにするか検討中 一応 $game_mbook[] とかで対応済
#~   #--------------------------------------------------------------------------
#~   def method_missing(name, *args, &block)
#~     eval("@data.#{name}(*args, &block)")
#~   rescue => error
#~     raise $!.class, $!.message, caller.first
#~   end
end

module CAO::MB
  # コメントのパス
  COMMENT_FILE = "MBComments.txt"
  COMMENT_DATA = "Data/MBComments.rvdata"
  module Commands
    #--------------------------------------------------------------------------
    # ● コメントデータの作成
    #--------------------------------------------------------------------------
    def self.create_comment_data
      return unless $TEST && FileTest.file?(CAO::MB::COMMENT_FILE)
      comments = {}
      File.open(CAO::MB::COMMENT_FILE) do |file|
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
              next if $data_enemies[i].name != $1
              id = i
              break
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
      save_data(comments, CAO::MB::COMMENT_DATA)
    end
  end
end

class Scene_Title
  #--------------------------------------------------------------------------
  # ○ コマンド : ニューゲーム
  #--------------------------------------------------------------------------
  alias _cao_mbook_command_new_game command_new_game
  def command_new_game
    _cao_mbook_command_new_game
    $game_mbook.reset
  end
  #--------------------------------------------------------------------------
  # ○ データベースのロード
  #--------------------------------------------------------------------------
  alias _cao_mbook_load_database load_database
  def load_database
    _cao_mbook_load_database
    begin
      CAO::MB::Commands.create_comment_data
      $data_mbcomments = load_data(CAO::MB::COMMENT_DATA)
    rescue Errno::ENOENT
      $data_mbcomments = CAO::MB::COMMENT
    end
  end
  #--------------------------------------------------------------------------
  # ○ 各種ゲームオブジェクトの作成
  #--------------------------------------------------------------------------
  alias _cao_mbook_create_game_objects create_game_objects
  def create_game_objects
    _cao_mbook_create_game_objects
    $game_mbook = Game_MonsterBook.new
  end
end

class Scene_File
  #--------------------------------------------------------------------------
  # ○ セーブデータの書き込み
  #--------------------------------------------------------------------------
  alias _cao_mbook_write_save_data write_save_data
  def write_save_data(file)
    _cao_mbook_write_save_data(file)
    Marshal.dump($game_mbook, file)
  end
  #--------------------------------------------------------------------------
  # ○ セーブデータの読み込み
  #--------------------------------------------------------------------------
  alias _cao_mbook_read_save_data read_save_data
  def read_save_data(file)
    _cao_mbook_read_save_data(file)
    $game_mbook = Marshal.load(file)
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_mbook_update_scene_change update_scene_change
  def update_scene_change
    return if $game_player.moving?
    if $game_temp.next_scene == "mbook"
      $game_temp.next_scene = nil
      $scene = Scene_MonsterBook.new
    end
    _cao_mbook_update_scene_change
  end
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ● 図鑑を起動する
  #--------------------------------------------------------------------------
  def start_mbook
    $scene = Scene_MonsterBook.new(@command_window.index)
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
    self.opacity = CAO::MB::BACK_WINDOW ? 255 : 0
    self.index = 0
    @item_max = $game_mbook.size
    refresh
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の作成
  #--------------------------------------------------------------------------
  def create_contents
    self.contents.dispose
    h = [height - 32, $game_mbook.size * WLH].max
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
    if $game_mbook[index].entry.empty? || $game_mbook[index].secret
      self.contents.font.color.alpha = CAO::MB::ALPHA_SECRET
      self.contents.draw_text(rect, CAO::MB::TEXT_SECRET[:cmd], 2)
    else
      rect.x = 32
      rect.width -= 28
      if $game_mbook[index].unread
        self.contents.font.color = CAO::MB::COLOR_UNREAD
      end
      self.contents.draw_text(rect, $game_mbook[index].name, 2)
    end
  end
end

class Window_MbookStatus < Window_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  PAGE_WIDTH  = 288
  PAGE_HEIGHT = 240
  SLIDE_SPEED = PAGE_WIDTH / [1, 48, 32, 16, 8, 4, 2][CAO::MB::SLIDE_SPEED]
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(216, 72, PAGE_WIDTH + 32, PAGE_HEIGHT + 32)
    self.opacity = CAO::MB::BACK_WINDOW ? 255 : 0
    self.ox = PAGE_WIDTH
    @enemy = $game_mbook[0]
    @page = 1
    @slide_x = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の作成
  #--------------------------------------------------------------------------
  def create_contents
    self.contents.dispose
    self.contents = Bitmap.new(PAGE_WIDTH * 3, PAGE_HEIGHT)
    if CAO::MB::IMAGE_BACKSTATUS
      @back_sprite = Sprite.new
      @back_sprite.bitmap = Cache.system(CAO::MB::IMAGE_BACKSTATUS)
      @back_sprite.x = self.x
      @back_sprite.y = self.y
      @back_sprite.z = 0
      @back_sprite.ox = PAGE_WIDTH
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    super
    @back_sprite.dispose if @back_sprite
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    last_page = @page
    if Input.trigger?(Input::LEFT) && self.ox > 0
      @page -= 1
      @slide_x = -SLIDE_SPEED
    elsif Input.trigger?(Input::RIGHT) && self.ox < 576
      @page += 1
      @slide_x = SLIDE_SPEED
    end
    if @page != last_page
      Sound.play_cursor
      refresh
    end
    # ページ切り替えの更新
    if @slide_x != 0
      self.ox += @slide_x
      @back_sprite.ox += @slide_x if @back_sprite
      @slide_x = 0 if self.ox % PAGE_WIDTH == 0
    end
  end
  #--------------------------------------------------------------------------
  # ● ページのｘ座標
  #--------------------------------------------------------------------------
  def page_x
    return PAGE_WIDTH * @page
  end
  #--------------------------------------------------------------------------
  # ● 選択中のインデックス
  #--------------------------------------------------------------------------
  def index=(index)
    @enemy = $game_mbook[index]
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 項目を許可状態で表示するかどうか
  #--------------------------------------------------------------------------
  def enable?(param)
    return @enemy.enable?(param)
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @enemy.unread = false unless @enemy.entry.empty?
    self.contents.clear_rect(self.page_x, 0, 288, 240)
    case @page
    when 0
      draw_comments
    when 1
      x = self.page_x
      self.contents.font.color = normal_color
      self.contents.draw_text(x + 4, 0, 280, WLH,
        enable?(:name) ? @enemy.name : CAO::MB::TEXT_SECRET[:name])
      draw_enemy_parameter(x, 33)
      draw_drop_items(x, 168)
    when 2
      draw_weak_point(self.page_x)
    end
  end
  #--------------------------------------------------------------------------
  # ● コメントの描画
  #--------------------------------------------------------------------------
  def draw_comments
    self.contents.font.color = normal_color
    self.contents.font.size = CAO::MB::COME_FONT_SIZE
    text = enable?(:come) ? @enemy.comment : $data_mbcomments[0] || [""]
    for i in 0...text.size
      draw_message(text[i], WLH * i)
    end
    self.contents.font.size = Font.default_size
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
        break if PAGE_WIDTH < (x + contents.text_size(c).width)
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
    # ステータスの描画
    for i in 0...(CAO::MB::USABLE_HITEVA ? 8 : 6)
      xx = x + i % 2 * 152
      yy = y + i / 2 * WLH
      if CAO::MB::SYSTEM_TEXT
        self.contents.font.color = system_color
        self.contents.draw_text(xx, yy, 60, WLH, CAO::MB::TEXT_STATUS[i])
      end
      self.contents.font.color = normal_color
      t = enable?(:status) ? params[i] : CAO::MB::TEXT_SECRET[:status]
      self.contents.draw_text(xx + 60, yy, 72, WLH, t, 2)
    end
    return unless CAO::MB::USABLE_EXPGOLD
    y = CAO::MB::USABLE_HITEVA ? 135 : 135 - WLH
    # 経験値とお金の描画
    if CAO::MB::SYSTEM_TEXT
      self.contents.font.color = system_color
      self.contents.draw_text(x, y, 60, WLH, CAO::MB::TEXT_STATUS[8])
      self.contents.draw_text(x + 152, y, 60, WLH, CAO::MB::TEXT_STATUS[9])
    end
    self.contents.font.color = normal_color
    if enable?(:params)
      self.contents.draw_text(x + 60, y, 72, WLH, @enemy.data.exp, 2)
      self.contents.draw_text(x + 212, y, 72, WLH, @enemy.data.gold, 2)
    else
      t = CAO::MB::TEXT_SECRET[:param]
      self.contents.draw_text(x + 60, y, 72, WLH, t, 2)
      self.contents.draw_text(x + 212, y, 72, WLH, t, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの描画
  #--------------------------------------------------------------------------
  def draw_drop_items(x, y)
    y -= WLH unless CAO::MB::USABLE_HITEVA
    y -= WLH unless CAO::MB::USABLE_EXPGOLD
    if CAO::MB::SYSTEM_TEXT
      self.contents.font.color = system_color
      self.contents.draw_text(x, y, 160, WLH, CAO::MB::TEXT_STATUS[10])
    end
    item_max = 2
    item_max += 1 unless CAO::MB::USABLE_HITEVA
    item_max += 1 unless CAO::MB::USABLE_EXPGOLD
    for i in 0...item_max
      draw_drop_item(x + 24, y + WLH, i)
    end
  end
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの描画
  #--------------------------------------------------------------------------
  def draw_drop_item(x, y, index)
    y += 24 * index
    if enable?(:drop)
      if index < @enemy.drop_item_max
        if CAO::MB::AUTO_ENTRY_DROP && !@enemy.drop_items[index]
          draw_disable_item(x, y)
        else
          item = @enemy.data.drop_items[index].item
          draw_icon(item.icon_index, x, y)
          self.contents.font.color = normal_color
          self.contents.draw_text(x + 26, y, 230, WLH, item.name)
        end
      else
        # 未設定アイテムの描画
        self.contents.font.color = normal_color
        self.contents.font.color.alpha = CAO::MB::ALPHA_NODROP
        self.contents.draw_text(x, y, 230, WLH, CAO::MB::TEXT_NONDROP)
      end
    else
      draw_disable_item(x, y)
    end
  end
  #--------------------------------------------------------------------------
  # ● 非表示ドロップアイテムの描画
  #--------------------------------------------------------------------------
  def draw_disable_item(x, y)
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, 230, WLH, CAO::MB::TEXT_SECRET[:drop])
  end
  #--------------------------------------------------------------------------
  # ● 弱点の描画
  #--------------------------------------------------------------------------
  def draw_weak_point(x)
    if CAO::MB::SYSTEM_TEXT
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
        t = CAO::MB::TEXT_SECRET[:state]
        self.contents.draw_text(x+36,60*i+24,240,WLH, t)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 属性アイコンの描画
  #--------------------------------------------------------------------------
  def draw_element_icon(x, y)
    count = 0
    for i in 0...CAO::MB::USABLE_ELEMENT.size
      if @enemy.data.element_ranks[CAO::MB::USABLE_ELEMENT[i]] < 3
        if CAO::MB::ONE_NAME_ELEMENT
          rank = @enemy.data.element_ranks[CAO::MB::USABLE_ELEMENT[i]]
          text = $data_system.elements[CAO::MB::USABLE_ELEMENT[i]][/./]
          draw_weak_icon(text, x + 26 * count, y, rank)
        else
          icon_index = CAO::MB::ICON_ELEMENT[i]
          rank = @enemy.data.element_ranks[CAO::MB::USABLE_ELEMENT[i]]
          draw_weak_icon(icon_index, x + 26 * count, y, rank)
        end
        count += 1
      end
    end
    count = 0
    for i in 0...CAO::MB::USABLE_ELEMENT.size
      if @enemy.data.element_ranks[CAO::MB::USABLE_ELEMENT[i]] > 3
        if CAO::MB::ONE_NAME_ELEMENT
          rank = @enemy.data.element_ranks[CAO::MB::USABLE_ELEMENT[i]]
          text = $data_system.elements[CAO::MB::USABLE_ELEMENT[i]][/./]
          draw_weak_icon(text, x + 26 * count, y + 120, rank)
        else
          icon_index = CAO::MB::ICON_ELEMENT[i]
          rank = @enemy.data.element_ranks[CAO::MB::USABLE_ELEMENT[i]]
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
    for en in CAO::MB::USABLE_STATE
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
    if icon_index.is_a?(String)
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
      rect = Rect.new(0, 0, 24, 24)
      if CAO::MB::IMAGE_WEAK_PONIT && CAO::MB::BACK_WEAKICON
        rect.x = (rank - 1) % 6 * 24
        rect.y = (rank - 1) / 6 * 24
        self.contents.blt(x, y, Cache.system(CAO::MB::IMAGE_WEAK_PONIT), rect)
      end
      rect.x = icon_index % 16 * 24
      rect.y = icon_index / 16 * 24
      self.contents.blt(x, y, Cache.system("Iconset"), rect)
      if CAO::MB::IMAGE_WEAK_PONIT && !CAO::MB::BACK_WEAKICON
        rect.x = (rank - 1) % 6 * 24
        rect.y = (rank - 1) / 6 * 24
        self.contents.blt(x, y, Cache.system(CAO::MB::IMAGE_WEAK_PONIT), rect)
      end
    end
  end
end

class Window_MbookHelp < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(8, 352, 528, 56)
    self.opacity = CAO::MB::BACK_WINDOW ? 255 : 0
    @item_max = $game_mbook.size
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    draw_system_text
    draw_defeat_count(0)
    draw_encount_count
    draw_completion_rate
  end
  #--------------------------------------------------------------------------
  # ● システム文字の描画
  #--------------------------------------------------------------------------
  def draw_system_text
    return unless CAO::MB::SYSTEM_TEXT
    self.contents.font.color = system_color
    # 倒した数
    self.contents.draw_text(  7, 0, 100, WLH, CAO::MB::TEXT_HELP[0])
    self.contents.draw_text(147, 0,  30, WLH, CAO::MB::TEXT_HELP[1], 2)
    # 遭遇数
    self.contents.draw_text(193, 0,  70, WLH, CAO::MB::TEXT_HELP[2])
    self.contents.draw_text(303, 0,  30, WLH, CAO::MB::TEXT_HELP[3], 2)
    # 完成度
    self.contents.draw_text(349, 0,  70, WLH, CAO::MB::TEXT_HELP[4])
    self.contents.draw_text(459, 0,  30, WLH, CAO::MB::TEXT_HELP[5], 2)
  end
  #--------------------------------------------------------------------------
  # ● 倒した数の描画
  #--------------------------------------------------------------------------
  def draw_defeat_count(id)
    self.contents.clear_rect(107, 0, 40, WLH)
    self.contents.font.color = normal_color
    self.contents.draw_text(107, 0, 40, WLH, $game_mbook[id].defeat, 2)
  end
  #--------------------------------------------------------------------------
  # ● 遭遇数の描画
  #--------------------------------------------------------------------------
  def draw_encount_count
    self.contents.font.color = normal_color
    self.contents.draw_text(263, 0, 40, WLH, $game_mbook.encount_rate, 2)
  end
  #--------------------------------------------------------------------------
  # ● 完成度の描画
  #--------------------------------------------------------------------------
  def draw_completion_rate
    if $game_mbook.complete? && CAO::MB::COLOR_COMPLETE
      self.contents.font.color = CAO::MB::COLOR_COMPLETE
    end
    self.contents.draw_text(419, 0, 40, WLH, $game_mbook.completion_rate, 2)
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
    @help_window = Window_MbookHelp.new
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
  # ● メニュー画面系の背景作成
  #--------------------------------------------------------------------------
  if CAO::MB::IMAGE_BACKGROUND
  def create_menu_background
    @menuback_sprite = Sprite.new
    @menuback_sprite.bitmap = Cache.system(CAO::MB::IMAGE_BACKGROUND)
    @menuback_sprite.z = 1
    update_menu_background
  end
  end # if CAO::MB::IMAGE_BACKGROUND
  #--------------------------------------------------------------------------
  # ● タイトルウィンドウの作成
  #--------------------------------------------------------------------------
  def create_title_window
    @title_window = Window_Base.new(0, 8, 180, 56)
    @title_window.opacity = CAO::MB::BACK_WINDOW ? 255 : 0
    if CAO::MB::SYSTEM_TEXT
      @title_window.contents.font.color = @title_window.normal_color
      @title_window.contents.draw_text(0, 0, 148, 24, CAO::MB::TEXT_TITLE, 1)
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
  # ● 元の画面へ戻る
  #--------------------------------------------------------------------------
  def return_scene
    $scene = (@menu_index < 0) ? Scene_Map.new : Scene_Menu.new(@menu_index)
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    current_id = @command_window.index
    @command_window.update
    @status_window.update
    @graphic_sprite.update
    if @command_window.index != current_id
      @status_window.index = @command_window.index
      @help_window.draw_defeat_count(@command_window.index)
      draw_enemy_graphics
    end
    if @graphic_sprite.visible
      update_graphic_input
    else
      update_command_input
    end
  end
  #--------------------------------------------------------------------------
  # ● グラフィック切り替えの更新
  #--------------------------------------------------------------------------
  def update_graphic_input
    if Input.trigger?(Input::C) || Input.trigger?(Input::B)
      Sound.play_cancel
      @graphic_sprite.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ● エネミー選択の更新
  #--------------------------------------------------------------------------
  def update_command_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene
    elsif Input.trigger?(Input::C)
      Sound.play_decision
      @graphic_sprite.visible = true
      draw_enemy_graphics
    end
  end
  #--------------------------------------------------------------------------
  # ● モンスター画像の描画
  #--------------------------------------------------------------------------
  def draw_enemy_graphics
    return unless @graphic_sprite.visible
    enemy = $game_mbook[@command_window.index]
    @graphic_sprite.bitmap.fill_rect(0, 0, 512, 384, Color.new(0, 0, 0, 128))
    bitmap = Cache.battler(enemy.battler_name, enemy.battler_hue)
    if enemy.enable?(:graphics)
      @graphic_sprite.color.set(0, 0, 0, 0)
    else
      @graphic_sprite.color.set(0, 0, 0)
    end
    x = (512 - bitmap.width) / 2
    y = (384 - bitmap.height) / 2
    @graphic_sprite.bitmap.blt(x, y, bitmap, bitmap.rect)
  end
end

unless $BTEST
class Scene_Battle
  #--------------------------------------------------------------------------
  # ○ 戦闘終了
  #     result : 結果 (0:勝利 1:逃走 2:敗北)
  #--------------------------------------------------------------------------
  alias _cao_mbook_battle_end battle_end
  def battle_end(result)
    if CAO::MB::AUTO_ENTRY_LOSE || result != 2
      for en in $game_troop.members
        enemy = $game_mbook.enemy(en.enemy_id)
        next if enemy.nil?
        enemy.defeat += 1 if en.dead?   # 倒した数を増加
        enemy.encount = true            # 遭遇済み
        if CAO::MB::AUTO_ENTRY
          if CAO::MB::AUTO_ENTRY_DEFEATED   # 勝利時のみ登録
            enemy.entry |= CAO::MB::ENTRY_WINNER if en.dead?
          elsif en.dead?                    # 倒していれば登録
            enemy.entry |= CAO::MB::ENTRY_WINNER
          else                              # 遭遇のみ
            enemy.entry |= CAO::MB::ENTRY_ENCOUNT
          end
        end
      end
    end
    _cao_mbook_battle_end(result)
  end
  #--------------------------------------------------------------------------
  # ● アナライズの実行
  #     target : 解析対象
  #--------------------------------------------------------------------------
  def execute_analyze(target)
    return if target.skipped
    return unless target.is_a?(Game_Enemy)
    return unless target.state?(CAO::MB::ID_ANALYZE)
    $game_mbook.enemy(target.enemy_id).entry |= CAO::MB::ENTRY_ANALYZE
  end
  #--------------------------------------------------------------------------
  # ○ 行動結果の表示
  #     target : 対象者
  #     obj    : スキルまたはアイテム
  #--------------------------------------------------------------------------
  alias _cao_mbook_display_action_effects display_action_effects
  def display_action_effects(target, obj = nil)
    execute_analyze(target)
    _cao_mbook_display_action_effects(target, obj)
  end
end
end # unless $BTEST
