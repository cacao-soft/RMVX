#=============================================================================
#  [RGSS2] スクリーンショット (F5版) - v1.0.0
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/mit-license.php
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================


module Sound
  @@camera = RPG::SE.new("Key", 100, 150)
  # 撮影音
  def self.play_camera
    @@camera.play
  end
end

class Scene_Base
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_update_ss update
  def update
    _cao_update_ss
    save_screen_shot if Input.press?(Input::F5)
  end
  #--------------------------------------------------------------------------
  # ● スクリーンショットの保存
  #--------------------------------------------------------------------------
  def save_screen_shot
    # 撮影時の効果音を再生
    Sound.play_camera
    # 保存するフォルダが無ければ、新しく作成
    Dir::mkdir("ScreenShot") unless FileTest.directory?("ScreenShot")
    # 保存するファイル名 (現在の日付と時刻を使用)
    filename = Time.now.strftime("%Y%m%d%H%M%S") + ".png"
    # 画面の画像をＰＮＧ形式で保存
    Graphics.snap_to_bitmap.save_png("ScreenShot/" + filename)
    # 保存後のメッセージ (必要なければ、コメントアウトなり削除なりする)
    print "スクリーンショットを ScreenShot フォルダに保存しました。"
  end
end