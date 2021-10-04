#=============================================================================
#  [RGSS2] パーティ編成 - v2.1.3
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

  パーティ編成機能を追加します。
  パーティから外せないキャラを設定できます。
  パーティに追加できないキャラを設定できます。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、Cacao Base Script が必要です。

 -- 画像規格 ----------------------------------------------------------------

  ★ ロック画像
   16 x 16 の画像（Lock）を "Graphics/system" に用意してください。
   この画像は、パーティから外せないアクターを識別するために使用します。

 -- 使用方法 ----------------------------------------------------------------

  ※ ⇒ は、イベントコマンド「ラベル」に記述する文章です。

  ★ 編成画面の表示
   ⇒ <パーティ編成>
   § start_party_selection   （[Scene_Menu]で呼び出す）

  ★ パーティから外せないアクターの設定
   ⇒ >必須メンバ：[アクター番号]     （初期化）
   ⇒ >必須メンバ：[アクター番号]+    （追加）
   ⇒ >必須メンバ：[アクター番号]-    （除外）
   ※ 複数指定する場合は、>○○：[1, 2, 3, 4]+ のように記述してください。
 
  ★ 必須メンバーすべて削除する。
   ⇒ <必須メンバクリア>
 
  ★ すべてのアクターを追加可能にする。
   ⇒ <全メンバ待機>
 
  ★ パーティに追加できるアクターの設定
   ⇒ >待機メンバ：[アクター番号]     （初期化）
   ⇒ >待機メンバ：[アクター番号]+    （追加）
   ⇒ >待機メンバ：[アクター番号]-    （除外）
   ※ 複数指定する場合は、>○○：[1, 2, 3, 4]+ のように記述してください。
 
  ★ 待機メンバーをすべて削除する。
   ⇒ <待機メンバクリア>

=end


#==============================================================================
# ◆ 設定項目
#==============================================================================

module CAO_MEMBER
  #--------------------------------------------------------------------------
  # ◇ パーティの最大人数（４人以下）
  #--------------------------------------------------------------------------
    MAX_MEMBERS = 4
  #--------------------------------------------------------------------------
  # ◇ キャラクターグラフィクのサイズ
  #    ※ ファイルのサイズではなく、キャラのサイズです。（推奨：32×32）
  #--------------------------------------------------------------------------
    CHARACTER_WIDTH = 32    # キャラクターの横サイズ
    CHARACTER_HEIGHT = 32   # キャラクターの縦サイズ
  #--------------------------------------------------------------------------
  # ◇ 横に並べる待機メンバーの最大数
  #    ※ キャラサイズによって自動調整されます。 (推奨：4)
  #--------------------------------------------------------------------------
    MAX_COLUMN = 4
  #--------------------------------------------------------------------------
  # ◇ 用語の設定
  #--------------------------------------------------------------------------
    # オプション名
    POTENTIAL_NAME_0 = "潜在能力"
    
    # オプションの項目名
    POTENTIAL_NAME_1 = "自動戦闘"
    POTENTIAL_NAME_2 = "装備固定"
    POTENTIAL_NAME_3 = "二刀流"
    POTENTIAL_NAME_4 = "強力防御"
    POTENTIAL_NAME_5 = "薬の知識"
    POTENTIAL_NAME_6 = "クリティカル"

    # 確認画面の項目名
    COMMAND_TEXT = ["編成完了", "やり直す", "やめる"]
