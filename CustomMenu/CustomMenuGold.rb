#=============================================================================
#  [RGSS2] 所持金ウィンドウ - v1.0.1
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

  カスタムメニューに所持金を表示するウィンドウを追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの動作には、Custom Menu Base が必要です。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::GD
   #--------------------------------------------------------------------------
   # ◇ ウィンドウの位置とサイズ
   #--------------------------------------------------------------------------
   #     ウィンドウの最小サイズは、120x56 となります。
   #--------------------------------------------------------------------------
   WINDOW_X = 0
   WINDOW_Y = 360
   WINDOW_WIDTH = 160
   WINDOW_HEIGHT = 56

   #--------------------------------------------------------------------------
   # ◇ システム文字を表示する。
   #--------------------------------------------------------------------------
   #     false  : システム文字が非表示になります。
   #--------------------------------------------------------------------------
   DISPLAY_SYSTEM = true
     #------------------------------------------------------------------------
     # ◇ システム文字 / アイコン
     #------------------------------------------------------------------------
     #     文字列 : 文字を表示（非表示にする場合は、"" を設定してください。）
     #     数　値 : アイコンを表示（アイコン番号 [147]）
     #------------------------------------------------------------------------
     TEXT_SYSTEM = ""

   #--------------------------------------------------------------------------
   # ◇ ウィンドウスキンを使用する。
   #--------------------------------------------------------------------------
   #     false  : ウィンドウ枠が非表示になります。
   #--------------------------------------------------------------------------
   DISPLAY_WINDOW = true

 end


 #/////////////////////////////////////////////////////////////////////////////#
 #                                                                             #
 #                下記のスクリプトを変更する必要はありません。                 #
 #                                                                             #
 #/////////////////////////////////////////////////////////////////////////////#


 class Window_CustomMenuGold < Window_Base
   include CAO::CM::GD
   #--------------------------------------------------------------------------
   # ● オブジェクト初期化
   #--------------------------------------------------------------------------
   def initialize
     super(WINDOW_X, WINDOW_Y, [WINDOW_WIDTH,120].max, [WINDOW_HEIGHT,56].max)
     self.opacity = 0 unless DISPLAY_WINDOW
     refresh
   end
   #--------------------------------------------------------------------------
   # ● リフレッシュ
   #--------------------------------------------------------------------------
   def refresh
     self.contents.clear
     # ウィンドウ内容を描画
     ww = contents.width
     cx = contents.text_size(Vocab::gold).width
     self.contents.font.color = system_color
     if DISPLAY_SYSTEM
       if String === TEXT_SYSTEM && TEXT_SYSTEM != ""
         self.contents.draw_text(0, 0, ww-cx-82, WLH, TEXT_SYSTEM)
       elsif Integer === TEXT_SYSTEM
         self.draw_icon(TEXT_SYSTEM, 0, 0)
       end
       self.contents.draw_text(0, 0, ww, WLH, Vocab::gold, 2)
     end
     self.contents.font.color = normal_color
     self.contents.draw_text(4, 0, ww-cx-8, WLH, $game_party.gold, 2)
   end
 end

 class Scene_Menu
   #--------------------------------------------------------------------------
   # ○ オプションウィンドウの作成
   #--------------------------------------------------------------------------
   alias _cao_create_option_window_cm_gold create_option_window
   def create_option_window
     _cao_create_option_window_cm_gold
     @gold_window = Window_CustomMenuGold.new
     @component[:option] << @gold_window
     @component[:opt_gold] = @gold_window
   end
   #--------------------------------------------------------------------------
   # ○ オプションウィンドウの解放
   #--------------------------------------------------------------------------
   alias _cao_dispose_option_window_cm_gold dispose_option_window
   def dispose_option_window
     _cao_dispose_option_window_cm_gold
     @gold_window.dispose
   end
 end