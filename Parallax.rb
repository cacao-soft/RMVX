#=============================================================================
#  [RGSS2] 遠景のフェード - v1.0.0
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

  遠景のみにフェード効果を与えます。

 -- 注意事項 ----------------------------------------------------------------

  ※ 使用の際には、上記サイトの利用規約に従ってください。
  ※ 上記サイトでのサポートは、お断りいたします。

 -- 使用方法 ----------------------------------------------------------------

  ★ フェードアウト
   イベントコマンド「ラベル」に "遠景アウト[フレーム数]"

  ★ フェードイン
   イベントコマンド「ラベル」に "遠景イン[フレーム数]"

  § スクリプトでフェード（ウェイトなし）
   フェードアウト： $game_map.start_parallax_fadeout(フレーム数)
    フェードイン ： $game_map.start_parallax_fadein(フレーム数)

  § 現在のマップ設定を適用
   $game_map.setup_parallax

  § 遠景の画像を変更
   消　去 : $game_map.instance_variable_set(:@parallax_name, "")
   変　更 : $game_map.instance_variable_set(:@parallax_name, "ファイル名")

  § 遠景のループ状態を変更
   ｘ座標 : $game_map.instance_variable_set(:@parallax_loop_x, 真偽値)
   ｙ座標 : $game_map.instance_variable_set(:@parallax_loop_y, 真偽値)

  § 遠景の移動距離を変更
   ｘ座標 : $game_map.instance_variable_set(:@parallax_sx, 移動量)
   ｙ座標 : $game_map.instance_variable_set(:@parallax_sy, 移動量)

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   このスクリプトに設定項目はありません。                    #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_expa command_118
  def command_118
    case @params[0]
    when /^遠景アウト(?:\[(\d+)\])?/
      if $game_message.visible
        return false
      else
        duration = $1 ? $1.to_i : 30
        $game_map.start_parallax_fadeout(duration)
        @wait_count = duration
        return true
      end
    when /^遠景イン(?:\[(\d+)\])?/
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
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :parallax_brightness      # 遠景 明るさ
  #--------------------------------------------------------------------------
  # ○ 遠景のセットアップ
  #--------------------------------------------------------------------------
  alias _cao_setup_parallax_expa setup_parallax
  def setup_parallax
    _cao_setup_parallax_expa
    @parallax_brightness = 255
    @fadeout_parallax_duration = 0
    @fadein_parallax_duration = 0
  end
  #--------------------------------------------------------------------------
  # ◎ フェードアウトの開始
  #     duration : 時間
  #--------------------------------------------------------------------------
  def start_parallax_fadeout(duration)
    @fadeout_parallax_duration = duration
    @fadein_parallax_duration = 0
  end
  #--------------------------------------------------------------------------
  # ◎ フェードインの開始
  #     duration : 時間
  #--------------------------------------------------------------------------
  def start_parallax_fadein(duration)
    @fadein_parallax_duration = duration
    @fadeout_parallax_duration = 0
  end
  #--------------------------------------------------------------------------
  # ◎ フェードアウトの更新
  #--------------------------------------------------------------------------
  def update_parallax_fadeout
    if @fadeout_parallax_duration >= 1
      d = @fadeout_parallax_duration
      @parallax_brightness = (@parallax_brightness * (d - 1)) / d
      @fadeout_parallax_duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # ◎ フェードインの更新
  #--------------------------------------------------------------------------
  def update_parallax_fadein
    if @fadein_parallax_duration >= 1
      d = @fadein_parallax_duration
      @parallax_brightness = (@parallax_brightness * (d - 1) + 255) / d
      @fadein_parallax_duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # ○ 遠景の更新
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
  # ○ 遠景の更新
  #--------------------------------------------------------------------------
  alias _cao_update_parallax_expa update_parallax
  def update_parallax
    _cao_update_parallax_expa
    @parallax.color.set(0, 0, 0, 255 - $game_map.parallax_brightness)
  end
end