end
module Vocab
  # 経験値
  def self.exp
    return "経験値"
  end
  # 経験値 (略)
  def self.exp_a
    return "Ｅ"
  end
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::Commands
  #--------------------------------------------------------------------------
  # ◎ メンバの配列を収得
  #--------------------------------------------------------------------------
  def self.member_ary(str)
    return str.scan(/\d+/).collect! { |s| s.to_i }
  end
  #--------------------------------------------------------------------------
  # ◎ 必須メンバの処理
  #--------------------------------------------------------------------------
  def self.required_member(ary, type)
    case type
    when "+"
      for i in 0...ary.size
        $game_actors[ary[i]].required = true
      end
    when "-"
      for i in 0...ary.size
        $game_actors[ary[i]].required = false
      end
    else
      for i in 1...$data_actors.size
        $game_actors[i].required = false
      end
      for i in 0...ary.size
        $game_actors[ary[i]].required = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 待機メンバの処理
  #--------------------------------------------------------------------------
  def self.standby_unit(ary, type)
    case type
    when "+"
      for i in 0...ary.size
        $game_actors[ary[i]].unavailable = false
      end
    when "-"
      for i in 0...ary.size
        $game_actors[ary[i]].unavailable = true
      end
    else
      for i in 1...$data_actors.size
        $game_actors[i].unavailable = true
      end
      for i in 0...$game_party.members.size
        $game_party.members[i].unavailable = false
      end
      for i in 0...ary.size
        $game_actors[ary[i]].unavailable = false
      end
    end
  end  
  #--------------------------------------------------------------------------
  # ◎ すべての必須メンバーを解除する
  #--------------------------------------------------------------------------
  def self.actor_all_required_nomember
    for i in 1...$data_actors.size
      $game_actors[i].required = false
    end
  end
  #--------------------------------------------------------------------------
  # ◎ すべてのアクターを待機メンバーにする
  #--------------------------------------------------------------------------
  def self.actor_all_member
    for i in 1...$data_actors.size
      $game_actors[i].unavailable = false
    end
  end
  #--------------------------------------------------------------------------
  # ◎ すべてのアクターを待機メンバーから外す
  #--------------------------------------------------------------------------
  def self.actor_all_nomember
    for i in 1...$data_actors.size
      $game_actors[i].unavailable = true
    end
  end
end

module Sound
  # ページ捲り
  def self.play_page
      Audio.se_play("Audio/SE/Book", 80)
  end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ○ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :required       # 必須メンバー（true）
  attr_accessor :unavailable    # パーティに加えられない（true）
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     actor_id : アクター ID
  #--------------------------------------------------------------------------
  def initialize(actor_id)
    super()
    setup(actor_id)
    @last_skill_id = 0
  end
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #     actor_id : アクター ID
  #--------------------------------------------------------------------------
  alias _cao_setup_member setup
  def setup(actor_id)
    @required = false
    @unavailable = true
    _cao_setup_member(actor_id)
  end
