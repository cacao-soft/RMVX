#=============================================================================
#  [RGSS2] スクリーンショット - v1.0.1
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

  現在のゲーム画面を画像保存します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、『Bitmap Class EX』 が必要です。
  ※ 画像の保存中は、ゲームが停止します。

 -- 使用方法 ----------------------------------------------------------------

  ★ 撮影する
   PrintScreen(PrtScn) キー を押してください。

=end


module CAO
module SS

  # 保存フォルダ
  DIR_NAME = "ScreenShot"

  # 保存ファイル名
  FILE_NAME = "%Y%m%d%H%M%S"

  # ロゴ
  FILE_LOGO = ""

  # 撮影時の効果音
  FILE_SOUND = RPG::SE.new("Key", 100, 150)

end # module SS
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


CAO::SS::GetKeyState = Win32API.new('user32', 'GetKeyState', 'i', 'i')

class Scene_Base
  #--------------------------------------------------------------------------
  # ● ロゴスプライト
  #--------------------------------------------------------------------------
  @@screenshot_sprite = Sprite.new
  @@screenshot_sprite.bitmap = Cache.system(CAO::SS::FILE_LOGO)
  @@screenshot_sprite.z = 99999
  @@screenshot_sprite.opacity = 0
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_ss_update update
  def update
    _cao_ss_update
    @@screenshot_sprite.update
    @@screenshot_sprite.opacity -= 4 if @@screenshot_sprite.opacity != 0
    if (CAO::SS::GetKeyState.call(0x2C) >> 15) & 1 == 1   # PrintScreen
      CAO::SS::FILE_SOUND.play
      @@screenshot_sprite.opacity = 255
      Graphics.update
      save_screen_shot
    end
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  alias _cao_ss_terminate terminate
  def terminate
    _cao_ss_terminate
    @@screenshot_sprite.opacity = 0
  end
  #--------------------------------------------------------------------------
  # ● スクリーンショットの保存
  #--------------------------------------------------------------------------
  def save_screen_shot
    make_directory
    filename = Time.now.strftime(CAO::SS::FILE_NAME) + ".png"
    bitmap = Graphics.snap_to_bitmap
    bitmap.save_png("#{CAO::SS::DIR_NAME}/#{filename}")
    bitmap.dispose
  end
  #--------------------------------------------------------------------------
  # ● スクリーンショットの保存フォルダを作成
  #--------------------------------------------------------------------------
  def make_directory
    return if CAO::SS::DIR_NAME.empty?
    return if FileTest.directory?(CAO::SS::DIR_NAME)
    dir_name = ""
    for dn in CAO::SS::DIR_NAME.split(/[\/\\]/)
      dir_name << dn
      Dir.mkdir(dir_name) unless FileTest.directory?(dir_name)
      dir_name << "/"
    end
  end
end
