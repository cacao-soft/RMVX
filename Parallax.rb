#=============================================================================
#  [RGSS2] ���i�̃t�F�[�h - v1.0.0
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

  ���i�݂̂Ƀt�F�[�h���ʂ�^���܂��B

 -- ���ӎ��� ----------------------------------------------------------------

  �� �g�p�̍ۂɂ́A��L�T�C�g�̗��p�K��ɏ]���Ă��������B
  �� ��L�T�C�g�ł̃T�|�[�g�́A���f�肢�����܂��B

 -- �g�p���@ ----------------------------------------------------------------

  �� �t�F�[�h�A�E�g
   �C�x���g�R�}���h�u���x���v�� "���i�A�E�g[�t���[����]"

  �� �t�F�[�h�C��
   �C�x���g�R�}���h�u���x���v�� "���i�C��[�t���[����]"

  �� �X�N���v�g�Ńt�F�[�h�i�E�F�C�g�Ȃ��j
   �t�F�[�h�A�E�g�F $game_map.start_parallax_fadeout(�t���[����)
    �t�F�[�h�C�� �F $game_map.start_parallax_fadein(�t���[����)

  �� ���݂̃}�b�v�ݒ��K�p
   $game_map.setup_parallax

  �� ���i�̉摜��ύX
   ���@�� : $game_map.instance_variable_set(:@parallax_name, "")
   �ρ@�X : $game_map.instance_variable_set(:@parallax_name, "�t�@�C����")

  �� ���i�̃��[�v��Ԃ�ύX
   �����W : $game_map.instance_variable_set(:@parallax_loop_x, �^�U�l)
   �����W : $game_map.instance_variable_set(:@parallax_loop_y, �^�U�l)

  �� ���i�̈ړ�������ύX
   �����W : $game_map.instance_variable_set(:@parallax_sx, �ړ���)
   �����W : $game_map.instance_variable_set(:@parallax_sy, �ړ���)

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   ���̃X�N���v�g�ɐݒ荀�ڂ͂���܂���B                    #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Interpreter
  #--------------------------------------------------------------------------
  # �� ���x��
  #--------------------------------------------------------------------------
  alias _cao_command_118_expa command_118
  def command_118
    case @params[0]
    when /^���i�A�E�g(?:\[(\d+)\])?/
      if $game_message.visible
        return false
      else
        duration = $1 ? $1.to_i : 30
        $game_map.start_parallax_fadeout(duration)
        @wait_count = duration
        return true
      end
    when /^���i�C��(?:\[(\d+)\])?/
      if $game_message.visible
        return false
      else
        duration = $1 ? $1.to_i : 30
        $game_map.start_parallax_fadein(duration)
        @wait_count = duration
        return true
      end
    end
    _cao_command_118_expa
  end
end

class Game_Map
  #--------------------------------------------------------------------------
  # �� ���J�C���X�^���X�ϐ�
  #--------------------------------------------------------------------------
  attr_reader   :parallax_brightness      # ���i ���邳
  #--------------------------------------------------------------------------
  # �� ���i�̃Z�b�g�A�b�v
  #--------------------------------------------------------------------------
  alias _cao_setup_parallax_expa setup_parallax
  def setup_parallax
    _cao_setup_parallax_expa
    @parallax_brightness = 255
    @fadeout_parallax_duration = 0
    @fadein_parallax_duration = 0
  end
  #--------------------------------------------------------------------------
  # �� �t�F�[�h�A�E�g�̊J�n
  #     duration : ����
  #--------------------------------------------------------------------------
  def start_parallax_fadeout(duration)
    @fadeout_parallax_duration = duration
    @fadein_parallax_duration = 0
  end
  #--------------------------------------------------------------------------
  # �� �t�F�[�h�C���̊J�n
  #     duration : ����
  #--------------------------------------------------------------------------
  def start_parallax_fadein(duration)
    @fadein_parallax_duration = duration
    @fadeout_parallax_duration = 0
  end
  #--------------------------------------------------------------------------
  # �� �t�F�[�h�A�E�g�̍X�V
  #--------------------------------------------------------------------------
  def update_parallax_fadeout
    if @fadeout_parallax_duration >= 1
      d = @fadeout_parallax_duration
      @parallax_brightness = (@parallax_brightness * (d - 1)) / d
      @fadeout_parallax_duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # �� �t�F�[�h�C���̍X�V
  #--------------------------------------------------------------------------
  def update_parallax_fadein
    if @fadein_parallax_duration >= 1
      d = @fadein_parallax_duration
      @parallax_brightness = (@parallax_brightness * (d - 1) + 255) / d
      @fadein_parallax_duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # �� ���i�̍X�V
  #--------------------------------------------------------------------------
  alias _cao_update_parallax_expa update_parallax
  def update_parallax
    update_parallax_fadeout
    update_parallax_fadein
    _cao_update_parallax_expa
  end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # �� ���i�̍X�V
  #--------------------------------------------------------------------------
  alias _cao_update_parallax_expa update_parallax
  def update_parallax
    _cao_update_parallax_expa
    @parallax.color.set(0, 0, 0, 255 - $game_map.parallax_brightness)
  end
end
