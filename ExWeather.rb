#=============================================================================
#  [RGSS2] �V��̐ݒ� - v1.0.3
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

  �Ǝ��̓V����g�p�\�ɂ��܂��B
  �V��ɉ摜���g�p�\�ɂ��܂��B

 -- �g�p���@ ----------------------------------------------------------------

  �� �Ǝ��̓V���K�p����
   �C�x���g�R�}���h�u���x���v�ɁA���̕��͂��L��
     �V��F�V��, ����(1-9), �ω�����(0-600)[, �E�F�C�g(0-600)]
  �� �E�F�C�g���Ԃ��ȗ������ꍇ�́A�E�F�C�g���s���܂���B

  ��) �V��F��, 5, 60
  �� �e�p�����[�^�̊Ԃ̔��p�X�y�[�X�́A�ȗ��\�ł��B

=end


#==============================================================================
# �� ���[�U�[�ݒ�
#==============================================================================
module CAO
module Weather
  #--------------------------------------------------------------------------
  # �� �V��̐ݒ�
  #     "�V��" => ["", x, y, opacity, rand_x, rand_y, color = [0,0,0,0]]
  #     ""             : �t�@�C���� (�J, ��, �� �ŁA�f�t�H���g�̉摜���g�p)
  #     x, y           : �i�߂���W
  #     opacity        : �摜���������x
  #     rand_x, rand_y : �i�߂���W�ɉ����郉���_���l (�����̂�)
  #     color          : �u�����h�J���[ [red, green, blue, alpha = 255]
  #--------------------------------------------------------------------------
  WEATHER_TYPE = {
    "�J" => ["�J", -2, 8, -8, 0, 0],
    "��" => ["��", -3, 2, -4, 7, 0],
    "����" => ["��", -10, 12, -8, 5, 0],
    "��" => ["��", -3, 2, -1, 7, 0, [255,182,193]],
    "SAKURA" => ["sakura", -3, 2, -1, 7, 0],
    "�I�H" => ["p", -4, 1, -2, 0, 8],
  }
end
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                ���L�̃X�N���v�g��ύX����K�v�͂���܂���B                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Interpreter
  #--------------------------------------------------------------------------
  # �� ���x��
  #--------------------------------------------------------------------------
  alias _cao_command_118_weather command_118
  def command_118
    if /^�V��F(.+?),\s?(\d+),\s?(\d+)(?:,\s?(\d+))?/ =~ @params[0]
      return true if $game_temp.in_battle
      power = [1, [$2.to_i, 9].min].max
      duration = [0, [$3.to_i, 600].min].max
      screen.weather($1, power, duration)
      @wait_count = [0, [$4.to_i, 600].min].max if $4
      return true
    end
    return _cao_command_118_weather
  end
end

class Spriteset_Weather
  #--------------------------------------------------------------------------
  # �� �V��^�C�v�̐ݒ�
  #     type : �V�����V��^�C�v
  #--------------------------------------------------------------------------
  def type=(type)
    return if @type == type
    @type = type
    case @type
    when 0
      bitmap = nil
    when 1
      bitmap = @rain_bitmap
    when 2
      bitmap = @storm_bitmap
    when 3
      bitmap = @snow_bitmap
    else
      case CAO::Weather::WEATHER_TYPE[@type][0]
      when "�J"
        bitmap = @rain_bitmap
      when "��"
        bitmap = @storm_bitmap
      when "��"
        bitmap = @snow_bitmap
      else
        bitmap = Cache.picture(CAO::Weather::WEATHER_TYPE[@type][0])
      end
    end
    for i in 0...@sprites.size
      sprite = @sprites[i]
      sprite.visible = (i <= @max)
      sprite.bitmap = bitmap
      if (0..3) === @type || CAO::Weather::WEATHER_TYPE[@type][6].nil?
        sprite.color.set(0, 0, 0, 0)
      else
        sprite.color.set(*CAO::Weather::WEATHER_TYPE[@type][6])
      end
    end
  end
  #--------------------------------------------------------------------------
  # �� �t���[���X�V
  #--------------------------------------------------------------------------
  def update
    return if @type == 0
    for i in 1..@max
      sprite = @sprites[i]
      break if sprite == nil
      case @type
      when 1  # �J
        sprite.x -= 2
        sprite.y += 16
        sprite.opacity -= 8
      when 2  # ��
        sprite.x -= 8
        sprite.y += 16
        sprite.opacity -= 12
      when 3  # ��
        sprite.x -= 2
        sprite.y += 8
        sprite.opacity -= 8
      else    # �Ǝ��V��
        sprite.x += CAO::Weather::WEATHER_TYPE[@type][1]
        sprite.y += CAO::Weather::WEATHER_TYPE[@type][2]
        sprite.opacity += CAO::Weather::WEATHER_TYPE[@type][3]
        if CAO::Weather::WEATHER_TYPE[@type][4] > 0
          sprite.x += rand(CAO::Weather::WEATHER_TYPE[@type][4])
        end
        if CAO::Weather::WEATHER_TYPE[@type][5] > 0
          sprite.y += rand(CAO::Weather::WEATHER_TYPE[@type][5])
        end
      end
      x = sprite.x - @ox
      y = sprite.y - @oy
      if sprite.opacity < 64
        sprite.x = rand(800) - 100 + @ox
        sprite.y = rand(600) - 200 + @oy
        sprite.opacity = 255
      end
    end
  end
end
