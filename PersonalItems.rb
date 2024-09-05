#=============================================================================
#  [RGSS2] アイテム個別所持 - v1.1.0
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

  アクター毎の持ち物を追加します。
  アクターの所持できるものは、アイテムのみとなります。
  戦闘中には、共有アイテムは使用できなくなります。

 -- 操作方法 ----------------------------------------------------------------

  ★ アクターの切り替え
   Ｌボタン or Ｒボタン (デフォルト)
   ※ デフォルトの設定では、ページ送り機能は使用できなくなります。

 -- 使用方法 ----------------------------------------------------------------

  ★ アイテムの追加
   アイテムの追加自体は、今まで通りのイベントコマンドでできます。
   ※ アイテムの追加をする場合、必ず追加先を設定する必要があります。

  ★ アイテムの追加先指定
   イベントコマンド「ラベル」に以下の文字を入れることで、設定できます。
     "共有に追加" ： "パーティに追加：n" ： "アクターに追加：n"

  ★ 捨てられないアイテムの設定
   データベースのメモ欄に <キーアイテム> と記述してください。

  ★ アクターが持てる各アイテムの最大数の設定
   データベースのメモ欄に <最大所持数:n> と記述してください。
   ※ n は、半角数字で最大値を設定してください。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO; module INDI
  
  #--------------------------------------------------------------------------
  # ◇ アイテムの追加先指定のＥＶ変数のＩＤ
  #--------------------------------------------------------------------------
  VAR_MEMBER_ID = 12    # パーティの何番目
  VAR_ACTOR_ID = 13     # 何番のアクター
  
  #--------------------------------------------------------------------------
  # ◇ 共有アイテムの設定
  #--------------------------------------------------------------------------
  COMMON_ITEM_NAME = "共有所持品"   # 名称
  COMMON_ITEM_ICON = 144            # アイコン
  
  #--------------------------------------------------------------------------
  # ◇ 歩行グラの表示幅
  #--------------------------------------------------------------------------
  SELECTING_ACTOR_WIDTH = 64
  
  #--------------------------------------------------------------------------
  # ◇ アイテムを捨てた際の効果音（ファイル名, ピッチ）
  #--------------------------------------------------------------------------
  SOUND_DISCARD = ["Jump2", 100]
  
  #--------------------------------------------------------------------------
  # ◇ アクターのアイテム最大所持数（種類）
  #--------------------------------------------------------------------------
  MAX_ITEM = 10
  
  #--------------------------------------------------------------------------
  # ◇ アクターの各アイテム最大所持数 (設定省略時)
  #--------------------------------------------------------------------------
  #     アイテムの最大数をメモ欄で設定しなかった場合に使用されます。
  #--------------------------------------------------------------------------
  DEFAULT_MAXIMUM = 99
  
  #--------------------------------------------------------------------------
  # ◇ キーアイテムを渡すことができるか
  #--------------------------------------------------------------------------
  #     true .. 渡せる : false .. 渡せない
  #--------------------------------------------------------------------------
  KEYITEM_PASS = false
  
  #--------------------------------------------------------------------------
  # ◇ アクター切り替えを行うキー設定
  #--------------------------------------------------------------------------
  #     0 .. (L or R) : 1 .. (A + L or A + R) : 2 .. (A + ← or A + →)
  #--------------------------------------------------------------------------
#~   KEY_ACTOR = 0
  
  #--------------------------------------------------------------------------
  # ◇ 前面の画像
  #--------------------------------------------------------------------------
  #     画像は、"Graphics/Pictures" フォルダ : 使用しない場合は、nil
  #--------------------------------------------------------------------------
#~   FRONT_IMAGE = nil  # [x, y, "ファイル名"]
  
end; end # module CAO; module INDI


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module KeyItem
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  REGEXP_KEYITEM = /^<キーアイテム>/
  REGEXP_MAXIMUM = /^<最大所持数:(\d+)>/
  #--------------------------------------------------------------------------
  # ● アクターの最大所持数
  #--------------------------------------------------------------------------
  def maximum
    @maximum ||= (@note[REGEXP_MAXIMUM,1] || CAO::INDI::DEFAULT_MAXIMUM).to_i
    return @maximum
  end
  #--------------------------------------------------------------------------
  # ● キーアイテムか判定
  #--------------------------------------------------------------------------
  def keyitem?
    return @keyitem ||= @note.match(REGEXP_KEYITEM)
  end
  #--------------------------------------------------------------------------
  # ● 渡せるアイテムか判定
  #--------------------------------------------------------------------------
  def can_pass?
    return (!keyitem? || CAO::INDI::KEYITEM_PASS)
  end
