#=============================================================================
#  [RGSS2] ����̕ύX - v1.0.0
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/mit-license.php
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- �T    �v ----------------------------------------------------------------

  �A�N�^�[���Ƃɑ����ݒ�\�ɂ���B
  �ʒu�ɂ���Ēʏ�U�����֎~����@�\��ǉ����܂��B
  Window_Base �ɑ���̈ʒu��\������@�\��ǉ����܂��B

 -- ���ӎ��� ----------------------------------------------------------------

  �� �ǉ��@�\�́A���ׂăX�N���v�g�Œ񋟂���܂��B

 -- �g�p���@ ----------------------------------------------------------------

  �� �ʒu�̕ύX
   Game_Actors#position=(pos)
   pos : -1..�N���X�ݒ�A0..�O�q�A1..���q�A2..��q
   ��j$game_actor[1].position = 0
   
  �� �ʏ�U���s�\�Ȉʒu�̐ݒ�
   ����̃������� <�ʒu�~> �ƋL������ƁA���̈ʒu�ł͒ʏ�U���s�ɂ���B
   �����ݒ肷��ꍇ�́A���s����B
   ��j<�O�q�~>
   ���̑��ɉp����g�p�����ݒ肪�\�B
   Game_Actors::POS_NAME �Őݒ肳�ꂽ�ʒu�̖��̂ɍ��E����Ȃ��B
     <NO_VANGUARD>  : �O�q�֎~
     <NO_MIDGUARD>  : ���q�֎~
     <NO_REARGUARD> : ��q�֎~

  �� ����̎g�p����
   Game_Actors#wield_weapons?
   �߂�l : true..�ʏ�U���\�Afalse..�ʏ�U���s��
   ��j$game_actor[1].wield_weapons?

  �� �ʒu�̖��̂̎擾
   Game_Actors#position_name
   ��j$game_actor[1].position_name

  �� ����̕`��
   Window_Base#draw_actor_position(actor, x, y, width = 120, align = 0)

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  ���̃X�N���v�g�ɐݒ荀�ڂ͂���܂���B                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Actor
  # �ʒu�̖��� (�R�R��ύX����ƃ������̋L���������ω�)
  POS_NAME = ["�O�q", "���q", "��q"]
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # �� �Z�b�g�A�b�v
  #     actor_id : �A�N�^�[ ID
  #--------------------------------------------------------------------------
  alias _cao_setup_class_pos setup
  def setup(actor_id)
    _cao_setup_class_pos(actor_id)
    @position = -1
  end
  #--------------------------------------------------------------------------
  # �� �_���₷���̎擾
  #--------------------------------------------------------------------------
  def odds
    return 4 - (@position < 0 ? self.class.position : @position)
  end
  #--------------------------------------------------------------------------
  # �� ����̈ʒu�̎擾
  #--------------------------------------------------------------------------
  def position
    return (@position < 0 ? self.class.position : @position)
  end
  #--------------------------------------------------------------------------
  # �� ����̈ʒu�̕ύX
  #     pos : �ʒu (-1..�N���X�ݒ�A0..�O�q�A1..���q�A2..��q)
  #--------------------------------------------------------------------------
  def position=(pos)
    @position = pos
  end
  #--------------------------------------------------------------------------
  # �� ����̈ʒu�̖��̂��擾
  #--------------------------------------------------------------------------
  def position_name
    return POS_NAME[@position < 0 ? self.class.position : @position]
  end
  #--------------------------------------------------------------------------
  # �� �����i�̎g�p����
  #     item : �A�C�e��
  #--------------------------------------------------------------------------
  def wield?(item)
    case self.position
    when 0
      return false if item.note.match(/^<(#{POS_NAME[0]}�~|NO_VANGUARD)>/i)
    when 1
      return false if item.note.match(/^<(#{POS_NAME[1]}�~|NO_MIDGUARD)>/i)
    when 2
      return false if item.note.match(/^<(#{POS_NAME[2]}�~|NO_REARGUARD)>/i)
    end
    return true
  end
  #--------------------------------------------------------------------------
  # �� ����̎g�p����
  #--------------------------------------------------------------------------
  def wield_weapons?
    for w in self.weapons
      return false unless self.wield?(w)
    end
    return true
  end
end

class Window_Base < Window
  #--------------------------------------------------------------------------
  # �� �|�W�V�����̕`��
  #     actor : �A�N�^�[
  #     x     : �`��� X ���W
  #     y     : �`��� Y ���W
  #     width : �`���̉���
  #     align : �A���C�������g (0..�������A1..���������A2..�E����)
  #--------------------------------------------------------------------------
  def draw_actor_position(actor, x, y, width = 120, align = 0)
    self.contents.draw_text(x, y, width, WLH, actor.position_name, align)
  end
end

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # �� �A�N�^�[�R�}���h�I���̊J�n
  #--------------------------------------------------------------------------
  alias _cao_start_actor_cmd_select_class_pos start_actor_command_selection
  def start_actor_command_selection
    _cao_start_actor_cmd_select_class_pos
    unless @active_battler.wield_weapons?
      @actor_command_window.draw_item(0, false)
    end
  end
  #--------------------------------------------------------------------------
  # �� �A�N�^�[�R�}���h�I���̍X�V
  #--------------------------------------------------------------------------
  alias _cao_update_actor_cmd_select update_actor_command_selection
  def update_actor_command_selection
    if Input.trigger?(Input::C)
      if @actor_command_window.index == 0 && !@active_battler.wield_weapons?
        Sound.play_buzzer
        return
      end
    end
    _cao_update_actor_cmd_select
  end
end
