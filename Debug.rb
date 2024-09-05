#=============================================================================
#  [RGSS2] ＜拡張＞ デバッグ機能 - v1.1.9
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

  デバッグ機能に下記の機能を追加します。
   - セルフスイッチ・アイテム・ゴールドの操作
   - アクターのＨＰ・ＭＰ・Ｌｖ・ステートなどの操作
   - イベント変数に文字列・配列を格納時のエラーを回避
   - 警告メッセージ表示

 -- 注意事項 ----------------------------------------------------------------

  ※ 他の素材スクリプトより上に導入してください。
  ※ cacao service pack を導入している場合は、それより下に導入してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ マップ画面で F8 キーを押すと、マップコマンドが表示されます。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   このスクリプトには設定項目はありません。                  #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO
  module Debug
    # エラーメッセージの表示
    USE_ERROR_MESSAGE = true
    
    # マップコマンド
    USE_MAP_COMMAND = true
    
    # マップコマンドキー
    KEY_MAP_COMMAND = Input::F8
    
    # 項目名
    COMMAND_NAME = [ "スイッチ", "セルフスイッチ", "イベント変数",
                     "アイテム", "武器", "防具", "ゴールド", "パーティ" ]
    
    # テキストの色
    COLOR_ERROR   = Color.new(230, 0, 0)  # エラー
    COLOR_WARNING = Color.new(0, 210, 0)  # 警告
    
    # 経験値ゲージカラー
    COLOR_EXP_INDEX_1 = 28
    COLOR_EXP_INDEX_2 = 29
    
    # コマンドのインデックス番号
    CMD_SWITCHE       = 0  # スイッチ
    CMD_SELF_SWITCHE  = 1  # セルフスイッチ
    CMD_VARIABLE      = 2  # イベント変数
    CMD_ITEM          = 3  # アイテム
    CMD_WEAPON        = 4  # 武器
    CMD_ARMOR         = 5  # 防具
    CMD_GOLD          = 6  # ゴールド
    CMD_ACTOR         = 7  # アクター
  end
end

# Game_Switches#[], Game_Variables#[] の obj == nil 対策
# 自身と同じクラスのオブジェクト意外と == すると、エラーが発生する
# CAO_SP と同じメソッド名を使用
unless $cao_sp || $!
class Color
  alias _cao_debug_equate? ==
  def ==(other)
    return other.is_a?(Color) && _cao_debug_equate?(other)
  end
end
class Rect
  alias _cao_debug_equate? ==
  def ==(other)
    return other.is_a?(Rect) && _cao_debug_equate?(other)
  end
end
class Tone
  alias _cao_debug_equate? ==
  def ==(other)
    return other.is_a?(Tone) && _cao_debug_equate?(other)
  end
end
end # unless $cao_sp

class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :debug_add_value          # デバッグ画面 状態保存用
end

class Window_DebugHelp < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, 172, WLH + 32)
  end
  #--------------------------------------------------------------------------
  # ● テキスト設定
  #     text  : ウィンドウに表示する文字列
  #     align : アラインメント (0..左揃え、1..中央揃え、2..右揃え)
  #--------------------------------------------------------------------------
  def set_text(text, align = 0)
    if text != @text or align != @align
      self.contents.clear
      self.contents.font.color = normal_color
      self.contents.draw_text(4, 0, self.width - 40, WLH, text, align)
      @text = text
      @align = align
    end
  end
end

class Window_DebugLeft < Window_Selectable
  include CAO::Debug
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x     : ウィンドウの X 座標
  #     y     : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  def initialize
    super(0, 56, 172, 272)
    self.active = false
    self.visible = false
    self.index = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    case $game_temp.debug_index
    when CMD_SWITCHE
      @item_max = ($data_system.switches.size - 1 + 9) / 10
    when CMD_SELF_SWITCHE
      @item_max = ($game_map.events.size + 9) / 10
    when CMD_VARIABLE
      @item_max = ($data_system.variables.size - 1 + 9) / 10
    when CMD_ITEM
      @item_max = ($data_items.size - 1 + 9) / 10
    when CMD_WEAPON
      @item_max = ($data_weapons.size - 1 + 9) / 10
    when CMD_ARMOR
      @item_max = ($data_armors.size - 1 + 9) / 10
    when CMD_ACTOR
      @item_max = $game_party.members.size
    end
    self.height = [[56, WLH * @item_max + 32].max, 360].min
    create_contents
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    case $game_temp.debug_index
    when CMD_ACTOR
      text = $game_party.members[index].name
    else
      n = index * 10
      text = sprintf("[%04d - %04d]", n + 1, n + 10)
    end
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    self.contents.clear_rect(rect)
    self.contents.draw_text(rect, text)
  end
end