end

module RPG
  class Item;   include KeyItem; end
  class Weapon; include KeyItem; end
  class Armor;  include KeyItem; end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #     actor_id : アクター ID
  #--------------------------------------------------------------------------
  alias _cao_setup_indi setup
  def setup(actor_id)
    @items = {}       # 所持品ハッシュ (アイテム ID)
    _cao_setup_indi(actor_id)
  end
  #--------------------------------------------------------------------------
  # ● アイテムオブジェクトの配列取得
  #--------------------------------------------------------------------------
  def items
    result = []
    for i in @items.keys.sort
      result.push($data_items[i]) if @items[i] > 0
    end
    return result
  end
  #--------------------------------------------------------------------------
  # ● アイテムの増加
  #     item          : アイテム
  #     n             : 個数
  #--------------------------------------------------------------------------
  def gain_item(item, n)
    return unless item.is_a?(RPG::Item)
    number = item_number(item)
    @items[item.id] = [[number + n, 0].max, 99].min
  end
  #--------------------------------------------------------------------------
  # ● アイテムの減少
  #     item          : アイテム
  #     n             : 個数
  #--------------------------------------------------------------------------
  def lose_item(item, n)
    return unless item.is_a?(RPG::Item)
    number = item_number(item)
    @items[item.id] = [[number - n, 0].max, 99].min
  end
  #--------------------------------------------------------------------------
  # ● アイテムの消耗
  #     item : アイテム
  #    指定されたオブジェクトが消耗アイテムであれば、所持数を 1 減らす。
  #--------------------------------------------------------------------------
  def consume_item(item)
    lose_item(item, 1) if item.is_a?(RPG::Item) and item.consumable
  end
  #--------------------------------------------------------------------------
  # ● アイテムの所持数取得
  #     item : アイテム
  #--------------------------------------------------------------------------
  def item_number(item)
    return @items[item.id] == nil ? 0 : @items[item.id]
  end
  #--------------------------------------------------------------------------
  # ● アイテムの所持種類数取得
  #     item : アイテム
  #--------------------------------------------------------------------------
  def item_kind_number
    count = 0
    @items.each_value { |val| count += 1 if val > 0 }
    return count
  end
  #--------------------------------------------------------------------------
  # ● アイテムの所持種類数が最大か判定
  #     item : アイテム
  #--------------------------------------------------------------------------
  def item_kind_fullness?
    return item_kind_number >= CAO::INDI::MAX_ITEM
  end
  #--------------------------------------------------------------------------
  # ● アイテムの使用可能判定
  #     item : アイテム
  #--------------------------------------------------------------------------
  def item_can_use?(item)
    return false unless item.is_a?(RPG::Item)
    return false if item_number(item) == 0
    if $game_temp.in_battle
      return item.battle_ok?
    else
      return item.menu_ok?
    end
  end
  #--------------------------------------------------------------------------
  # ● アイテムの所持可能判定
  #     item : アイテム
  #--------------------------------------------------------------------------
  def item_can_have?(item)
    return false unless item.is_a?(RPG::Item)
    return false if item_number(item) == 0 && item_kind_fullness?
    return false unless item_number(item) < item.maximum
    return true
  end
end

class Game_Party
  #--------------------------------------------------------------------------
  # ● アイテムの所持可能判定
  #     item : アイテム
  #--------------------------------------------------------------------------
  def item_can_have?(item)
    return item_number(item) < 99
  end
end