end

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ○ 初期パーティのセットアップ
  #--------------------------------------------------------------------------
  def setup_starting_members
    for i in 1...$data_actors.size
      $game_actors[i].unavailable = true
    end
    @actors = []
    for i in $data_system.party_members
      @actors.push(i)
      $game_actors[i].unavailable = false
    end
  end
  #--------------------------------------------------------------------------
  # ○ アクターを加える
  #     actor_id : アクター ID
  #--------------------------------------------------------------------------
  def add_actor(actor_id)
    if @actors.size < MAX_MEMBERS and not @actors.include?(actor_id)
      @actors.push(actor_id)
      $game_actors[actor_id].unavailable = false
      $game_player.refresh
    end
  end
  #--------------------------------------------------------------------------
  # ◎ パーティを作り直す
  #     actor_id : アクター ID
  #--------------------------------------------------------------------------
  def reparty(actor_id)
    @actors.clear
    for i in actor_id
      @actors.push(i)
      $game_actors[i].unavailable = false
    end
    $game_player.refresh
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ◎ ラベルの処理
  #--------------------------------------------------------------------------
  alias _cao_command_118_party command_118
  def command_118
    case @params[0]
    when /^<パーティ編成>/
      $game_temp.next_scene = "party"
    when /^<全メンバ待機>/
      CAO::Commands.actor_all_member
    when /^<必須メンバクリア>/
      CAO::Commands.actor_all_required_nomember
    when /^<待機メンバクリア>/
      CAO::Commands.actor_all_nomember
    when /^>必須メンバ：\[\s*(\d+(?:\s*,\s*\d+)*)\s*\]([+-]?)/
      mode = $2
      ary = CAO::Commands.member_ary($1)
      CAO::Commands.required_member(ary, mode)
    when /^>待機メンバ：\[\s*(\d+(?:\s*,\s*\d+)*)\s*\]([+-]?)/
      mode = $2
      ary = CAO::Commands.member_ary($1)
      CAO::Commands.standby_unit(ary, mode)
    else
      return _cao_command_118_party
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ◎ 注釈の処理
  #--------------------------------------------------------------------------
  if $CAO_EX108I
  alias _cao_command_108_party command_108
  def command_108
    for params in @parameters
      case params
      when /^<パーティ編成>/
        $game_temp.next_scene = "party"
      when /^<全メンバ待機>/
        CAO::Commands.actor_all_member
      when /^<必須メンバクリア>/
        CAO::Commands.actor_all_required_nomember
      when /^<待機メンバクリア>/
        CAO::Commands.actor_all_nomember
      when /^>必須メンバ：\[\s*(\d+(?:\s*,\s*\d+)*)\s*\]([+-]?)/
        mode = $2
        ary = CAO::Commands.member_ary($1)
        CAO::Commands.required_member(ary, mode)
      when /^>待機メンバ：\[\s*(\d+(?:\s*,\s*\d+)*)\s*\]([+-]?)/
        mode = $2
        ary = CAO::Commands.member_ary($1)
        CAO::Commands.standby_unit(ary, mode)
      end
    end
    return _cao_command_108_party
  end
  end # if $CAO_EX108I
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_party_update_scene_change update_scene_change
  def update_scene_change
    return if $game_player.moving?    # プレイヤーの移動中？
    if $game_temp.next_scene == "party"
      $game_temp.next_scene = nil
      $scene = Scene_Member.new
    else
      _cao_party_update_scene_change
    end
  end
end

class Scene_Menu < Scene_Base
  #--------------------------------------------------------------------------
  # ◎ パーティ編成の開始
  #--------------------------------------------------------------------------
  def start_party_selection
    $scene = Scene_Member.new(@command_window.index)
  end
end

