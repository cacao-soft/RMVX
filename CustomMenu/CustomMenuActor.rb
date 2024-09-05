#=============================================================================
#  [RGSS2] 立ち絵表示 - v1.0.3
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

  カスタムメニューにパーティの立ち絵を表示する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの動作には、Custom Menu Base が必要です。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::AG
   #--------------------------------------------------------------------------
   # ◇ 画像の位置
   #--------------------------------------------------------------------------
   POSITIONS = [
     [364, 64], [304, 124], [424, 184], [364, 224]
   ]

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
   alias _cao_create_option_window_cm_ag create_option_window
   def create_option_window
     _cao_create_option_window_cm_ag
     @actor_sprite = []
     for i in 0...$game_party.members.size
       unless i < AG::POSITIONS.size
         msg = "#{i+1} 人目の位置が設定されていません。\n"\
               "立ち絵表示(POSITIONS)の設定を確認してください。"
         raise CustomizeError, msg, __FILE__
       end
       @actor_sprite[i] = Sprite.new
       @actor_sprite[i].bitmap = Cache.picture($game_party.members[i].body_name)
       @actor_sprite[i].x = AG::POSITIONS[i][0]
       @actor_sprite[i].y = AG::POSITIONS[i][1]
     end
     @component[:opt_actor] = @actor_sprite
   end
   #--------------------------------------------------------------------------
   # ○ オプションウィンドウの解放
   #--------------------------------------------------------------------------
   alias _cao_dispose_option_window_cm_ag dispose_option_window
   def dispose_option_window
     _cao_dispose_option_window_cm_ag
     for i in 0...@actor_sprite.size
       @actor_sprite[i].dispose
     end
   end
 end