class Game_BattleAction
  #--------------------------------------------------------------------------
  # ○ 行動が有効か否かの判定
  #    イベントコマンドによる [戦闘行動の強制] ではないとき、ステートの制限
  #    やアイテム切れなどで予定の行動ができなければ false を返す。
  #--------------------------------------------------------------------------
  def valid?
    return false if nothing?                      # 何もしない
    return true if @forcing                       # 行動強制中
    return false unless battler.movable?          # 行動不能
    if skill?                                     # スキル
      return false unless battler.skill_can_use?(skill)
    elsif item?                                   # アイテム
      return false unless battler.item_can_use?(item)
    end
    return true
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_indi command_118
  def command_118
    case @params[0]
    when /^共有に追加/
      $game_variables[CAO::INDI::VAR_MEMBER_ID] = 0
      $game_variables[CAO::INDI::VAR_ACTOR_ID] = 0
    when /^パーティに追加：(\d+)/
      $game_variables[CAO::INDI::VAR_MEMBER_ID] = $1.to_i
      $game_variables[CAO::INDI::VAR_ACTOR_ID] = 0
    when /^アクターに追加：(\d+)/
      $game_variables[CAO::INDI::VAR_MEMBER_ID] = 0
      $game_variables[CAO::INDI::VAR_ACTOR_ID] = $1.to_i
    else
      return _cao_command_118_indi
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ○ アイテムの増減
  #--------------------------------------------------------------------------
  def command_126
    member_id = $game_variables[CAO::INDI::VAR_MEMBER_ID]
    if member_id == 0
      actor_id = $game_variables[CAO::INDI::VAR_ACTOR_ID]
      target = actor_id == 0 ? $game_party : $game_actors[actor_id]
    else
      target = $game_party.members[member_id - 1]
    end
    item = $data_items[@params[0]]
    if target.is_a?(Game_Actor) && !target.item_can_have?(item)
      return true
    end
    target.gain_item(item, operate_value(@params[1], @params[2], @params[3]))
    $game_map.need_refresh = true
    return true
  end
end

class Window_Item < Window_Selectable
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     x      : ウィンドウの X 座標
  #     y      : ウィンドウの Y 座標
  #     width  : ウィンドウの幅
  #     height : ウィンドウの高さ
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height, actor_id = nil)
    super(x, y, width, height)
    @target = actor_id ? $game_actors[actor_id] : $game_party
    @column_max = 2
    self.index = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @data = []
    for item in @target.items
      next unless include?(item)
      @data.push(item)
    end
    @data.push(nil) if include?(nil)
    @item_max = @data.size
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ○ アイテムを許可状態で表示するかどうか
  #     item : アイテム
  #--------------------------------------------------------------------------
  def enable?(item)
    return @target.item_can_use?(item)
  end
  #--------------------------------------------------------------------------
  # ○ 項目の描画
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    item = @data[index]
    if item != nil
      number = @target.item_number(item)
      enabled = enable?(item)
      rect.width -= 4
      draw_item_name(item, rect.x, rect.y, enabled)
      self.contents.draw_text(rect, sprintf(":%2d", number), 2)
    end
  end
end

class Window_ItemPass < Window_Selectable
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    item_max = $game_party.members.size + 1
    height = WLH * item_max + 32
    super(186, (416 - height) / 2, 172, height)
    @item_max = item_max
    refresh
    self.index = 0
    self.openness = 0
    self.active = false
    self.z = 105
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
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item(index, enabled = true)
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    self.contents.clear_rect(rect)
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = enabled ? 255 : 128
    if index == 0
      self.contents.draw_text(rect, CAO::INDI::COMMON_ITEM_NAME, 1)
    else
      self.contents.draw_text(rect, $game_party.members[index - 1].name, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ開閉中
  #--------------------------------------------------------------------------
  def move?
    return (@opening || @closing)
  end
end

class Window_ItemCommand < Window_Selectable
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(202, 156, 140, 104)
    @commands = ["つかう", "わたす", "すてる"]
    @item_max = 3
    refresh
    self.index = 0
    self.openness = 0
    self.active = false
    self.z = 105
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
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item(index, enabled = true)
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    self.contents.clear_rect(rect)
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = enabled ? 255 : 128
    self.contents.draw_text(rect, @commands[index], 1)
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ開閉中
  #--------------------------------------------------------------------------
  def move?
    return (@opening || @closing)
  end
end

class Window_ItemActorName < Window_Base
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :index                    # 
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 56, 544, 64)
    @index = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = normal_color
    cw = CAO::INDI::SELECTING_ACTOR_WIDTH
    draw_icon(CAO::INDI::COMMON_ITEM_ICON, (cw-24)/2, 4, @index == 0)
    if @index == 0
      self.contents.draw_text(312, 0, 200, 32,
                              CAO::INDI::COMMON_ITEM_NAME, 1)
    end
    for actor in $game_party.members
      index = actor.index + 1
      enabled = (@index == index)
      draw_actor_graphic(actor, index * cw + cw / 2, 0, enabled)
      self.contents.font.color.alpha = enabled ? 255 : 128
      self.contents.draw_text(312, 0, 200, 32, actor.name, 1) if enabled
    end
  end
  #--------------------------------------------------------------------------
  # ● アクターの歩行グラフィック描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_graphic(actor, x, y, enabled = false)
    draw_character(actor.character_name, actor.character_index, x, y, enabled)
  end
  #--------------------------------------------------------------------------
  # ● 歩行グラフィックの描画
  #     character_name  : 歩行グラフィック ファイル名
  #     character_index : 歩行グラフィック インデックス
  #     x               : 描画先 X 座標
  #     y               : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_character(character_name, character_index, x, y, enabled)
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
    self.contents.blt(x - cw / 2, y, bitmap, src_rect, enabled ? 255 : 128)
  end
  #--------------------------------------------------------------------------
  # ● 次のアクターの画面に切り替え
  #--------------------------------------------------------------------------
  def id
    return nil if @index == 0
    return $game_party.members[@index - 1].id
  end
  #--------------------------------------------------------------------------
  # ● 次のアクターの画面に切り替え
  #--------------------------------------------------------------------------
  def next_actor
    @index += 1
    @index %= $game_party.members.size + 1
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 前のアクターの画面に切り替え
  #--------------------------------------------------------------------------
  def prev_actor
    @index -= 1
    @index %= $game_party.members.size + 1
    refresh
  end