class Window_Member < Window_Selectable
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :dummy_party    # 編成中のパーティを一時的に保存
  attr_accessor :select_actor   # 現在選択されているアクター
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, 544, 136)
    @item_max = CAO_MEMBER::MAX_MEMBERS
    @column_max = CAO_MEMBER::MAX_MEMBERS
    @index = 0
    set_dummy_party
    refresh_info
    refresh
  end
  #--------------------------------------------------------------------------
  # ◎ 偽パーティを作成
  #--------------------------------------------------------------------------
  def set_dummy_party
    @dummy_party = []
    for i in 0...$game_party.members.size
      @dummy_party[i] = $game_party.members[i]
    end
    @item_max = $game_party.members.size
    if @item_max < CAO_MEMBER::MAX_MEMBERS
      @item_max = @dummy_party.size + 1
    else
      @item_max = CAO_MEMBER::MAX_MEMBERS
    end
    @select_actor = $game_party.members[0]
  end
  #--------------------------------------------------------------------------
  # ◎ 右文章のリフレッシュ
  #--------------------------------------------------------------------------
  def refresh_info
    wlh = 16
    self.contents.font.size = 14
    self.contents.font.color = system_color
    self.contents.draw_text(420, wlh * 0, 20, wlh, "R:")
    self.contents.draw_text(420, wlh * 1, 20, wlh, "L:")
    self.contents.draw_text(420, wlh * 2 + 4, 20, wlh, "X:")
    self.contents.draw_text(420, wlh * 3 + 4, 20, wlh, "Y:")
    self.contents.draw_text(420, wlh * 4 + 4, 20, wlh, "Z:")
    self.contents.draw_text(420, wlh * 5 + 8, 20, wlh, "A:")
    self.contents.font.color = normal_color
    self.contents.draw_text(440, wlh * 0, 76, wlh, "次のページ")
    self.contents.draw_text(440, wlh * 1, 76, wlh, "前のページ")
    self.contents.draw_text(440, wlh * 2 + 4, 76, wlh, "パラメータ")
    self.contents.draw_text(440, wlh * 3 + 4, 76, wlh, "装備品")
    self.contents.draw_text(440, wlh * 4 + 4, 76, wlh, "潜在能力")
    self.contents.draw_text(440, wlh * 5 + 8, 76, wlh, "パーティ脱退")
    self.contents.font.size = 20
  end
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    # 顔グラの部分のみ再描画
    self.contents.clear_rect(0, 0, 416, 104)
    for i in 0...@dummy_party.size
      actor = @dummy_party[i]
      draw_face(actor.face_name, actor.face_index, 104 * i + 4, 4)
      set_lock(i)   # ロック画像を描画
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 必須アクター
  #--------------------------------------------------------------------------
  def set_lock(num)
    if $game_actors[@dummy_party[num].id].required
      rect = Rect.new(0, 0, 16, 16)
      self.contents.blt(104 * num + 80, 84, Cache.system("Lock"), rect)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    @select_actor = @dummy_party[@index]
  end
  #--------------------------------------------------------------------------
  # ◎ パーティから外す
  #--------------------------------------------------------------------------
  def out_dummy_party
    if @dummy_party.size <= 1 || required?
      Sound.play_buzzer
    else
      Sound.play_decision
      @dummy_party[@index] = nil
      @dummy_party.compact!
      @index -= 1 if @index != 0
      @item_max -= 1
      if @item_max < CAO_MEMBER::MAX_MEMBERS
        @item_max = @dummy_party.size + 1
      else
        @item_max = CAO_MEMBER::MAX_MEMBERS
      end
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ◎ パーティを変更
  #--------------------------------------------------------------------------
  def in_dummy_party
    @dummy_party[@index] = @select_actor
    @index += 1 if @index < @column_max - 1
    if @item_max < CAO_MEMBER::MAX_MEMBERS
      @item_max = @dummy_party.size + 1
    else
      @item_max = CAO_MEMBER::MAX_MEMBERS
    end
    refresh
  end
  #--------------------------------------------------------------------------
  # ◎ 必須アクターか判別
  #--------------------------------------------------------------------------
  def required?
    return false if @dummy_party[@index] == nil
    return $game_actors[@dummy_party[@index].id].required
  end
  #--------------------------------------------------------------------------
  # ◎ 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new(0, 0, 104, 104)
    rect.x = 104 * index
    return rect
  end
end