class Window_DebugRight < Window_Selectable
  include CAO::Debug
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :top_id                   # 先頭に表示する ID
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     x : ウィンドウの X 座標
  #     y : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  def initialize
    super(172, 0, 372, 272)
    self.index = -1
    self.active = false
    @item_max = 10
    @top_id = 1
    @self_index = "A"
    @caution = { :level => 0, :type => nil }
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
  #     current_id : 項目番号
  #--------------------------------------------------------------------------
  def event_params(current_id)
    id_text = sprintf("%04d:", current_id)
    id_width = self.contents.text_size(id_text).width
    case $game_temp.debug_index
    when CMD_SWITCHE        # スイッチ
      sw_class = $game_switches[current_id].class
      # 型チェック
      if sw_class != TrueClass && sw_class != FalseClass
        @caution[:level] = 2
        @caution[:type] = :sw
        $game_switches[current_id] = false
      end
      name = $data_system.switches[current_id]
      status = $game_switches[current_id] ? "[O N]" : "[OFF]"
    when CMD_SELF_SWITCHE   # セルフスイッチ
      if $game_map.events[current_id]
        params = [$game_map.map_id, current_id, @self_index]
        sw_class = $game_self_switches[params].class
        # 型チェック
        if sw_class != TrueClass && sw_class != FalseClass
          @caution[:level] = 2
          @caution[:type] = :sw
          $game_self_switches[params] = false
        end
        name = $game_map.events[current_id].instance_variable_get(:@event).name
        status = $game_self_switches[params] ? "[O N]" : "[OFF]"
      else
        @undefined = true
        name = "　<!> 未設置"
        status = "-"
      end
    when CMD_VARIABLE       # 変数
      @caution[:level] = 1
      name = $data_system.variables[current_id]
      # 型チェック
      case $game_variables[current_id]
      when Integer
        @caution[:level] = 0
        status = sprintf("%05d", $game_variables[current_id])
        if $game_variables[current_id].abs > 99999999
          @caution[:level] = 1
          @caution[:type] = :num
          if $game_variables[current_id].abs > 999999999999
            status = "多倍長整数"
          end
        end
      when Float
        @caution[:type] = :num
        status = $game_variables[current_id]
      when String
        status = "テキスト"
      when Array
        status = "配　列"
      when Bitmap
        @caution[:level] = 2
        @caution[:type] = :dump
        status = "画　像"
      when Font, Plane, Sprite, Tilemap, Viewport, Window
        @caution[:level] = 2
        @caution[:type] = :dump
        status = $game_variables[current_id].class.to_s
      else
        @caution[:type] = :obj
        status = $game_variables[current_id].class.to_s
      end
    end
    name = "" if name == nil
    return id_text, name, status
  end
  #--------------------------------------------------------------------------
  # ● アイテムの描画内容の取得
  #     current_id : 項目番号
  #--------------------------------------------------------------------------
  def item_params(current_id)
    id_text = sprintf("%03d:", current_id)
    case $game_temp.debug_index
    when CMD_ITEM
      @item = $data_items
    when CMD_WEAPON
      @item = $data_weapons
    when CMD_ARMOR
      @item = $data_armors
    end
    if @item[current_id]
      name = @item[current_id].name
      status = sprintf("%02d", $game_party.item_number(@item[current_id]))
    else
      @undefined = true
      name = "　<!> 未設定"
      status = "--"
    end
    name = "" if name == nil
    return id_text, name, status
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index   : 項目番号
  #--------------------------------------------------------------------------
  def draw_item(index)
    current_id = @top_id + index
    @caution[:level] = 0
    @caution[:type] = nil
    @undefined = false
    case $game_temp.debug_index
    when CMD_SWITCHE, CMD_SELF_SWITCHE, CMD_VARIABLE
      id_text, name, status = event_params(current_id)
    when CMD_ITEM, CMD_WEAPON, CMD_ARMOR
      id_text, name, status = item_params(current_id)
    end
    id_width = self.contents.text_size(id_text).width
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    case @caution[:level]
    when 0
      self.contents.font.color = normal_color
    when 1
      self.contents.font.color = COLOR_WARNING
    when 2
      self.contents.font.color = COLOR_ERROR
    end
    self.contents.font.color.alpha = @undefined ? 128 : 255
    rect.x += 4
    self.contents.draw_text(rect, id_text)
    rect.x += id_width + 4
    rect.width -= id_width + 72
    rect.width -= 30 if $game_temp.debug_index == CMD_SELF_SWITCHE
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = @undefined ? 128 : 255
    self.contents.draw_text(rect, name)
    rect.x = self.contents.width - 60
    rect.width = 60
    self.contents.draw_text(rect, status, 1)
    if $game_temp.debug_index == CMD_SELF_SWITCHE
      rect.x -= 30
      self.contents.draw_text(rect, "[#{@self_index}]")
    end
    if @caution[:level] != 0
      show_error_message(current_id, @caution[:type])
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update
    super
    case $game_temp.debug_index
    when CMD_SWITCHE
      update_switches
    when CMD_SELF_SWITCHE
      update_self_switches
    when CMD_VARIABLE
      update_variables
    else
      update_items if $game_temp.debug_index < 6
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_switches
    if Input.trigger?(Input::C)
      current_id = @top_id + @index
      Sound.play_decision
      $game_switches[current_id] = !$game_switches[current_id]
      draw_item(@index)
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_self_switches
    current_id = @top_id + @index
    return unless $game_map.events[current_id]
    last_index = @self_index
    if Input.repeat?(Input::RIGHT)
      @self_index = @self_index == "D" ? "A" : @self_index.succ
    elsif Input.repeat?(Input::LEFT)
      @self_index = @self_index == "A" ? "D" : (@self_index[0] - 1).chr
    end
    if @self_index != last_index
      Sound.play_cursor
      refresh
    end
    if Input.trigger?(Input::C)
      Sound.play_decision
      $game_self_switches[[$game_map.map_id, current_id, @self_index]] ^= true
      draw_item(@index)
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_variables
    current_id = @top_id + @index
    if Input.trigger?(Input::Y)
      Sound.play_decision
      inspection_view(current_id)
      Input.update
    end
    return unless $game_variables[current_id].is_a?(Integer)
    last_value = $game_variables[current_id]
    if Input.repeat?(Input::RIGHT)
      $game_variables[current_id] += $game_temp.debug_add_value
    elsif Input.repeat?(Input::LEFT)
      $game_variables[current_id] -= $game_temp.debug_add_value
    elsif Input.trigger?(Input::Z)
      Sound.play_decision
      $game_variables[current_id] = 0
    end
    if $game_variables[current_id] != last_value
      Sound.play_cursor
      draw_item(@index)
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_items
    current_id = @top_id + @index
    last_item_number = $game_party.item_number(@item[current_id])
    if Input.repeat?(Input::RIGHT)
      $game_party.gain_item(@item[current_id], 1)
    elsif Input.repeat?(Input::LEFT)
      $game_party.gain_item(@item[current_id], -1)
    end
    if $game_party.item_number(@item[current_id]) != last_item_number
      Sound.play_cursor
      draw_item(@index)
    end
    if Input.trigger?(Input::Z)
      Sound.play_decision
      $game_party.gain_item(@item[current_id], -99)
      draw_item(@index)
    end
  end
  #--------------------------------------------------------------------------
  # ● 先頭に表示する ID の設定
  #     id : 新しい ID
  #--------------------------------------------------------------------------
  def top_id=(id)
    if @top_id != id
      @top_id = id
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def is_number
    current_id = @top_id + @index
    case $game_temp.debug_index
    when CMD_ITEM
      return $data_items[current_id] ? true : false
    when CMD_WEAPON
      return $data_weapons[current_id] ? true : false
    when CMD_ARMOR
      return $data_armors[current_id] ? true : false
    when CMD_VARIABLE
      return $game_variables[current_id].is_a?(Integer)
    else
      return false
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def number
    current_id = @top_id + @index
    case $game_temp.debug_index
    when CMD_VARIABLE
      return $game_variables[current_id]
    when CMD_ITEM
      return $game_party.item_number($data_items[current_id])
    when CMD_WEAPON
      return $game_party.item_number($data_weapons[current_id])
    when CMD_ARMOR
      return $game_party.item_number($data_armors[current_id])
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def number=(value)
    current_id = @top_id + @index
    case $game_temp.debug_index
    when CMD_VARIABLE
      $game_variables[current_id] = value
    when CMD_ITEM
      lose_value = $game_party.item_number($data_items[current_id])
      $game_party.lose_item($data_items[current_id], lose_value)
      $game_party.gain_item($data_items[current_id], value)
    when CMD_WEAPON
      lose_value = $game_party.item_number($data_weapons[current_id])
      $game_party.lose_item($data_weapons[current_id], lose_value)
      $game_party.gain_item($data_weapons[current_id], value)
    when CMD_ARMOR
      lose_value = $game_party.item_number($data_armors[current_id])
      $game_party.lose_item($data_armors[current_id], lose_value)
      $game_party.gain_item($data_armors[current_id], value)
    end
  end
  #--------------------------------------------------------------------------
  # ● 選択中のアイテムの最大数を取得
  #--------------------------------------------------------------------------
  def item_max
    case $game_temp.debug_index
    when CMD_SWITCHE
      return $data_system.switches.size
    when CMD_SELF_SWITCHE
      return $game_map.events.size
    when CMD_VARIABLE
      return $data_system.variables.size
    when CMD_ITEM
      return $data_items.size
    when CMD_WEAPON
      return $data_weapons.size
    when CMD_ARMOR
      return $data_armors.size
    when CMD_ACTOR
      return $data_actors.size
    end
  end
  #--------------------------------------------------------------------------
  # ● 選択中のアイテムを取得
  #--------------------------------------------------------------------------
  def item(current_id)
    case $game_temp.debug_index
    when CMD_SWITCHE
      return $data_system.switches[current_id]
    when CMD_SELF_SWITCHE
      return $game_self_switches[[$game_map.map_id, current_id, @self_index]]
    when CMD_VARIABLE
      return $game_variables[current_id]
    when CMD_ITEM
      return $data_items[current_id]
    when CMD_WEAPON
      return $data_weapons[current_id]
    when CMD_ARMOR
      return $data_armors[current_id]
    when CMD_ACTOR
      return $game_actors[current_id]
    end
  end
  #--------------------------------------------------------------------------
  # ● 次のページを表示
  #--------------------------------------------------------------------------
  def next_page
    if item_max > (@top_id / 10 * 10 + 11)
      Sound.play_cursor
      self.top_id = @top_id / 10 * 10 + 11
      return true
    else
      return false
    end
  end
  #--------------------------------------------------------------------------
  # ● 前のページを表示
  #--------------------------------------------------------------------------
  def prev_page
    if @top_id > 1
      Sound.play_cursor
      self.top_id = @top_id / 10 * 10 - 9
      return true
    else
      return false
    end 
  end
  #--------------------------------------------------------------------------
  # ● デバッグ文字の表示
  #--------------------------------------------------------------------------
  def inspection_view(id)
    var = $game_variables[id]
    case var
    when Bitmap
      msg = "#{var.inspect}\n横幅：#{var.width}\n縦幅：#{var.height}"
    when Font
      msg = "#{var.inspect}\n"\
            "フォント名：#{var.name.inspect}\n"\
            "サイズ：#{var.size}\n"\
            "スタイル：影#{var.shadow ? "付き" : "なし"}"\
            "#{var.bold ? "、太字" : ""}#{var.italic ? "、斜体" : ""}\n"\
            "カラー：#{var.color.inspect}"
    else
      msg = var.inspect
    end
    print msg   # 変数の値を出力
  end
  #--------------------------------------------------------------------------
  # ● エラーメッセージの表示
  #--------------------------------------------------------------------------
  def show_error_message(current_id, type)
    return unless USE_ERROR_MESSAGE
    return unless type
    message = sprintf("%04d : ", current_id)
    case type
    when :num
      message += "不正な桁数もしくは整数ではありません。\n"
      message += "　暗黙的に値が変更される危険性があります。"
    when :dump
      message += "ファイルに書き出せないオブジェクトです。\n"
      message += "　セーブ時に例外が発生する可能性があります。"
    when :sw
      message += "不正な型です。\n"
      message += "　ture/false 以外の値を保持できません。false を代入します。"
    when :obj
      message += "不正なオブジェクトです。\n"
      message += "　この変数でサポートされている値は、８桁までの整数のみです。"
    end
    print message
  end
