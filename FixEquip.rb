#=============================================================================
#  [RGSS2] �����̌Œ� - v1.0.0
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

  ������ʂő����������邱�Ƃ̂ł��Ȃ����ʂ�ݒ肵�܂��B

=end


class Scene_Equip < Scene_Base
  #--------------------------------------------------------------------------
  # �� �萔
  #--------------------------------------------------------------------------
  EQUIP_PERMANENTLY = { # �n�b�V���i���������s�� = ture�j
    # "�A�N�^�[��" => [����, ��, ���h��, �g�̖h��, �����i],
    "�����t" => [true, false, false, true, false],
    "�E�����J" => [true, false, false, true, false]
  }
  #--------------------------------------------------------------------------
  # �� �������ʑI���̍X�V
  #--------------------------------------------------------------------------
  def update_equip_selection
    # �L�����Z��
    if Input.trigger?(Input::B)
      Sound.play_cancel
      return_scene # �ЂƂO�ɖ߂�
    # �v
    elsif Input.trigger?(Input::R)
      Sound.play_cursor
      next_actor # ���̃A�N�^�[
    # �p
    elsif Input.trigger?(Input::L)
      Sound.play_cursor
      prev_actor # �O�̃A�N�^�[
    # ����
    elsif Input.trigger?(Input::C)
      # �����Œ�ӏ����ݒ肳��Ă���A�N�^�[�ŏ�����
      if EQUIP_PERMANENTLY.key?(@actor.name) &&
        # �I�����ꂽ�ӏ����Œ肳��Ă���Ȃ�
        EQUIP_PERMANENTLY[@actor.name][@equip_window.index]
        Sound.play_buzzer
        return # �����𒆒f���Ė߂�
      end
      # �����Œ肪�ݒ肳��Ă���Ȃ�i�W���j
      if @actor.fix_equipment
        Sound.play_buzzer
      else # �����łȂ��Ȃ�A�A�C�e���̑I���Ɉڂ�
        Sound.play_decision
        @equip_window.active = false
        @item_window.active = true
        @item_window.index = 0
      end
    end
  end
end