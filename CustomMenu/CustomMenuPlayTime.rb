#=============================================================================
#  [RGSS2] プレイ時間ウィンドウ - v1.0.4
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

  カスタムメニューにプレイ時間を表示するウィンドウを追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、Cacao Base Script が必要です。
  ※ このスクリプトの動作には、Custom Menu Base が必要です。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::PT
   #--------------------------------------------------------------------------
   # ◇ ウィンドウの位置とサイズ
   #--------------------------------------------------------------------------
   WINDOW_POSITION = [0, 248, 160, 56]   # [x, y, width, height]

   #--------------------------------------------------------------------------
   # ◇ システム文字 / アイコン
   #--------------------------------------------------------------------------
   #     文字列 : 文字を表示（非表示にする場合は、"" を設定してください。）
   #     数　値 : アイコンを表示（アイコン番号 [188]）
   #--------------------------------------------------------------------------
   TEXT_TIME = 188#"TIME"

   #--------------------------------------------------------------------------
   # ◇ ウィンドウスキンを使用する。
   #--------------------------------------------------------------------------
   #     false  : ウィンドウ枠が非表示になります。
   #--------------------------------------------------------------------------
   WINDOW_DISPLAY = true

 end


 #/////////////////////////////////////////////////////////////////////////////#
 #                                                                             #
 #                下記のスクリプトを変更する必要はありません。                 #
 #                                                                             #
 #/////////////////////////////////////////////////////////////////////////////#


 class Scene_Menu
   #--------------------------------------------------------------------------
   # ○ オプションウィンドウの作成
   #--------------------------------------------------------------------------
   alias _cao_create_option_window_cm_pt create_option_window
   def create_option_window
     _cao_create_option_window_cm_pt
     @time_count = Graphics.frame_rate
     @playtime_window = Window_Base.new(*PT::WINDOW_POSITION)
     @playtime_window.opacity = 0 unless PT::WINDOW_DISPLAY
     draw_time
     @component[:opt_time] = @playtime_window
   end
   #--------------------------------------------------------------------------
   # ○ オプションウィンドウの解放
   #--------------------------------------------------------------------------
   alias _cao_dispose_option_window_cm_pt dispose_option_window
   def dispose_option_window
     _cao_dispose_option_window_cm_pt
     @playtime_window.dispose
   end
   #--------------------------------------------------------------------------
   # ○ オプションウィンドウの更新
   #--------------------------------------------------------------------------
   alias _cao_update_option_window_cm_pt update_option_window
   def update_option_window
     _cao_update_option_window_cm_pt
     @time_count += 1
     if Graphics.frame_rate <= @time_count
       @time_count = 0
       draw_time
     end
   end
   #--------------------------------------------------------------------------
   # ○ プレイ時間の描画
   #--------------------------------------------------------------------------
   def draw_time
     @playtime_window.contents.clear
     rect = @playtime_window.contents.rect.dup
     if String === PT::TEXT_TIME
       @playtime_window.contents.font.color = @playtime_window.system_color
       @playtime_window.contents.draw_text(rect, PT::TEXT_TIME)
     else
       @playtime_window.draw_icon(PT::TEXT_TIME, 0, (rect.height - 24) / 2)
     end
     @playtime_window.contents.font.color = @playtime_window.normal_color
     @playtime_window.contents.draw_text(rect, RPG::Time.to_s, 2)
   end
 end