end

class Window_DebugActor < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  CMD_NAME = 0
  CMD_LEVEL = 1
  CMD_CLASS = 2
  CMD_EXP = 3
  CMD_HP = 4
  CMD_MP = 5
  CMD_STATE = 6
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :actor_index              # 先頭に表示する ID
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(172, 0, 372, 272)
    self.index = -1
    self.active = false
    self.visible = false
    @actor_index = 0
    @states = []
    for state in $data_states
      next if state.nil?
      @states.push(state) unless state.battle_only
      break if @states.size == 18
    end
    @item_max = CMD_STATE + @states.size
    refresh
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_input
  end
  #--------------------------------------------------------------------------
  # ● の更新
  #--------------------------------------------------------------------------
  def update_input
    actor = $game_party.members[@actor_index]
    last_state = actor.states.size
    last_hp_color = hp_color(actor)
    last_level = actor.level
    case @index
    when CMD_NAME
      # 未定
    when CMD_LEVEL
      if Input.repeat?(Input::LEFT)
        actor.change_level(actor.level - $game_temp.debug_add_value, false)
        refresh
      elsif Input.repeat?(Input::RIGHT)
        actor.change_level(actor.level + $game_temp.debug_add_value, false)
        refresh
      end
    when CMD_CLASS
      class_id = actor.class_id
      if Input.repeat?(Input::LEFT)
        if $data_classes[actor.class_id - 1] != nil
          actor.class_id -= 1
        else
          actor.class_id = $data_classes.size - 1
        end
        draw_item(@index)
      elsif Input.repeat?(Input::RIGHT)
        if $data_classes[actor.class_id + 1] != nil
          actor.class_id += 1
        else
          actor.class_id = 1
        end
        draw_item(@index)
      end
    when CMD_EXP
      if Input.repeat?(Input::LEFT)
        actor.change_exp(actor.exp - $game_temp.debug_add_value, false)
        (actor.level != last_level) ? refresh : draw_item(@index)
      elsif Input.repeat?(Input::RIGHT)
        actor.change_exp(actor.exp + $game_temp.debug_add_value, false)
        (actor.level != last_level) ? refresh : draw_item(@index)
      end
    when CMD_HP
      if Input.repeat?(Input::LEFT)
        actor.hp -= $game_temp.debug_add_value
        (hp_color(actor) != last_hp_color) ? refresh : draw_item(@index)
      elsif Input.repeat?(Input::RIGHT)
        actor.hp += $game_temp.debug_add_value
        (hp_color(actor) != last_hp_color) ? refresh : draw_item(@index)
      end
    when CMD_MP
      if Input.repeat?(Input::LEFT)
        actor.mp -= $game_temp.debug_add_value
        draw_item(@index)
      elsif Input.repeat?(Input::RIGHT)
        actor.mp += $game_temp.debug_add_value
        draw_item(@index)
      end
    else  # ステート
      if Input.trigger?(Input::C)
        state_id = @states[@index - CMD_STATE].id
        if actor.state?(state_id)
          actor.remove_state(state_id)
        else
          actor.add_state(state_id)
        end
        state_id == 1 ? refresh : draw_actor_state(actor, 4, WLH * 6 + 4)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    actor = $game_party.members[@actor_index]
    return if actor == nil
    draw_actor_face(actor, 4, WLH * 0)
    draw_actor_graphic(actor, 24, 92)
    for i in 0..CMD_STATE
      draw_item(i, false)
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def draw_item(index, clear = true)
    self.contents.clear_rect(self.cursor_rect) if clear
    actor = $game_party.members[@actor_index]
    case index
    when CMD_NAME
      draw_actor_name(actor, 116, WLH * 0)
    when CMD_LEVEL
      draw_actor_level(actor, 116, WLH * 1)
    when CMD_CLASS
      draw_actor_class(actor, 116, WLH * 2)
    when CMD_EXP
      draw_actor_exp(actor, 116, WLH * 3, 220)
    when CMD_HP
      draw_actor_hp(actor, 6, WLH * 4 + 6, 160)
    when CMD_MP
      draw_actor_mp(actor, 178, WLH * 4 + 6, 160)
    when CMD_STATE
      draw_actor_state(actor, 4, WLH * 6 + 4)
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def draw_actor_state(actor, x, y)
    self.contents.clear_rect(x, y, 372, 100)
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, 120, WLH, "ステート")
    draw_item_state(actor, 24, y + WLH)
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def draw_item_state(actor, x, y)
    for i in 0...@states.size
      dx = x + i % 9 * 36
      dy = y + i / 9 * (WLH + 6) + 4
      enabled = actor.states.include?(@states[i])
      draw_icon(@states[i].icon_index, dx, dy, enabled)
     end
  end
  #--------------------------------------------------------------------------
  # ● 
  #     index : 
  #--------------------------------------------------------------------------
  def actor_index=(index)
    if @actor_index != index
      @actor_index = index
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 次のページを表示
  #--------------------------------------------------------------------------
  def next_page
    Sound.play_cursor
    self.actor_index = (@actor_index + 1) % $game_party.members.size
    return @actor_index
  end
  #--------------------------------------------------------------------------
  # ● 前のページを表示
  #--------------------------------------------------------------------------
  def prev_page
    Sound.play_cursor
    if @actor_index == 0
      self.actor_index = $game_party.members.size - 1
    else
      self.actor_index = @actor_index - 1
    end
    return @actor_index
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    if @index < 0                   # カーソル位置が 0 未満の場合
      self.cursor_rect.empty        # カーソルを無効とする
    else                            # カーソル位置が 0 以上の場合
      rect = item_rect(@index)      # 選択されている項目の矩形を取得
      if @index < CMD_HP
        rect.x = 110
        rect.width = 232
      elsif @index < CMD_STATE
        rect.y = item_rect(4).y + 6
        rect.x = 172 if @index == 5
        rect.width = 172
      else
        rect.x = (@index - CMD_STATE) % 9 * 36 + 20
        rect.width = 32
        rect.height = 32
        if @index < (CMD_STATE + 9)
          rect.y = WLH * 7 + 4
        else
          rect.y = WLH * 8 + 12
        end
      end
      self.cursor_rect = rect       # カーソルの矩形を更新
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを 1 ページ後ろに移動
  #--------------------------------------------------------------------------
  def cursor_pagedown
  end
  #--------------------------------------------------------------------------
  # ● カーソルを 1 ページ前に移動
  #--------------------------------------------------------------------------
  def cursor_pageup
  end