end

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ○ アイテム選択の開始
  #--------------------------------------------------------------------------
  def start_item_selection
    @help_window = Window_Help.new
    @item_window = Window_Item.new(0, 56, 544, 232, @active_battler.id)
    @item_window.help_window = @help_window
    @actor_command_window.active = false
  end
  #--------------------------------------------------------------------------
  # ○ アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_item_selection
    @item_window.active = true
    @item_window.update
    @help_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      end_item_selection
    elsif Input.trigger?(Input::C)
      @item = @item_window.item
      if @active_battler.item_can_use?(@item)
        Sound.play_decision
        determine_item
      else
        Sound.play_buzzer
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 戦闘行動の実行 : アイテム
  #--------------------------------------------------------------------------
  def execute_action_item
    item = @active_battler.action.item
    text = sprintf(Vocab::UseItem, @active_battler.name, item.name)
    @message_window.add_instant_text(text)
    targets = @active_battler.action.make_targets
    display_animation(targets, item.animation_id)
    @active_battler.consume_item(item)
    $game_temp.common_event_id = item.common_event_id
    for target in targets
      target.item_effect(@active_battler, item)
      display_action_effects(target, item)
    end
  end
end

if CAO::INDI::KEY_ACTOR < 3
class Window_Item < Window_Selectable
  #--------------------------------------------------------------------------
  # ○ カーソルを 1 ページ後ろに移動
  #--------------------------------------------------------------------------
  def cursor_pagedown
    super if !Input.press?(Input::A) && CAO::INDI::KEY_ACTOR != 0
  end
  #--------------------------------------------------------------------------
  # ○ カーソルを 1 ページ前に移動
  #--------------------------------------------------------------------------
  def cursor_pageup
    super if !Input.press?(Input::A) && CAO::INDI::KEY_ACTOR != 0
  end
end
end # if CAO::INDI::KEY_ACTOR == 0

