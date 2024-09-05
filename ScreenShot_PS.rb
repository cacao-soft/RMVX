#=============================================================================
#  [RGSS2] スクリーンショット (PrintScreen版) - v1.0.0
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/license/mit
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

module WIN32API
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  VK_SNAPSHOT = 0x2C    # PrintScreen
  VK_F10      = 0x79    # F10
  VK_F11      = 0x7A    # F11
  #--------------------------------------------------------------------------
  # ● クラス変数
  #--------------------------------------------------------------------------
  @@get_key_state = Win32API.new('user32', 'GetKeyState', 'i', 'i')
  #--------------------------------------------------------------------------
  # ● 仮想キーの状態を取得 (押されているか)
  #--------------------------------------------------------------------------
  def self.GetKeyState(nVirtKey)
    return @@get_key_state.call(nVirtKey) < 0
  end
end

class Scene_Base
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_update_ss update
  def update
    _cao_update_ss
    save_screen_shot if WIN32API.GetKeyState(WIN32API::VK_SNAPSHOT)
  end
  #--------------------------------------------------------------------------
  # ● スクリーンショットの保存
  #--------------------------------------------------------------------------
  def save_screen_shot
    Sound.play_camera
    Dir::mkdir("ScreenShot") unless FileTest.directory?("ScreenShot")
    filename = Time.now.strftime("%Y%m%d%H%M%S") + ".png"
    Graphics.snap_to_bitmap.save_png("ScreenShot/" + filename)
    print "スクリーンショットを ScreenShot フォルダに保存しました。"
  end
end