end

class Window_DebugActor < Window_Selectable
  #--------------------------------------------------------------------------
  # ● EXP の文字色を取得
  #     actor : アクター
  #--------------------------------------------------------------------------
  def exp_color(actor)
    return power_up_color if next_rest_exp(actor) < level_up_exp(actor) / 4
    return normal_color
  end
  #--------------------------------------------------------------------------
  # ● EXP ゲージの色 1 の取得
  #--------------------------------------------------------------------------
  def exp_gauge_color1
    return text_color(CAO::Debug::COLOR_EXP_INDEX_1)
  end
  #--------------------------------------------------------------------------
  # ● EXP ゲージの色 2 の取得
  #--------------------------------------------------------------------------
  def exp_gauge_color2
    return text_color(CAO::Debug::COLOR_EXP_INDEX_2)
  end
  #--------------------------------------------------------------------------
  # ● 次のレベルまでの経験値の取得
  #--------------------------------------------------------------------------
  def next_rest_exp(actor)
    exp_list = actor.instance_variable_get(:@exp_list)
    next_level = actor.level + 1
    return (exp_list[next_level] > 0) ? (exp_list[next_level] - actor.exp) : 0
  end
  #--------------------------------------------------------------------------
  # ● レベルアップに必要な経験値の取得
  #--------------------------------------------------------------------------
  def level_up_exp(actor)
    exp_list = actor.instance_variable_get(:@exp_list)
    level = actor.level
    return (level < 99) ? (exp_list[level + 1] - exp_list[level]) : 0
  end
  #--------------------------------------------------------------------------
  # ● レベル単位の経験値の取得
  #--------------------------------------------------------------------------
  def level_exp(actor)
    return level_up_exp(actor) - next_rest_exp(actor)
  end
  #--------------------------------------------------------------------------
  # ● 経験値の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_exp(actor, x, y, width = 120)
    draw_actor_exp_gauge(actor, x, y, width)
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 60, WLH, "経験値")
    xr = x + width
    self.contents.font.color = exp_color(actor)
    self.contents.draw_text(xr - 110, y, 50, WLH, next_rest_exp(actor), 2)
    self.contents.font.color = normal_color
    self.contents.draw_text(xr - 60, y, 10, WLH, "/", 1)
    self.contents.draw_text(xr - 50, y, 50, WLH, actor.exp, 2)
  end
  #--------------------------------------------------------------------------
  # ● 経験値ゲージの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_exp_gauge(actor, x, y, width = 120)
    gw = width
    gw = gw*level_exp(actor)/level_up_exp(actor) if next_rest_exp(actor) > 0
    gc1 = exp_gauge_color1
    gc2 = exp_gauge_color2
    self.contents.fill_rect(x, y + WLH - 8, width, 6, gauge_back_color)
    self.contents.gradient_fill_rect(x, y + WLH - 8, gw, 6, gc1, gc2)
  end