class Window_MemberSelect < Window_Selectable
  include CAO_MEMBER
  #--------------------------------------------------------------------------
  # ◎ 定数
  #--------------------------------------------------------------------------
  WLH = CHARACTER_HEIGHT + 8
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :dummy_party
  attr_accessor :select_actor
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 136, 192, 280)
    @column_max = [MAX_COLUMN, (160 / CHARACTER_WIDTH)].min
    @index = -1
    @dummy_party = []
  end
  #--------------------------------------------------------------------------
  # ● 待機メンバーの収得
  #--------------------------------------------------------------------------
  def actor_await
    @game_actors = [] ; c = 0
    # キャラを順番に見る
    for i in 1...$data_actors.size
      for ii in 0...@dummy_party.size
        out_party = false
        # パーティのキャラは除外
        if $game_actors[i].id == @dummy_party[ii].id
          out_party = true
          break
        end
      end
      # アクターが登録可能で除外されていない
      if !$game_actors[i].unavailable && !out_party
        @game_actors[c] = $game_actors[i]
        c += 1
      end
    end
    # セレクト数
    @item_max = @game_actors.size
    create_contents
  end
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    actor_await
    for i in 0...@game_actors.size
      chara_name = @game_actors[i].character_name
      chara_index = @game_actors[i].character_index
      cw = self.contents.width / @column_max
      x = i % @column_max * cw + cw / 2
      y = i / @column_max * WLH + WLH
      draw_character(chara_name, chara_index, x, y)
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
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, ch)
    src_rect.width = [src_rect.width, CHARACTER_WIDTH].min
    src_rect.height = [src_rect.height, CHARACTER_HEIGHT].min
    src_rect.x += (cw - src_rect.width) / 2
    x -= src_rect.width / 2
    y -= src_rect.height
    self.contents.blt(x, y, bitmap, src_rect)
  end
  #--------------------------------------------------------------------------
  # ◎ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    @select_actor = @game_actors[@index] if @index >= 0
  end
  #--------------------------------------------------------------------------
  # ◎ ウィンドウ内容の作成
  #--------------------------------------------------------------------------
  def create_contents
    self.contents.dispose
    self.contents = Bitmap.new(160, [248, row_max * WLH].max)
  end
  #--------------------------------------------------------------------------
  # ◎ 行数の取得
  #--------------------------------------------------------------------------
  def row_max
    return (@item_max + @column_max - 1) / @column_max
  end
  #--------------------------------------------------------------------------
  # ◎ 先頭の行の取得
  #--------------------------------------------------------------------------
  def top_row
    return self.oy / WLH
  end
  #--------------------------------------------------------------------------
  # ◎ 先頭の行の設定
  #     row : 先頭に表示する行
  #--------------------------------------------------------------------------
  def top_row=(row)
    row = 0 if row < 0
    row = row_max - 1 if row > row_max - 1
    self.oy = row * WLH
  end
  #--------------------------------------------------------------------------
  # ◎ 1 ページに表示できる行数の取得
  #--------------------------------------------------------------------------
  def page_row_max
    return (self.height - 32) / WLH
  end
  #--------------------------------------------------------------------------
  # ◎ 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new(0, 0, 0, 0)
    rect.width = contents.width / @column_max
    rect.height = WLH
    rect.x = index % @column_max * rect.width
    rect.y = index / @column_max * WLH + 4
    return rect
  end
end

