#=============================================================================
#  [RGSS2] ステータス振り分け - v1.0.3
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

  ステータスを振り分ける機能を追加します。
  メニュー画面から振り分けを行うこともできます。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、Cacao Base Script が必要です。

 -- 使用方法 ----------------------------------------------------------------

 ※ ⇒：注釈  §：スクリプト

 ★ 振り分け画面の呼び出し
   § $game_temp.next_scene = "spoint"   # マップなど
   § start_spoint                       # メニュー専用

 ★ 振り分けポイントの格納変数
   § $game_actors[n].spoint

=end


#==============================================================================
# ◆ ユーザー設定（項目数：４）
#==============================================================================
  
module CAO; class Status
  #--------------------------------------------------------------------------
  # ◇ レベルアップ時に貰えるポイント
  #--------------------------------------------------------------------------
    STATUS_POINT = 5
  #--------------------------------------------------------------------------
  # ◇１ステータスごとの振り分けの上限（推奨：8, 10, 20）
  #--------------------------------------------------------------------------
    MAX_SORT = 10
  #--------------------------------------------------------------------------
  # ◇ ポイント１に対して、ステータスをいくつ上げるか
  #--------------------------------------------------------------------------
    UP_HP  = 5    # ＨＰの増加数
    UP_MP  = 5    # ＭＰの増加数
    UP_ATK = 1    # 攻撃力の増加数
    UP_DEF = 1    # 防御力の増加数
    UP_SPI = 1    # 精神力の増加数
    UP_AGI = 1    # 俊敏性の増加数
  #--------------------------------------------------------------------------
  # ◇ 用語の設定
  #--------------------------------------------------------------------------
    # 残りのポイント
    INFOS_REMAINING_POINT = "残りポイント"

end; end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Actor < Game_Battler
  attr_accessor :spoint
  alias _cao_setup_status setup
  def setup(actor_id)
    @spoint = 0
    _cao_setup_status(actor_id)
  end
  alias _cao_level_up_status level_up
  def level_up
    _cao_level_up_status
    $game_actors[self.id].spoint += CAO::Status::STATUS_POINT
  end
end
class Scene_Map
  #--------------------------------------------------------------------------
  # ○ 画面切り替えの実行
  #--------------------------------------------------------------------------
  alias _cao_spoint_update_scene_change update_scene_change
  def update_scene_change
    return if $game_player.moving?    # プレイヤーの移動中？
    if $game_temp.next_scene == "spoint"
      $game_temp.next_scene = nil
      $scene = Scene_ActorSelect_S.new
    else
      _cao_spoint_update_scene_change
    end
  end
end
class Scene_Menu < Scene_Base
  def start_spoint(type = 0)
    @from_spoint = type
    start_actor_selection
  end
  alias _cao_update_actor_selection_spoint update_actor_selection
  def update_actor_selection
    if Input.trigger?(Input::C) && @from_spoint == 0
      @from_spoint = nil
      Sound.play_decision
      actor_id = $game_party.members[@status_window.index].id
      $scene = Scene_StatusPoint.new(actor_id, @command_window.index)
    end
    _cao_update_actor_selection_spoint
  end
end
class Window_ParaStatus < Window_Base
  def initialize(actor_id)
    super(132, 28, 280, 128)
    @actor = $game_actors[actor_id]
    refresh
  end
  def refresh
    draw_actor_name(@actor, 2, WLH * 0)
    draw_actor_class(@actor, 2, WLH * 1)
    draw_actor_hp(@actor, 2, WLH * 2)
    draw_actor_mp(@actor, 2, WLH * 3)
    for i in 0...4
      draw_actor_parameter(@actor, 132, WLH * i, i)
    end
  end
  def draw_actor_parameter(actor, x, y, type)
    case type
    when 0
      parameter_name = Vocab::atk
      parameter_value = actor.atk
    when 1
      parameter_name = Vocab::def
      parameter_value = actor.def
    when 2
      parameter_name = Vocab::spi
      parameter_value = actor.spi
    when 3
      parameter_name = Vocab::agi
      parameter_value = actor.agi
    end
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 72, WLH, parameter_name)
    self.contents.font.color = normal_color
    self.contents.draw_text(x + 72, y, 40, WLH, parameter_value, 2)
  end