class Scene_Item < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    @viewport = Viewport.new(0, 0, 544, 416)
    @help_window = Window_Help.new
    @help_window.viewport = @viewport
    @actor_window = Window_ItemActorName.new
    create_item_window
    @command_window = Window_ItemCommand.new
    @command_window.z = 110
    @pass_window = Window_ItemPass.new
    @pass_window.z = 110
    @target_window = Window_MenuStatus.new(0, 0)
    @target_window.z = 110
    hide_target_window
    create_front_image
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    dispose_front_image
    @viewport.dispose
    @help_window.dispose
    @item_window.dispose
    @command_window.dispose
    @pass_window.dispose
    @actor_window.dispose
    @target_window.dispose
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    @help_window.update
    @item_window.update
    @command_window.update
    @pass_window.update
    @target_window.update
    if @item_window.active
      update_item_selection
    elsif @command_window.active
      update_command_selection
    elsif @pass_window.active
      update_pass_selection
    elsif @target_window.active
      update_target_selection
    end
  end
  #--------------------------------------------------------------------------
  # ● アイテムウィンドウの生成
  #--------------------------------------------------------------------------
  def create_item_window(actor_id = nil)
    @item_window = Window_Item.new(0, 120, 544, 296, actor_id)
    @item_window.viewport = @viewport
    @item_window.help_window = @help_window
  end
  #--------------------------------------------------------------------------
  # ● 前面に表示する画像を生成
  #--------------------------------------------------------------------------
  def create_front_image
    if CAO::INDI::FRONT_IMAGE
      @help_sprite = Sprite.new
      @help_sprite.x = CAO::INDI::FRONT_IMAGE[0]
      @help_sprite.y = CAO::INDI::FRONT_IMAGE[1]
      @help_sprite.z = 105
      @help_sprite.bitmap = Cache.picture(CAO::INDI::FRONT_IMAGE[2])
    end
  end
  #--------------------------------------------------------------------------
  # ● 前面に表示する画像を解放
  #--------------------------------------------------------------------------
  def dispose_front_image
    @help_sprite.dispose if CAO::INDI::FRONT_IMAGE
  end
  #--------------------------------------------------------------------------
  # ○ アイテム選択の更新
  #--------------------------------------------------------------------------
  def update_item_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene
    elsif Input.trigger?(Input::C)
      # インスタンス変数に選択アイテムを代入
      unless @item = @item_window.item
        Sound.play_buzzer
        return
      end
      # 操作対象を決定
      if @actor_window.index == 0
        @doer = $game_party
      else
        @doer = $game_party.members[@actor_window.index - 1]
      end
      @item_window.active = false
      @command_window.index = 0
      @command_window.active = true
      @command_window.open
      @command_window.refresh
      unless @doer.item_can_use?(@item)
        @command_window.draw_item(0, false)
      end
      unless @item.is_a?(RPG::Item) && @item.can_pass?
        @command_window.draw_item(1, false)
      end
      if @item.keyitem?
        @command_window.draw_item(2, false)
      end
    end
    update_actor_selection
  end
  #--------------------------------------------------------------------------
  # ● アクター切り替えの更新
  #--------------------------------------------------------------------------
  def update_actor_selection
    case CAO::INDI::KEY_ACTOR
    when 0
      if Input.trigger?(Input::L)
        next_actor
      elsif Input.trigger?(Input::R)
        prev_actor
      end
    when 1
      if Input.press?(Input::A)
        if Input.trigger?(Input::L)
          next_actor
        elsif Input.trigger?(Input::R)
          prev_actor
        end
      end
    when 2
      if Input.press?(Input::A)
        if Input.trigger?(Input::LEFT)
          next_actor
        elsif Input.trigger?(Input::RIGHT)
          prev_actor
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 次のアクター
  #--------------------------------------------------------------------------
  def next_actor
    Sound.play_decision
    @actor_window.prev_actor
    @item_window.dispose
    create_item_window(@actor_window.id)
  end
  #--------------------------------------------------------------------------
  # ● 前のアクター
  #--------------------------------------------------------------------------
  def prev_actor
    Sound.play_decision
    @actor_window.next_actor
    @item_window.dispose
    create_item_window(@actor_window.id)
  end
  #--------------------------------------------------------------------------
  # ● 選択メニュー非表示
  #--------------------------------------------------------------------------
  def hide_command_window
    @command_window.active = false
    @command_window.close
    while @command_window.move?
      @command_window.update
      Graphics.update
    end
  end
  #--------------------------------------------------------------------------
  # ● 選択メニューの更新
  #--------------------------------------------------------------------------
  def update_command_selection
    if Input.trigger?(Input::B)
      @item_window.active = true
      @command_window.active = false
      @command_window.close
    elsif Input.trigger?(Input::C)
      case @command_window.index
      when 0  # つかう
        if @item.is_a?(RPG::Item) && @doer.item_can_use?(@item)
          hide_command_window
          Sound.play_decision
          determine_item
        else
          Sound.play_buzzer
        end
      when 1  # わたす
        if @item.is_a?(RPG::Item) && @item.can_pass?
          hide_command_window
          Sound.play_decision
          @pass_window.active = true
          @pass_window.open
          @pass_window.index = (@actor_window.index == 0 ? 1 : 0)
          @pass_window.refresh
          @pass_window.draw_item(@actor_window.index, false)
          for actor in $game_party.members
            unless actor.item_can_have?(@item)
              @pass_window.draw_item(actor.index + 1, false)
            end
          end
        else
          Sound.play_buzzer
        end
      when 2  # すてる
        if @item.keyitem?
          Sound.play_buzzer
        else
          file = CAO::INDI::SOUND_DISCARD[0]
          pitch = CAO::INDI::SOUND_DISCARD[1]
          Audio.se_play("Audio/SE/" + file, 80, pitch)
          @doer.lose_item(@item, 1)
          if @doer.item_number(@item) == 0  # アイテムを使い切った場合
            @item_window.refresh            # ウィンドウの内容を再作成
          else
            @item_window.draw_item(@item_window.index)
          end
          @item_window.active = true
          @command_window.active = false
          @command_window.close
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ アイテムの決定
  #--------------------------------------------------------------------------
  def determine_item
    if @item.for_friend?
      show_target_window(@item_window.index % 2 == 0)
      if @command_window.index == 0 && @item.for_all?
        @target_window.index = 99
      else
        if $game_party.last_target_index < @target_window.item_max
          @target_window.index = $game_party.last_target_index
        else
          @target_window.index = 0
        end
      end
    else
      use_item_nontarget
    end
  end
  #--------------------------------------------------------------------------
  # ○ ターゲット選択の更新（使う）
  #--------------------------------------------------------------------------
  def update_target_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      if @doer.item_number(@item) == 0    # アイテムを使い切った場合
        @item_window.refresh                # ウィンドウの内容を再作成
      end
      hide_target_window
    elsif Input.trigger?(Input::C)
      if @doer.item_can_use?(@item)
        determine_target
      else
        Sound.play_buzzer
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ ターゲットの決定（使う）
  #    効果なしの場合 (戦闘不能にポーションなど) ブザー SE を演奏。
  #--------------------------------------------------------------------------
  def determine_target
    used = false
    if @item.for_all?
      for target in $game_party.members
        target.item_effect(target, @item)
        used = true unless target.skipped
      end
    else
      $game_party.last_target_index = @target_window.index
      target = $game_party.members[@target_window.index]
      target.item_effect(target, @item)
      used = true unless target.skipped
    end
    if used
      use_item_nontarget
    else
      Sound.play_buzzer
    end
  end
  #--------------------------------------------------------------------------
  # ○ アイテムの使用 (味方対象以外の使用効果を適用)
  #--------------------------------------------------------------------------
  def use_item_nontarget
    Sound.play_use_item
    @doer.consume_item(@item)
    @item_window.draw_item(@item_window.index)
    @target_window.refresh
    if $game_party.all_dead?
      $scene = Scene_Gameover.new
    elsif @item.common_event_id > 0
      $game_temp.common_event_id = @item.common_event_id
      $scene = Scene_Map.new
    end
  end
  #--------------------------------------------------------------------------
  # ● ターゲット選択の更新（渡す）
  #--------------------------------------------------------------------------
  def update_pass_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @item_window.refresh if @doer.item_number(@item) == 0
      @item_window.active = true
      @pass_window.active = false
      @pass_window.close
    elsif Input.trigger?(Input::C)
      determine_pass
    end
  end
  #--------------------------------------------------------------------------
  # ● ターゲットの決定（渡す）
  #--------------------------------------------------------------------------
  def determine_pass
    # 受け取る人の設定
    if @pass_window.index == 0
      excipient = $game_party
    else
      excipient = $game_party.members[@pass_window.index - 1]
    end
    if @doer.item_number(@item) == 0 || @doer == excipient
      Sound.play_buzzer
    elsif excipient.is_a?(Game_Actor) && !excipient.item_can_have?(@item)
      Sound.play_buzzer
    else
      Sound.play_decision
      @doer.lose_item(@item, 1)
      excipient.gain_item(@item, 1)
      @item_window.draw_item(@item_window.index)
      unless excipient.is_a?(Game_Actor) && excipient.item_can_have?(@item)
        @pass_window.draw_item(@pass_window.index, false)
      end
    end
  end
end