class Window_MemberStatus < Window_Selectable
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :select_actor
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(192, 136, 352, 280)
    @select_actor = 0
    @actor = 0
    @page = 0
  end
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    if @select_actor != nil
      draw_basic_info
      update_options
    end
  end
  #--------------------------------------------------------------------------
  # ◎ ステータスの更新
  #--------------------------------------------------------------------------
  def update_options
    self.contents.clear_rect(0, 120, 352, 248)
    if @select_actor != nil
      case @page
      when 0  # パラメータ
        draw_parameters(40, 120)
      when 1  # 装備
        draw_equipments(0, 140)
      when 2  # 潜在能力
        draw_options(0, 140)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if @select_actor != @actor
      refresh
      @actor = @select_actor
    end
    update_selection
  end
  #--------------------------------------------------------------------------
  # ◎ 下ステータスの更新
  #--------------------------------------------------------------------------
  def update_selection
    page_num = @page
    @page = 0 if Input.trigger?(Input::X)
    @page = 1 if Input.trigger?(Input::Y)
    @page = 2 if Input.trigger?(Input::Z)
    # ページが変わっていれば
    if page_num != @page
      Sound.play_page
      update_options
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 基本情報の描画
  #--------------------------------------------------------------------------
  def draw_basic_info
      draw_actor_name(@select_actor, 0, 0)
      draw_actor_face(@select_actor, 2, WLH)
      draw_actor_level(@select_actor, 120, 0)
      draw_actor_class(@select_actor, 210, 0)
      draw_actor_hp(@select_actor, 120, WLH * 1, 180)
      draw_actor_mp(@select_actor, 120, WLH * 2, 180)
      draw_actor_state(@select_actor, 120, WLH * 3)
      draw_actor_exp(@select_actor, 120, WLH * 4, 180)
  end
  #--------------------------------------------------------------------------
  # ◎ 能力値の描画
  #     x : 描画先 X 座標
  #     y : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_parameters(x, y)
    draw_actor_parameter(@select_actor, x, y + WLH * 1, 0)
    draw_actor_parameter(@select_actor, x, y + WLH * 2, 1)
    draw_actor_parameter(@select_actor, x, y + WLH * 3, 2)
    draw_actor_parameter(@select_actor, x, y + WLH * 4, 3)
  end
  #--------------------------------------------------------------------------
  # ◎ 能力値の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     type  : 能力値の種類 (0〜3)
  #--------------------------------------------------------------------------
  def draw_actor_parameter(actor, x, y, type)
    case type
    when 0  # 攻撃力
      parameter_name = Vocab::atk
      parameter_base = $data_actors[actor.id].parameters[2, actor.level]
      parameter_value = actor.atk
    when 1  # 防御力
      parameter_name = Vocab::def
      parameter_base = $data_actors[actor.id].parameters[3, actor.level]
      parameter_value = actor.def
    when 2  # 精神力
      parameter_name = Vocab::spi
      parameter_base = $data_actors[actor.id].parameters[4, actor.level]
      parameter_value = actor.spi
    when 3  # 俊敏性
      parameter_name = Vocab::agi
      parameter_base = $data_actors[actor.id].parameters[5, actor.level]
      parameter_value = actor.agi
    end
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 120, WLH, parameter_name)
    self.contents.font.color = normal_color
    self.contents.draw_text(x + 120, y, 36, WLH, parameter_value, 2)
    self.contents.draw_text(x + 168, y, 50, WLH, "(   )", 1)
    self.contents.draw_text(x + 168, y, 50, WLH, parameter_base, 1)
  end
  #--------------------------------------------------------------------------
  # ◎ 装備品の描画
  #     x : 描画先 X 座標
  #     y : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_equipments(x, y)
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 120, WLH, Vocab::equip)
    draw_item_name(@select_actor.equips[0], x, y + WLH * 1)
    draw_item_name(@select_actor.equips[1], x + 160, y + WLH * 1)
    draw_item_name(@select_actor.equips[2], x, y + WLH * 2)
    draw_item_name(@select_actor.equips[3], x + 160, y + WLH * 2)
    draw_item_name(@select_actor.equips[4], x, y + WLH * 3)
  end
  #--------------------------------------------------------------------------
  # ◎ アイテム名の描画
  #     item    : アイテム (スキル、武器、防具でも可)
  #     x       : 描画先 X 座標
  #     y       : 描画先 Y 座標
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item_name(item, x, y, enabled = true)
    if item != nil
      draw_icon(item.icon_index, x, y, enabled)
      self.contents.font.color = normal_color
      self.contents.font.color.alpha = enabled ? 255 : 100
      self.contents.draw_text(x + 24, y, 136, WLH, item.name)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 潜在能力の描画
  #     x : 描画先 X 座標
  #     y : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_options(x, y)
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 120, WLH, CAO_MEMBER::POTENTIAL_NAME_0)
    # 潜在能力の配列
    s1 = @select_actor.auto_battle                      # 自動戦闘
    s2 = @select_actor.fix_equipment                    # 装備固定
    s3 = @select_actor.two_swords_style                 # 二刀流
    s4 = @select_actor.super_guard                      # 強力防御
    s5 = @select_actor.pharmacology                     # 薬の知識
    s6 = $data_actors[@select_actor.id].critical_bonus  # クリティカル
    op = [s1, s2, s3, s4, s5, s6]
    # 潜在能力の名前配列
    p1 = CAO_MEMBER::POTENTIAL_NAME_1  # 自動戦闘
    p2 = CAO_MEMBER::POTENTIAL_NAME_2  # 装備固定
    p3 = CAO_MEMBER::POTENTIAL_NAME_3  # 二刀流
    p4 = CAO_MEMBER::POTENTIAL_NAME_4  # 強力防御
    p5 = CAO_MEMBER::POTENTIAL_NAME_5  # 薬の知識
    p6 = CAO_MEMBER::POTENTIAL_NAME_6  # クリティカル
    text = [p1, p2, p3, p4, p5, p6]
    for i in 0...op.size
      self.contents.font.color = normal_color
      self.contents.font.color.alpha = op[i] ? 255 : 128
      self.contents.draw_text(i%2*160, y + WLH * (i/2+1), 160, WLH, text[i], 1)
    end
  end
end