end
class Window_StatusPoint < Window_Selectable
  def initialize(actor_id)
    super(132, 156, 280, 176)
    @actor = $game_actors[actor_id]
    @spoint = @actor.spoint
    @psort = Array.new(6, 0)
    s = CAO::Status
    @s_rate = [s::UP_HP, s::UP_MP, s::UP_ATK, s::UP_DEF, s::UP_SPI, s::UP_AGI]
    @dumy_status = Array.new(6, 0)
    @item_max = 6
    @index = 0
    refresh
  end
  def refresh
    self.contents.clear
    s_name = [Vocab.hp, Vocab.mp, Vocab.atk, Vocab.def, Vocab.spi, Vocab.agi]
    for i in 0...6
      self.contents.font.color = system_color
      self.contents.draw_text(0, WLH * i, 48, WLH, s_name[i], 1)
      gauge(WLH * i, @psort[i])
      total_point = @psort[i] * @s_rate[i]
      self.contents.font.color = normal_color
      self.contents.draw_text(184, WLH * i, 16, WLH, "+", 2)
      text = sprintf("%04d", total_point)
      self.contents.draw_text(200, WLH * i, 48, WLH, text, 2)
    end
  end
  def gauge(y, point)
    color = Color.new(200, 200, 200)
    g1, g2 = Color.new(230, 160, 50), Color.new(240, 120, 30)
    for i in 0...point
      x = 120 / CAO::Status::MAX_SORT * i + 58
      w = 80 / CAO::Status::MAX_SORT
      self.contents.fill_rect(x + 2, y + 3, w, 18, color)
      self.contents.gradient_fill_rect(x + 3, y + 4, w - 2, 16, g1, g2, 1)
    end
  end
  def update
    if cursor_movable?
      last_index = @index
      if Input.repeat?(Input::DOWN)
        cursor_down(Input.trigger?(Input::DOWN))
      end
      if Input.repeat?(Input::UP)
        cursor_up(Input.trigger?(Input::UP))
      end
      if Input.repeat?(Input::RIGHT)
        cursor_right
        refresh
      end
      if Input.repeat?(Input::LEFT)
        cursor_left
        refresh
      end
      if @index != last_index
        Sound.play_cursor
      end
    end
    update_cursor
    call_update_help
  end
  def cursor_right
    if @actor.spoint > 0 && @psort[@index] < CAO::Status::MAX_SORT
      status = [ @actor.maxhp, @actor.maxmp,
                  @actor.atk, @actor.def, @actor.spi, @actor.agi ]
      @psort[@index] == 0 ? ps = 1 : ps = @psort[@index]
      if @index < 2 && status[@index] + @s_rate[@index] * ps < 9999
        Sound.play_cursor
        @actor.spoint -= 1
        @psort[@index] += 1
      elsif status[@index] + @s_rate[@index] * ps < 999
        Sound.play_cursor
        @actor.spoint -= 1
        @psort[@index] += 1
      else
        Sound.play_buzzer
      end
    end
  end
  def cursor_left
    if @psort[@index] > 0
      Sound.play_cursor
      @actor.spoint += 1
      @psort[@index] -= 1
    end
  end
  def update_cursor
    if @index < 0
      self.cursor_rect.empty
    else
      row = @index / @column_max
      if row < top_row
        self.top_row = row
      end
      if row > bottom_row
        self.bottom_row = row
      end
      rect = item_rect(@index)
      rect.x = 50
      rect.width = 134
      rect.y -= self.oy
      self.cursor_rect = rect
    end
  end
  def cancel_sort
    @actor.spoint = @spoint
  end
  def decision_sort
    for i in 0...6
      case i 
        when 0 ; @actor.maxhp += @s_rate[i] * @psort[i]
        when 1 ; @actor.maxmp += @s_rate[i] * @psort[i]
        when 2 ; @actor.atk   += @s_rate[i] * @psort[i]
        when 3 ; @actor.def   += @s_rate[i] * @psort[i]
        when 4 ; @actor.spi   += @s_rate[i] * @psort[i]
        when 5 ; @actor.agi   += @s_rate[i] * @psort[i]
      end
    end
  end
end
class Window_SpointInfos < Window_Base
  def initialize(actor_id)
    super(132, 332, 280, 56)
    @actor = $game_actors[actor_id]
    @spoint = @actor.spoint
    refresh
  end
  def refresh
    self.contents.clear 
    self.contents.font.color = system_color
    text = CAO::Status::INFOS_REMAINING_POINT
    self.contents.draw_text(12, 0, 200, WLH, text)
    if @actor.spoint < 10
      spoint_s = "00" + @actor.spoint.to_s
    elsif @actor.spoint < 100
      spoint_s = "0" + @actor.spoint.to_s
    end
    self.contents.font.color = normal_color
    self.contents.draw_text(200, 0, 36, WLH, spoint_s, 1)
  end
  def update
    if @spoint != @actor.spoint
      @spoint = @actor.spoint
      refresh
    end
  end
end
class Scene_StatusPoint < Scene_Base
  def initialize(actor_id, from = -1)
    @actor_id = actor_id
    @from = from
  end
  def start
    super
    create_menu_background
    @pstatus_window = Window_ParaStatus.new(@actor_id)
    @spoint_window = Window_StatusPoint.new(@actor_id)
    @sinfos_window = Window_SpointInfos.new(@actor_id)
  end
  def terminate
    super
    dispose_menu_background
    @pstatus_window.dispose
    @spoint_window.dispose
    @sinfos_window.dispose
  end
  def return_scene
    @from == -1 ? $scene = Scene_Map.new : $scene = Scene_Menu.new(@from)
  end
  def update
    super
    update_menu_background
    @pstatus_window.update
    @spoint_window.update
    @sinfos_window.update
    if Input.trigger?(Input::C)
      Sound.play_decision
      @spoint_window.decision_sort
      return_scene
    end
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @spoint_window.cancel_sort
      return_scene
    end
  end
end
class Scene_ActorSelect_S < Scene_Base
  def start
    super
    create_menu_background
    create_command_window
  end
  def post_start
    super
    open_command_window
  end
  def pre_terminate
    super
    close_command_window
  end
  def terminate
    super
    dispose_command_window
    dispose_menu_background
  end
  def update
    super
    update_menu_background
    @command_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      actor_id = $game_party.members[@command_window.index].id
      $scene = Scene_StatusPoint.new(actor_id)
    end
  end
  def update_menu_background
    super
    @menuback_sprite.tone.set(0, 0, 0, 128)
  end
  def create_command_window
    para = []
    for i in 0...$game_party.members.size
      para[i] = $game_party.members[i].name
    end
    @command_window = Window_Command.new(172, para)
    @command_window.x = (544 - @command_window.width) / 2
    @command_window.y = (416 - @command_window.height) / 2
    @command_window.openness = 0
  end
  def dispose_command_window
    @command_window.dispose
  end
  def open_command_window
    @command_window.open
    begin
      @command_window.update
      Graphics.update
    end until @command_window.openness == 255
  end
  def close_command_window
    @command_window.close
    begin
      @command_window.update
      Graphics.update
    end until @command_window.openness == 0
  end
end
