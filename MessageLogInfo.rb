#=============================================================================
#  [RGSS2] メッセージログ (操作説明) - v1.0.0
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/license/mit
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- 概    要 ----------------------------------------------------------------

  メッセージとログウィンドウの右下に操作説明文を表示します。


=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # ◇ 表示文字
  #--------------------------------------------------------------------------
  LOG_INFO_TEXT = "Ｙ：ログウィンドウ開閉"
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Scene_Map
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  LOG_INFO_WIDTH = 160
  LOG_INFO_HEIGHT = 16
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  alias _cao_log_plus_start start
  def start
    _cao_log_plus_start
    @info_sprite = Sprite.new
    @info_sprite.x = 544 - LOG_INFO_WIDTH - 8
    @info_sprite.y = 416 - LOG_INFO_HEIGHT
    @info_sprite.z = @log_window.z
    @info_sprite.visible = false
    @info_sprite.bitmap = Bitmap.new(LOG_INFO_WIDTH, LOG_INFO_HEIGHT)
    @info_sprite.bitmap.font.size = LOG_INFO_HEIGHT - 4
    @info_sprite.bitmap.draw_text(@info_sprite.bitmap.rect, LOG_INFO_TEXT, 2)
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  alias _cao_log_plus_terminate terminate
  def terminate
    _cao_log_plus_terminate
    @info_sprite.bitmap.dispose
    @info_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_log_plus_update update
  def update
    _cao_log_plus_update
    if @log_window.openness == 255
      @info_sprite.y = 416 - LOG_INFO_HEIGHT
      @info_sprite.visible = true
    elsif @log_window.openness == 0
      @info_sprite.y = @message_window.y
      @info_sprite.y += @message_window.height - LOG_INFO_HEIGHT
      @info_sprite.visible = @message_window.openness == 255
    end
    @info_sprite.visible = false if $game_switches[CAO::Log::DISABLE_SW_NUM]
  end
end