class Window_MemberMessage < Window_Selectable
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :index    # 現在のカーソル位置
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #     text  : 項目名の配列
  #--------------------------------------------------------------------------
  def initialize(text)
    height = WLH * text.size + 32
    super(184, (416 - height) / 2, 176, height)
    @text = text
    @item_max = @text.size
    self.openness = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ◎ ウィンドウを開く
  #--------------------------------------------------------------------------
  def move_window
    @index = 0
    self.visible = true
    if self.openness == 0
      while self.openness != 255
        self.openness += 25
        Graphics.update
      end
    elsif self.openness == 255
      while self.openness != 0
        self.openness -= 25
        Graphics.update
      end
      self.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ◎ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.font.color = normal_color
    for i in 0...@item_max
      self.contents.draw_text(0, WLH * i, 144, WLH, @text[i], 1)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
  end
end

class Scene_Member < Scene_Base
  #--------------------------------------------------------------------------
  # ◎ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(from = -1)
    @from = from
  end
  #--------------------------------------------------------------------------
  # ◎ 開始処理
  #--------------------------------------------------------------------------
  def start
    create_menu_background
    @member_window = Window_Member.new
    @select_window = Window_MemberSelect.new
    @select_window.dummy_party = @member_window.dummy_party
    @select_window.refresh
    @select_window.active = false
    @status_window = Window_MemberStatus.new
    @message_window = Window_MemberMessage.new(CAO_MEMBER::COMMAND_TEXT)
    @message_window.visible = false
  end
  #--------------------------------------------------------------------------
  # ◎ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    dispose_menu_background
    @member_window.dispose
    @select_window.dispose
    @status_window.dispose
    @message_window.dispose
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
    if @member_window.active
      @member_window.update
      @status_window.select_actor = @member_window.select_actor
    elsif @select_window.active
      @select_window.update
      @status_window.select_actor = @select_window.select_actor
    end
    @message_window.visible ? close_window : update_selection
    @status_window.update
  end
  #--------------------------------------------------------------------------
  # ◎ 更新
  #--------------------------------------------------------------------------
  def update_selection
    # メンバーウィンドウ
    if @member_window.active
      if Input.trigger?(Input::B)
        Sound.play_cancel
        @member_window.active = false
        @status_window.active = false
        @message_window.move_window
      elsif Input.trigger?(Input::C)
        if @member_window.required?
          Sound.play_buzzer
        else
          Sound.play_decision
          @member_window.active = false
          @select_window.active = true
          @select_window.index = 0
        end
      elsif Input.trigger?(Input::A)
        @member_window.out_dummy_party
        @select_window.refresh
      end
    # セレクトウィンドウ
    elsif @select_window.active
      if Input.trigger?(Input::B)
        Sound.play_cancel
        @select_window.active = false
        @member_window.active = true
        @select_window.index = -1
      elsif Input.trigger?(Input::C)
        if @select_window.select_actor == nil
          Sound.play_buzzer
        else
          @member_window.select_actor = @select_window.select_actor
          @member_window.in_dummy_party
          @select_window.refresh
          @select_window.active = false
          @member_window.active = true
          @select_window.index = -1
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 確認画面
  #--------------------------------------------------------------------------
  def close_window
    if Input.trigger?(Input::B)
        @message_window.move_window
        @member_window.active = true
        @status_window.active = true
    elsif Input.trigger?(Input::C)
      case @message_window.index
      when 0
        party_member_dexision
        return_scene
      when 1
        @member_window.set_dummy_party
        @message_window.move_window
        @member_window.index = 0
        @member_window.refresh
        @select_window.dummy_party = @member_window.dummy_party
        @select_window.refresh
        @member_window.active = true
        @status_window.active = true
      when 2
        return_scene
      end
    end
    @message_window.update
  end
  #--------------------------------------------------------------------------
  # ◎ パーティメンバーを決定
  #--------------------------------------------------------------------------
  def party_member_dexision
    party = []
    for i in 0...@member_window.dummy_party.size
      party[i] = @member_window.dummy_party[i].id
    end
    $game_party.reparty(party)
  end
end