end

class Window_DebugInfo < Window_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  HELP_MODE = [:sw, :self, :var, :item, :item, :item, :gold, :act]
  TEXT_HELP = {
    # 共通
    :def  => [ "＜共通操作＞",
               "Ｃ：決定　Ｂ：キャンセル",
               "Ａ：変動値の変更　Ｘ：情報切替",
               "F9：デバッグ終了",
               "※ 場所によって機能しないものもあります。" ],
    # スイッチ
    :sw   => [ "＜スイッチ操作＞",
               "Ｃ：ＯＮ・ＯＦＦの切り替え",
               "ＬＲ：ページ送り",
               "",
               "" ],
    # セルフスイッチ
    :self => [ "＜セルフスイッチ操作＞",
               "Ｃ：ＯＮ・ＯＦＦの切り替え",
               "←→：ＡＢＣＤの切り替え",
               "ＬＲ：ページ送り",
               "" ],
    # 変数
    :var  => [ "＜イベント変数操作＞",
               "Ｃ：数値の直接入力",
               "←→：数値の増減",
               "Ｙ：値の確認",
               "ＬＲ：ページ送り" ],
    # アイテム・武器・防具
    :item => [ "＜アイテム・武器・防具操作＞",
               "Ｃ：数値の直接入力",
               "←→：数値の増減",
               "ＬＲ：ページ送り",
               "※ マイナス値にすると 0 になります。" ],
    # ゴールド
    :gold => [ "＜ゴールド操作＞",
               "Ｃ：数値の直接入力",
               "↑↓←→：数値の増減",
               "",
               "※ マイナス値にすると 0 になります。" ],
    # アクター
    :act  => [ "＜アクターステータス操作＞",
               "Ｃ：ステートの付加・解除",
               "↑↓：項目の移動",
               "←→：数値の増減",
               "ＬＲ：アクターの変更" ]
  }
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :mode
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(172, 272, 372, 144)
    @last_index = $game_temp.debug_index
    @mode = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @last_index = $game_temp.debug_index
    self.contents.clear
    text = TEXT_HELP[(@mode == 0 ? (:def) : HELP_MODE[@last_index])]
    self.contents.font.size = 14
    self.contents.font.color = system_color
    self.contents.draw_text(0, 0, 200, 16, text[0])
    self.contents.draw_text(200, 0, 140, 16, "Ｘ：情報切替", 2)
    self.contents.font.color = normal_color
    self.contents.font.size = 20
    for i in 0...4
      self.contents.draw_text(0, WLH * i + 16, 340, WLH, text[i + 1])
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    refresh if @last_index != $game_temp.debug_index
  end
