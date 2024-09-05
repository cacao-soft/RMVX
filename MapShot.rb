#=============================================================================
#  [RGSS2] マップの画像保存 - v1.0.0
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

  マップを画像として保存する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には『Bitmap Class EX』が必要です。
  ※ マップサイズが大きい場合は『Cacao Base Script』が必要です。
  ※ すべてスクリプトで処理するため低速です。

 -- 使用方法 ----------------------------------------------------------------

  ★ 画像に保存する
   マップ上で F6 キーを押します。

 -- 拡張方法 ----------------------------------------------------------------

  半生さんの「Bitmapクラスの拡張」スクリプトを導入することで高速化できます。
  このスクリプト内の save_png を png_save に置換してください。
  ※ 『Bitmap Class EX』『Cacao Base Script』は不要となります。


=end


class Game_Map
  #--------------------------------------------------------------------------
  # ○ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :display_x                # 表示 X 座標 * 256
  attr_accessor :display_y                # 表示 Y 座標 * 256
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_update_ss update
  def update
    _cao_update_ss
    map_shot if Input.trigger?(Input::F6)
  end
  #--------------------------------------------------------------------------
  # ● マップ画像の保存
  #--------------------------------------------------------------------------
  def map_shot
    print "マップ画像を出力します。\n",
          "処理の完了までには、数分かかることもあります。\n",
          "その間、パソコンの操作は一切行わないでください。"

    max_width = $game_map.width * 256
    max_height = $game_map.height * 256
    screen_width = Graphics.width * 8
    screen_height = Graphics.height * 8

    bitmap = Bitmap.new($game_map.width * 32, $game_map.height * 32)

    last_display_x = $game_map.display_x
    last_display_y = $game_map.display_y
    $game_map.display_x = 0
    $game_map.display_y = 0

    time = Time.now
    while $game_map.display_y < max_height
      while $game_map.display_x < max_width
        $scene.update_basic
        Graphics.wait(5)

        ss = Graphics.snap_to_bitmap
        bitmap.blt($game_map.display_x/8, $game_map.display_y/8, ss, ss.rect)

        $game_map.display_x += screen_width
      end
      $game_map.display_x = 0
      $game_map.display_y += screen_height
    end

    $game_map.display_x = last_display_x
    $game_map.display_y = last_display_y
    $scene.update_basic

    sp = Sprite.new
    pg = Sprite.new
    Thread.new do
      sp.bitmap = Bitmap.new("Graphics/System/MessageBack")
      sp.y = (Graphics.height - sp.bitmap.height) / 2
      sp.bitmap.draw_text(0, 104, 544, 24,
        "長時間固まりますが、そのままでお待ちください。", 1)
      sp.bitmap.font.size = 48
      sp.bitmap.draw_text(0, 32, 544, 72, "ファイルに書き出し中", 1)

      pg.bitmap = Bitmap.new(64, 64)
      pg.bitmap.font.size = 60
      pg.y = Graphics.height - 96
      pg.bitmap.draw_text(pg.bitmap.rect, "◎")

      loop do
        Graphics.update
        pg.x = (pg.x + 5) % 480
        sleep(0.1)
      end
    end

    name = load_data("Data/MapInfos.rvdata")[$game_map.map_id].name
    bitmap.save_png("#{name}.png")
    bitmap.dispose

    sp.bitmap.dispose
    sp.dispose
    pg.bitmap.dispose
    pg.dispose

    time = Time.now - time
    print "すべての処理が完了しました。\n(#{time} s)"
  end
end
