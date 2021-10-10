#=============================================================================
#  [RGSS2] メッセージ黒背景の変更 - v1.0.0
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

  「背景を暗くする」で使用する画像をゲーム中に変更可能にします。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を多用しています。他スクリプトよりも上に設置してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ 黒背景の画像を変更する (MessageBack)
   $game_message.back_name = "ファイル名"
  ※ 画像は、Graphics/system フォルダに入れてください。

  ★ 黒背景の画像を元に戻す
   $game_message.back_name = "MessageBack"

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Message
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :back_name                # 背景画像のファイル名
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_mb initialize
  def initialize
    _cao_initialize_mb
    @back_name = "MessageBack"
  end
end

class Window_Message < Window_Selectable
  #--------------------------------------------------------------------------
  # ○ 背景スプライトの更新
  #--------------------------------------------------------------------------
  alias _cao_update_back_sprite_mb update_back_sprite
  def update_back_sprite
    if $game_message.back_name != @back_name
      @back_name = $game_message.back_name
      @back_sprite.bitmap = Cache.system(@back_name)
    end
    _cao_update_back_sprite_mb
  end
end
