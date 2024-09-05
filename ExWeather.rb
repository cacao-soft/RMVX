#=============================================================================
#  [RGSS2] 天候の設定 - v1.0.3
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

  独自の天候を使用可能にします。
  天候に画像を使用可能にします。

 -- 使用方法 ----------------------------------------------------------------

  ★ 独自の天候を適用する
   イベントコマンド「ラベル」に、次の文章を記入
     天候：天候名, 強さ(1-9), 変化時間(0-600)[, ウェイト(0-600)]
  ※ ウェイト時間を省略した場合は、ウェイトを行いません。

  例) 天候：雪, 5, 60
  ※ 各パラメータの間の半角スペースは、省略可能です。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
module Weather
  #--------------------------------------------------------------------------
  # ◇ 天候の設定
  #     "天候名" => ["", x, y, opacity, rand_x, rand_y, color = [0,0,0,0]]
  #     ""             : ファイル名 (雨, 嵐, 雪 で、デフォルトの画像を使用)
  #     x, y           : 進める座標
  #     opacity        : 画像を消す速度
  #     rand_x, rand_y : 進める座標に加えるランダム値 (正数のみ)
  #     color          : ブレンドカラー [red, green, blue, alpha = 255]
  #--------------------------------------------------------------------------
  WEATHER_TYPE = {
    "雨" => ["雨", -2, 8, -8, 0, 0],
    "雪" => ["雪", -3, 2, -4, 7, 0],
    "吹雪" => ["雪", -10, 12, -8, 5, 0],
    "桜" => ["雪", -3, 2, -1, 7, 0, [255,182,193]],
    "SAKURA" => ["sakura", -3, 2, -1, 7, 0],
    "！？" => ["p", -4, 1, -2, 0, 8],
  }
end
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_weather command_118
  def command_118
    if /^天候：(.+?),\s?(\d+),\s?(\d+)(?:,\s?(\d+))?/ =~ @params[0]
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
  # ○ 天候タイプの設定
  #     type : 新しい天候タイプ
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
      when "雨"
        bitmap = @rain_bitmap
      when "嵐"
        bitmap = @storm_bitmap
      when "雪"
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
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    return if @type == 0
    for i in 1..@max
      sprite = @sprites[i]
      break if sprite == nil
      case @type
      when 1  # 雨
        sprite.x -= 2
        sprite.y += 16
        sprite.opacity -= 8
      when 2  # 嵐
        sprite.x -= 8
        sprite.y += 16
        sprite.opacity -= 12
      when 3  # 雪
        sprite.x -= 2
        sprite.y += 8
        sprite.opacity -= 8
      else    # 独自天候
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
