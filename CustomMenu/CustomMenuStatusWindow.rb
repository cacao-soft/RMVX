#=============================================================================
#  [RGSS2] ステータスウィンドウ - v1.1.2
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

  カスタムメニューのデフォルトっぽいステータスです。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの動作には、Custom Menu Base が必要です。
  ※ 項目の描画には、Custom Menu Canvas が必要です。
  ※ 横１列のみの場合は左右に、それ以外は上下のみスクロールします。

 -- 画像規格 ----------------------------------------------------------------

  ★ 背景画像
   背景画像を使用する場合は、"Graphics/System" にご用意ください。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::ST
   #--------------------------------------------------------------------------
   # ◇ ウィンドウの位置・サイズ
   #--------------------------------------------------------------------------
   WINDOW_X = 160  # ｘ座標
   WINDOW_Y = 0    # ｙ座標
   WINDOW_W = 384  # 横幅
   WINDOW_H = 416  # 縦幅

   #--------------------------------------------------------------------------
   # ◇ １アクターのステータスの描画領域
   #--------------------------------------------------------------------------
   ULW = 352   # 横幅
   ULH = 96    # 縦幅
   #--------------------------------------------------------------------------
   # ◇ アクターを横に並べる数
   #--------------------------------------------------------------------------
   #   縦表示にする場合は、1 を、横に並べる場合は、2 以上を設定してください。
   #   横一列の場合は、-1 でも構いません。
   #--------------------------------------------------------------------------
   COLUMN_MAX = 1

   #--------------------------------------------------------------------------
   # ◇ 表示する項目
   #--------------------------------------------------------------------------
   TEXT_PARAMS = [
     [:face,    2,  2, 92],
     [:name,  104, 12],
     [:level, 104, 36],
     [:state, 104, 60],
     [:class, 224, 12],
     [:hp,    224, 36],
     [:mp,    224, 60],
   ]

   #--------------------------------------------------------------------------
   # ◇ ウィンドウスキンを使用する。
   #--------------------------------------------------------------------------
   #     false  : ウィンドウ枠が非表示になります。
   #--------------------------------------------------------------------------
   WINDOW_DISPLAY = true

   #--------------------------------------------------------------------------
   # ◇ 背景画像
   #--------------------------------------------------------------------------
   #     使用しない場合の値は、"" です。
   #--------------------------------------------------------------------------
   BACKGROUND_IMAGE = ""

 end


 #/////////////////////////////////////////////////////////////////////////////#
 #                                                                             #
 #                下記のスクリプトを変更する必要はありません。                 #
 #                                                                             #
 #/////////////////////////////////////////////////////////////////////////////#


 class Window_CustomMenuStatus < Window_Selectable
   include CAO::CM::ST
   include CAO::CM::MenuStatusBack if BACKGROUND_IMAGE != ""
   #--------------------------------------------------------------------------
   # ● オブジェクト初期化
   #     x : ウィンドウの X 座標
   #     y : ウィンドウの Y 座標
   #--------------------------------------------------------------------------
   def initialize
     super(WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H, 0)
     create_background if BACKGROUND_IMAGE != ""
     refresh
     self.active = false
     self.opacity = 0 unless WINDOW_DISPLAY
   end
   #--------------------------------------------------------------------------
   # ● ウィンドウ内容の作成
   #--------------------------------------------------------------------------
   def create_contents
     @item_max = $game_party.members.size
     @column_max = (COLUMN_MAX < 0 ? @item_max : COLUMN_MAX)
     self.contents.dispose
     if @item_max == 0
       self.contents = CustomMenu_Canvas.new(32, 32)
     else
       self.contents = CustomMenu_Canvas.new(@column_max * ULW, row_max * ULH)
     end
   end
   #--------------------------------------------------------------------------
   # ● リフレッシュ
   #--------------------------------------------------------------------------
   def refresh
     self.contents.clear
     for actor in $game_party.members
       # 項目を描画
       for param in TEXT_PARAMS
         x = param[1] + actor.index % @column_max * ULW
         y = param[2] + actor.index / @column_max * ULH
         draw_base_item(actor, x, y, param)              # Window 定義項目
         self.contents.draw_item(actor, x, y, param)     # Canvas 定義項目
       end
     end
   end
   #--------------------------------------------------------------------------
   # ● ステータス基礎項目の描画
   #     actor  : アクター
   #     x      : 描画先 X 座標
   #     y      : 描画先 Y 座標
   #     params : オプション
   #--------------------------------------------------------------------------
   def draw_base_item(actor, x, y, params)
     case params[0]
     when :w_name
       draw_actor_name(actor, x, y)
     when :w_level
       draw_actor_level(actor, x, y)
     when :w_class
       draw_actor_class(actor, x, y)
     when :w_state
       width = params[3] ? params[3] : 120
       draw_actor_state(actor, x, y, width)
     when :w_hp
       width = params[3] ? params[3] : 120
       draw_actor_hp(actor, x, y, width)
     when :w_mp
       width = params[3] ? params[3] : 120
       draw_actor_mp(actor, x, y, width)
     when :w_exp
       width = params[3] ? params[3] : 120
       draw_actor_exp(actor, x, y, width)
     when :w_face
       size = params[3] ? params[3] : 96
       draw_actor_face(actor, x, y, size)
     when :w_chara
       draw_actor_graphic(actor, x, y)
     when :w_position
       width = params[3] ? params[3] : 120
       draw_actor_position(actor, x, y, width)
     end
   end
   #--------------------------------------------------------------------------
   # ● フレーム更新
   #--------------------------------------------------------------------------
   def update
     super
     self.contents.update_walk     # 歩行アニメのフレーム更新
     param = TEXT_PARAMS.assoc(:walk)
     if param
       for actor in $game_party.members
         x = param[1] + actor.index % @column_max * ULW
         y = param[2] + actor.index / @column_max * ULH
         self.contents.draw_move_actor_graphic(actor, x, y, param[3])
       end
     end
   end
   #--------------------------------------------------------------------------
   # ● 先頭の行の取得
   #--------------------------------------------------------------------------
   def top_row
     return self.oy / ULH
   end
   #--------------------------------------------------------------------------
   # ● 先頭の行の設定
   #     row : 先頭に表示する行
   #--------------------------------------------------------------------------
   def top_row=(row)
     row = 0 if row < 0
     row = row_max - 1 if row > row_max - 1
     self.oy = row * ULH
   end
   #--------------------------------------------------------------------------
   # ● 1 ページに表示できる行数の取得
   #--------------------------------------------------------------------------
   def page_row_max
     return (self.height - 32) / ULH
   end
   #--------------------------------------------------------------------------
   # ● 先頭の桁の取得
   #--------------------------------------------------------------------------
   def top_column
     return self.ox / ULW
   end
   #--------------------------------------------------------------------------
   # ● 先頭の桁の設定
   #     column : 先頭に表示する桁
   #--------------------------------------------------------------------------
   def top_column=(column)
     column = 0 if column < 0
     column = @column_max - 1 if column > @column_max - 1
     self.ox = column * ULW
   end
   #--------------------------------------------------------------------------
   # ● 1 ページに表示できる桁数の取得
   #--------------------------------------------------------------------------
   def page_column_max
     return (self.width - 32) / ULW
   end
   #--------------------------------------------------------------------------
   # ● 末尾の桁の取得
   #--------------------------------------------------------------------------
   def bottom_column
     return top_column + page_column_max - 1
   end
   #--------------------------------------------------------------------------
   # ● 末尾の桁の設定
   #     column : 末尾に表示する桁
   #--------------------------------------------------------------------------
   def bottom_column=(column)
     self.top_column = column - (page_column_max - 1)
   end
   #--------------------------------------------------------------------------
   # ● カーソルを 1 ページ後ろに移動
   #--------------------------------------------------------------------------
   def cursor_pagedown
     if top_row + page_row_max < row_max
       @index = [@index + page_item_max, @item_max - 1].min
       self.top_row += page_row_max
     elsif top_column + page_column_max < @column_max
       @index = [@index + page_column_max, @item_max - 1].min
       self.top_column += page_column_max
     end
   end
   #--------------------------------------------------------------------------
   # ● カーソルを 1 ページ前に移動
   #--------------------------------------------------------------------------
   def cursor_pageup
     if top_row > 0
       @index = [@index - page_item_max, 0].max
       self.top_row -= page_row_max
     elsif top_column > 0
       @index = [@index - page_column_max, 0].max
       self.top_column -= page_column_max
     end
   end
   #--------------------------------------------------------------------------
   # ● 項目を描画する矩形の取得
   #     index : 項目番号
   #--------------------------------------------------------------------------
   def item_rect(index)
     rect = Rect.new(0, 0, 0, 0)
     rect.width = ULW
     rect.height = ULH
     rect.x = index % @column_max * ULW
     rect.y = index / @column_max * ULH
     return rect
   end
   #--------------------------------------------------------------------------
   # ● カーソルの更新
   #--------------------------------------------------------------------------
   def update_cursor
     if @index < 0               # カーソルなし
       self.cursor_rect.empty
     else
       if row_max == 1           # 横並びのステータス
         self.top_column = @index if @index < top_column
         self.bottom_column = @index if @index > bottom_column
       else                      # それ以外
         row = @index / page_column_max
         self.top_row = row if row < top_row
         self.bottom_row = row if row > bottom_row
       end
       # 現在選択中の項目の座標を計算
       x = @index % @column_max * ULW
       y = @index / @column_max * ULH
       if @index < @item_max     # 通常
         self.cursor_rect.set(x, y, ULW, ULH)
       elsif @index >= 100       # 自分
         self.top_row = @index - 100
         self.cursor_rect.set(x, y, ULW, ULH)
       else                      # 全体
         self.top_row = 0
         self.cursor_rect.set(0, 0, contents.width, contents.height)
       end
       # カーソルをスクロール位置に合わせる
       self.cursor_rect.x -= self.ox
       self.cursor_rect.y -= self.oy
     end
   end
 end

 class Scene_Menu < Scene_Base
   #--------------------------------------------------------------------------
   # ● ステータスウィンドウの作成
   #--------------------------------------------------------------------------
   def create_status_window
     @status_window = Window_CustomMenuStatus.new
     @component[:status] = @status_window
     @component[:sta_win] = @status_window
   end
   #--------------------------------------------------------------------------
   # ● ステータスウィンドウの解放
   #--------------------------------------------------------------------------
   def dispose_status_window
     @status_window.dispose
   end
   #--------------------------------------------------------------------------
   # ● ステータスウィンドウの更新
   #--------------------------------------------------------------------------
   def update_status_window
     @status_window.update
   end
 end