end

class Window_DebugNumber < Window_Base
  include CAO::Debug
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :minus_lock               # マイナスの可否
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     digits_max : 桁数
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, 132, 56)
    @number = 0           # 入力された数値
    @digits_max = 5       # 桁数
    @index = 0            # カーソルの位置
    @unsigned = true      # マイナスの有無（true: マイナスなし）
    @minus_lock = false   # マイナスの可否（true: マイナス付加禁止）
    self.opacity = 0
    self.active = false
    self.visible = false
    self.z += 9999
    refresh
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ● 入力設定
  #     digits_max : 桁数
  #     number     : 初期値
  #     minus_lock : マイナス値の有無 (true で使用しない)
  #     index      : 選択桁 (一番左が 0)
  #--------------------------------------------------------------------------
  def set(digits_max = 5, number = 0, minus_lock = false, index = nil)
    @digits_max = digits_max
    @number = [number.abs, 10 ** @digits_max - 1].min
    @unsigned = (number >= 0)
    @minus_lock = minus_lock
    @index = (index ? index : @digits_max)
    refresh
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ● 数値の取得
  #--------------------------------------------------------------------------
  def number
    if @unsigned
      return @number
    else
      return -@number
    end
  end
  #--------------------------------------------------------------------------
  # ● 数値の設定
  #     number : 新しい数値
  #--------------------------------------------------------------------------
  def number=(number)
    @number = [number.abs, 10 ** @digits_max - 1].min
    @unsigned = (number >= 0)
    refresh
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ● 桁数の取得
  #--------------------------------------------------------------------------
  def digits_max
    return @digits_max
  end
  #--------------------------------------------------------------------------
  # ● 桁数の設定
  #     digits_max : 新しい桁数
  #--------------------------------------------------------------------------
  def digits_max=(digits_max)
    @digits_max = digits_max
    refresh
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_right(wrap)
    if @index < @digits_max or wrap
      @index = (@index + 1) % (@digits_max + 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_left(wrap)
    if @index > 0 or wrap
      @index = (@index + @digits_max) % (@digits_max + 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if self.active
      if Input.repeat?(Input::UP) or Input.repeat?(Input::DOWN)
        Sound.play_cursor
        if @index == 0
            @unsigned = !@unsigned unless @minus_lock
        else
          place = 10 ** (@digits_max - @index)
          n = @number / place % 10
          @number -= n * place
          n = (n + 1) % 10 if Input.repeat?(Input::UP)
          n = (n + 9) % 10 if Input.repeat?(Input::DOWN)
          @number += n * place
        end
        refresh
      end
      last_index = @index
      if Input.repeat?(Input::RIGHT)
        cursor_right(Input.trigger?(Input::RIGHT))
      end
      if Input.repeat?(Input::LEFT)
        cursor_left(Input.trigger?(Input::LEFT))
      end
      if @index != last_index
        Sound.play_cursor
      end
      update_cursor
    end
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = normal_color
    if $game_temp.debug_index == CMD_VARIABLE
      self.contents.font.size = 16
    end
    cw = self.contents.font.size / 2
    self.contents.draw_text(0, 0, cw, WLH, @unsigned ? "+" : "-", 1)
    s = sprintf("%0*d", @digits_max, @number)
    for i in 0...@digits_max
      self.contents.draw_text((i + 1) * cw, 0, cw, WLH, s[i,1], 1)
    end
    self.contents.font.size = 20
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    if $game_temp.debug_index == CAO::Debug::CMD_VARIABLE
      self.cursor_rect.set(@index * 8, 0, 8, WLH)
    else
      self.cursor_rect.set(@index * 10, 0, 10, WLH)
    end
  end
end

class Window_DebugSelect < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :commands                 # コマンド
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     width      : ウィンドウの幅
  #     commands   : コマンド文字列の配列
  #     column_max : 桁数 (2 以上なら横選択)
  #     row_max    : 列数 (0:コマンド数に合わせる)
  #     spacing    : 横に項目が並ぶときの空白の幅
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, 56, 56, 8)
    self.visible = false
  end
  #--------------------------------------------------------------------------
  # ● コマンド設定
  #     commands   : コマンド文字列の配列
  #     column_max : 桁数 (2 以上なら横選択)
  #     align      : アラインメント (0..左揃え、1..中央揃え、2..右揃え)
  #--------------------------------------------------------------------------
  def set(commands, column_max = 1, align = 0)
    column_max = [0, [column_max, 3].min].max
    row_max = [(commands.size + column_max - 1) / column_max, 16].min
    self.index = 0
    self.width = 140 * column_max + 32
    self.height = row_max * WLH + 32
    self.x = (544 - self.width) / 2
    self.y = (416 - self.height) / 2
    @commands = commands
    @item_max = commands.size
    @column_max = column_max
    @align = align
    create_contents
    refresh
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
    self.contents.draw_text(rect, @commands[index], @align)
  end
end

class Scene_Debug < Scene_Base
  include CAO::Debug
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    @help_window = Window_DebugHelp.new
    @help_window.set_text(COMMAND_NAME[0], 1)
    @menu_window = Window_Command.new(172, COMMAND_NAME)
    @menu_window.y = 56
    @left_window = Window_DebugLeft.new
    @right_window = Window_DebugRight.new
    @actor_window = Window_DebugActor.new
    @info_window = Window_DebugInfo.new
    create_gold_window
    @number_window = Window_DebugNumber.new
    @value_window = Window_Command.new(160, [1, 10, 100, 1000])
    @value_window.x = 192
    @value_window.y = 144
    @value_window.z += 10
    @value_window.active = false
    @value_window.visible = false
    $game_temp.debug_add_value = 1 if $game_temp.debug_add_value == nil
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    $game_map.refresh
    @help_window.dispose
    @menu_window.dispose
    @left_window.dispose
    @right_window.dispose
    @actor_window.dispose
    @info_window.dispose
    @value_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● 元の画面へ戻る
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Scene_Map.new
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    # 一発終了キー
    if Input.trigger?(Input::F9)
      Sound.play_cancel
      return_scene
      return
    end
    # 
    if Input.trigger?(Input::A)
      @value_window.index = 0
      $game_temp.debug_add_value = 1
      @value_window.active = true
      @value_window.visible = true
    elsif Input.trigger?(Input::X) && !@menu_window.active
      Sound.play_cursor
      @info_window.mode = (@info_window.mode + 1) % 2
      @info_window.refresh
    end
    if @value_window.active
      unless Input.press?(Input::A)
        @value_window.active = false
        @value_window.visible = false
      end
      last_value_index = @value_window.index
      @value_window.update
      if @value_window.index != last_value_index
        $game_temp.debug_add_value = [1, 10 ** @value_window.index].max
      end
    elsif @menu_window.active
      @help_window.set_text(COMMAND_NAME[@menu_window.index], 1)
      @menu_window.update
      update_command_input
    elsif @left_window.active
      if $game_temp.debug_index == CMD_ACTOR
        @actor_window.actor_index = @left_window.index
      else
        @right_window.top_id = @left_window.index * 10 + 1
      end
      @left_window.update
      update_left_input
    elsif @right_window.active
      @right_window.update
      update_right_input
    elsif @gold_window.active
      @gold_window.update
      update_gold_input
    elsif @actor_window.active
      @actor_window.update
      update_actor_input
    elsif @number_window.active
      @number_window.update
      update_number_input
    end
  end
  #--------------------------------------------------------------------------
  # ◎ ゴールドウィンドウの生成
  #--------------------------------------------------------------------------
  def create_gold_window
    @gold_window = Window_Base.new(166, 180, 212, 56)
    @gold_window.active = false
    @gold_window.visible = false
    @gold_window.contents.font.color = @gold_window.system_color
    @gold_window.contents.draw_text(0, 0, 60, 24, "所持金")
    @gold_window.draw_currency_value($game_party.gold, 60, 0, 120)
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウ入力の更新
  #--------------------------------------------------------------------------
  def update_command_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene
      return
    elsif Input.trigger?(Input::C)
      if @menu_window.index == CMD_ACTOR && $game_party.members.empty?
        Sound.play_buzzer
        return
      end
      Sound.play_decision
      $game_temp.debug_index = @menu_window.index
      @menu_window.active = false
      @info_window.mode = 1
      @info_window.refresh
      case $game_temp.debug_index
      when CMD_GOLD
        @gold_window.active = true
        @gold_window.visible = true
      when CMD_ACTOR
        @right_window.visible = false
        @actor_window.visible = true
        @menu_window.visible = false
        @left_window.active = true
        @left_window.visible = true
        @left_window.index = 0
        @left_window.refresh
      else
        @menu_window.visible = false
        @left_window.active = true
        @left_window.visible = true
        @left_window.index = 0
        @left_window.refresh
        @right_window.refresh
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 左ウィンドウ入力の更新
  #--------------------------------------------------------------------------
  def update_left_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @actor_window.visible = false
      @left_window.active = false
      @left_window.visible = false
      @menu_window.active = true
      @menu_window.visible = true
      @right_window.visible = true
      @right_window.contents.clear
      @info_window.mode = 0
      @info_window.refresh
    elsif Input.trigger?(Input::C)
      Sound.play_decision
      @left_window.active = false
      case $game_temp.debug_index
      when CMD_ACTOR
        @actor_window.active = true
        @actor_window.index = 0
        @actor_window.actor_index = @left_window.index
      else
        @right_window.active = true
        @right_window.index = 0
        @right_window.top_id = @left_window.index * 10 + 1
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 右ウィンドウ入力の更新
  #--------------------------------------------------------------------------
  def update_right_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @left_window.active = true
      @right_window.active = false
      @right_window.index = -1
    elsif Input.trigger?(Input::C)
      return unless @right_window.is_number
      if (CMD_ITEM..CMD_ARMOR) === $game_temp.debug_index
        @number_window.set(2, @right_window.number)
        @number_window.x = 458
      else
        @number_window.set(8, @right_window.number)
        @number_window.x = 440
      end
      @number_window.y = @right_window.index * 24
      @right_window.contents.clear_rect(276, @right_window.index * 24, 60, 24)
      @right_window.cursor_rect.empty
      @number_window.active = true
      @number_window.visible = true
      @right_window.active = false
    end
    if Input.repeat?(Input::R)
      @left_window.index += 1 if @right_window.next_page
    elsif Input.repeat?(Input::L)
      @left_window.index -= 1 if @right_window.prev_page
    end
  end
  #--------------------------------------------------------------------------
  # ● アクター選択ウィンドウ入力の更新
  #--------------------------------------------------------------------------
  def update_actor_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @left_window.active = true
      @actor_window.active = false
      @actor_window.index = -1
    end
    if Input.repeat?(Input::R)
      @left_window.index = @actor_window.next_page
    elsif Input.repeat?(Input::L)
      @left_window.index = @actor_window.prev_page
    end
  end
  #--------------------------------------------------------------------------
  # ● ゴールドウィンドウ入力の更新
  #--------------------------------------------------------------------------
  def update_gold_input
    last_gold = $game_party.gold
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @menu_window.active = true
      @gold_window.active = false
      @gold_window.visible = false
      @info_window.mode = 0
      @info_window.refresh
    elsif Input.trigger?(Input::C)
      @number_window.set(7, $game_party.gold)
      @number_window.x = @gold_window.x + 80
      @number_window.y = @gold_window.y
      @gold_window.contents.clear_rect(60, 0, 100, 24)
      @number_window.active = true
      @number_window.visible = true
      @gold_window.active = false
    end
    if Input.repeat?(Input::UP) || Input.repeat?(Input::RIGHT)
      $game_party.gain_gold($game_temp.debug_add_value)
    elsif Input.repeat?(Input::DOWN) || Input.repeat?(Input::LEFT)
      $game_party.gain_gold(-$game_temp.debug_add_value)
    elsif Input.trigger?(Input::Z)
      Sound.play_decision
      $game_party.lose_gold(9999999)
    end
    if $game_party.gold != last_gold
      @gold_window.contents.clear_rect(60, 0, 120, 24)
      @gold_window.draw_currency_value($game_party.gold, 60, 0, 120)
    end
  end
  #--------------------------------------------------------------------------
  # ● 数値入力ウィンドウ入力の更新
  #--------------------------------------------------------------------------
  def update_number_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      number = nil
    elsif Input.trigger?(Input::C)
      Sound.play_decision
      number = @number_window.number
    else
      return
    end
    @number_window.active = false
    @number_window.visible = false
    case $game_temp.debug_index
    when CMD_GOLD
      if number
        $game_party.lose_gold(9999999)
        $game_party.gain_gold(number)
      end
      @gold_window.draw_currency_value($game_party.gold, 60, 0, 120)
      @gold_window.visible = false
      @menu_window.active = true
    else
      if number
        @right_window.number = number
      end
      @right_window.draw_item(@right_window.index)
      @right_window.active = true
    end
  end
end

if CAO::Debug::USE_MAP_COMMAND
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● F9 キーによるデバッグ呼び出し判定
  #--------------------------------------------------------------------------
  def update_call_debug
    if $TEST  # テストプレイ中
      if Input.press?(Input::F9)
        $game_temp.next_scene = "debug"
      elsif Input.press?(CAO::Debug::KEY_MAP_COMMAND)
        $scene = Scene_DebugCommand.new
      end
    end
  end
end

class Scene_DebugCommand < Scene_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  COMMANDS = {}                           # 項目の処理
  CMD_NAME = []                           # 項目の名前
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    @command_window = Window_Command.new(544, CMD_NAME, 2)
    @command_window.height = [416, @command_window.height].min
    @number_window = Window_DebugNumber.new
    @number_window.x = 206
    @number_window.y = 180
    @select_window = Window_DebugSelect.new
    @versatile = nil                      # 万能変数
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    @command_window.dispose
    @number_window.dispose
    @select_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if Input.trigger?(CAO::Debug::KEY_MAP_COMMAND)
      Sound.play_cancel
      return_scene
    end
    if @command_window.active
      @command_window.update
      update_command_input
    elsif @number_window.active
      @number_window.update
      update_number_input
    elsif @select_window.active
      @select_window.update
      update_select_input
    end
  end
  #--------------------------------------------------------------------------
  # ● 元の画面へ戻る
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Scene_Map.new
  end
  #--------------------------------------------------------------------------
  # ● コマンド処理の更新
  #--------------------------------------------------------------------------
  def update_command_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene
    elsif Input.trigger?(Input::C)
      input_command
    end
  end
  #--------------------------------------------------------------------------
  # ● 数値入力の更新
  #--------------------------------------------------------------------------
  def update_number_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      hide_number
    elsif Input.trigger?(Input::C)
      input_number
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目選択の更新
  #--------------------------------------------------------------------------
  def update_select_input
    if Input.trigger?(Input::B)
      Sound.play_cancel
      hide_select
    elsif Input.trigger?(Input::C)
      input_select
    end
  end
  #--------------------------------------------------------------------------
  # ● 数値入力ウィンドウを表示
  #--------------------------------------------------------------------------
  def show_number
    @number_window.active = true
    @number_window.visible = true
    @number_window.opacity = 255
    @command_window.active = false
  end
  #--------------------------------------------------------------------------
  # ● 数値入力ウィンドウを非表示
  #--------------------------------------------------------------------------
  def hide_number
    @number_window.active = false
    @number_window.visible = false
    @number_window.opacity = 0
    @command_window.active = true
  end
  #--------------------------------------------------------------------------
  # ● 項目選択ウィンドウを表示
  #--------------------------------------------------------------------------
  def show_select
    @select_window.active = true
    @select_window.visible = true
    @command_window.active = false
  end
  #--------------------------------------------------------------------------
  # ● 項目選択ウィンドウを非表示
  #--------------------------------------------------------------------------
  def hide_select
    @select_window.active = false
    @select_window.visible = false
    @command_window.active = true
  end
  #--------------------------------------------------------------------------
  # ● コマンド処理の更新 (内容は継承先で定義する)
  #--------------------------------------------------------------------------
  def input_command
  end
  #--------------------------------------------------------------------------
  # ● 数値入力の更新 (内容は継承先で定義する)
  #--------------------------------------------------------------------------
  def input_number
  end
  #--------------------------------------------------------------------------
  # ● 項目選択の更新 (内容は継承先で定義する)
  #--------------------------------------------------------------------------
  def input_select
  end
end
end # if CAO::Debug::USE_MAP_COMMAND
