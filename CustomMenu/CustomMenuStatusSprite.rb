#=============================================================================
#  [RGSS2] ステータススプライト - v1.2.1
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

  カスタムメニューの画像を使用するステータスです。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの動作には、Custom Menu Base が必要です。
  ※ 項目の設定は、Custom Menu Base で行ってください。

 -- 画像規格 ----------------------------------------------------------------

  ★ 背景画像
   保存場所：Graphics/System
   ファイル名：任意 (設定項目で変更可能)
   画像サイズ：任意 (制限はありません)
   ※ すべてのアクターで共通のものを使用します。
   ※ 使用しない場合は、必要ありません。

  ★ カーソル画像
   保存場所：Graphics/System
   ファイル名：任意 (設定項目で変更可能)
   画像サイズ：任意 (制限はありません)
   ※ アニメーションのコマを横に並べた画像をご用意ください。
   ※ 使用しない場合は、必要ありません。

  ★ 立ち絵画像
   保存場所：Graphics/Pictures
   ファイル名：Custom Menu Canvas で設定
   画像サイズ：任意 (制限はありません)
   ※ 表示する項目の設定で、:body を使用した際に必要になります。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::ST
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの位置
  #--------------------------------------------------------------------------
  #   パーティの最大数だけ [x, y] の要素を追加してください。
  #--------------------------------------------------------------------------
  WINDOW_POSITION = [ [176, 80], [192, 176], [208, 272] ]
  #--------------------------------------------------------------------------
  # ◇ ウィンドウのサイズ (32pxの余白なし)
  #--------------------------------------------------------------------------
  WINDOW_WIDTH = 324   # 横幅
  WINDOW_HEIGHT = 80   # 縦幅

  #--------------------------------------------------------------------------
  # ◇ カーソルの位置とサイズ (基点座標は各ステータスの左上でマイナス値可)
  #--------------------------------------------------------------------------
  #   ウィンドウスキンを使用   : [ｘ座標, ｙ座標, 横幅, 縦幅]
  #   アニメーション画像を使用 : [ｘ座標, ｙ座標, "ファイル名", コマ数, 時間]
  #--------------------------------------------------------------------------
  CURSOR_RECT = [0, 0, 324, 80]
  #--------------------------------------------------------------------------
  # ◇ カーソルタイプ
  #--------------------------------------------------------------------------
  #   0      : 横 (左右キーのみで移動)
  #   1      : 縦 (上下キーのみで移動)
  #   2 以上 : 縦横 (左右キーで１つ移動、上下キーで指定値移動)
  #--------------------------------------------------------------------------
  CURSOR_TYPE = 1

  #--------------------------------------------------------------------------
  # ◇ 表示する項目
  #--------------------------------------------------------------------------
  #   [描画項目の識別子, 描画位置(x, y), オプション...]
  #   設定の詳細は Custom Menu Canvas 参照
  #--------------------------------------------------------------------------
  TEXT_PARAMS = [
    [:walk,     36, 64, true],

    [:name,     72,  4],
    [:level_g,  72, 28],
    [:state,    72, 52],

    [:class,   200,  4],
    [:hp,      200, 28],
    [:mp,      200, 52],
  ]

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


class Sprite_CustomMenuStatus < Sprite
  #--------------------------------------------------------------------------
  # ● インクルード
  #--------------------------------------------------------------------------
  include CAO::CM::ST
  include CAO::CM::MenuStatusBack if BACKGROUND_IMAGE != ""
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :actor                    #
  #--------------------------------------------------------------------------
  # ● オブジェクトの初期化
  #--------------------------------------------------------------------------
  def initialize(index)
    super()
    @window_id = index
    create_background if BACKGROUND_IMAGE != ""
    self.x = WINDOW_POSITION[@window_id][0]
    self.y = WINDOW_POSITION[@window_id][1]
    self.z = @window_id + 10
    self.bitmap = CustomMenu_Canvas.new(WINDOW_WIDTH, WINDOW_HEIGHT)
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.bitmap.clear
    return if @actor == nil
    for param in TEXT_PARAMS
      self.bitmap.draw_item(@actor, param[1], param[2], param)
    end
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    self.bitmap.update_walk
    param = TEXT_PARAMS.assoc(:walk)
    if param && @actor
      self.bitmap.draw_move_actor_graphic(@actor, param[1], param[2], param[3])
    end
  end
end

class Sprite_MenuCursor < Sprite
  include CAO::CM::ST
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :item_max                 # 項目数
  attr_reader   :index                    # カーソル位置
  attr_accessor :active                   # カーソルの点滅状態
  #--------------------------------------------------------------------------
  # ● オブジェクトの初期化
  #--------------------------------------------------------------------------
  def initialize
    super(Viewport.new(0, 0, 32, 32))
    self.viewport.z = 1
    if String === CURSOR_RECT[2]
      self.bitmap = Cache.system(CURSOR_RECT[2])
      self.viewport.rect.width = self.bitmap.width / CURSOR_RECT[3]
      self.viewport.rect.height = self.bitmap.height
    else
      self.bitmap = Bitmap.new(CURSOR_RECT[2], CURSOR_RECT[3])
      self.viewport.rect.width = self.bitmap.width
      self.viewport.rect.height = self.bitmap.height
      create_cursor
    end
    self.visible = false
    @item_max = $game_party.members.size
    @active = false
    @index = -1
    @top_index = 0
    @blink = true
  end
  #--------------------------------------------------------------------------
  # ● カーソル画像の生成
  #--------------------------------------------------------------------------
  def create_cursor
    self.bitmap.clear
    src_rect = Rect.new(0, 0, 0, 0)
    dest_rect = Rect.new(0, 0, 0, 0)
    width = self.bitmap.width
    height = self.bitmap.height
    bitmap = Cache.system("Window")
    # 角
    src_rect.set(64, 64, 2, 2)
    self.bitmap.blt(0, 0, bitmap, src_rect)
    src_rect.set(94, 64, 2, 2)
    self.bitmap.blt(width - 2, 0, bitmap, src_rect)
    src_rect.set(64, 94, 2, 2)
    self.bitmap.blt(0, height - 2, bitmap, src_rect)
    src_rect.set(94, 94, 2, 2)
    self.bitmap.blt(width - 2, height - 2, bitmap, src_rect)
    # 辺
    dest_rect.set(2, 0, width - 4, 2)
    src_rect.set(66, 64, 28, 2)
    self.bitmap.stretch_blt(dest_rect, bitmap, src_rect)
    dest_rect.set(2, height - 2, width - 4, 2)
    src_rect.set(66, 94, 28, 2)
    self.bitmap.stretch_blt(dest_rect, bitmap, src_rect)
    dest_rect.set(0, 2, 2, height - 4)
    src_rect.set(64, 66, 2, 28)
    self.bitmap.stretch_blt(dest_rect, bitmap, src_rect)
    dest_rect.set(width - 2, 2, 2, height - 4)
    src_rect.set(94, 66, 2, 28)
    self.bitmap.stretch_blt(dest_rect, bitmap, src_rect)
    # 面
    src_rect.set(66, 66, 28, 28)
    dest_rect.set(0, 0, width, height)
    b = Bitmap.new(width, height)
    b.stretch_blt(dest_rect, bitmap, src_rect)
    b.blur
    src_rect.set(2, 2, width - 4, height - 4)
    self.bitmap.blt(2, 2, b, src_rect)
    b.dispose
  end
  #--------------------------------------------------------------------------
  # ● カーソル位置の設定
  #     index : 新しいカーソル位置
  #--------------------------------------------------------------------------
  def index=(index)
    @index = index
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ● 先頭の行の取得
  #--------------------------------------------------------------------------
  def top_row
    return @top_index
  end
  #--------------------------------------------------------------------------
  # ● 先頭の行の設定
  #     row : 先頭に表示する行
  #--------------------------------------------------------------------------
  def top_row=(row)
    row = 0 if row < 0
    row = @item_max - 1 if row > @item_max - 1
    @top_index = row
  end
  #--------------------------------------------------------------------------
  # ● 末尾の行の取得
  #--------------------------------------------------------------------------
  def bottom_row
    return top_row + WINDOW_POSITION.size - 1
  end
  #--------------------------------------------------------------------------
  # ● 末尾の行の設定
  #     row : 末尾に表示する行
  #--------------------------------------------------------------------------
  def bottom_row=(row)
    self.top_row = row - (WINDOW_POSITION.size - 1)
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動可能判定
  #--------------------------------------------------------------------------
  def cursor_movable?
    return false if (not visible or not active)
    return false if (@index < 0 or @index > @item_max or @item_max == 0)
    return true
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if cursor_movable?
      last_index = @index
      if Input.repeat?(Input::DOWN)
        cursor_down(Input.trigger?(Input::DOWN))
      end
      if Input.repeat?(Input::UP)
        cursor_up(Input.trigger?(Input::UP))
      end
      if Input.repeat?(Input::RIGHT)
        cursor_right(Input.trigger?(Input::RIGHT))
      end
      if Input.repeat?(Input::LEFT)
        cursor_left(Input.trigger?(Input::LEFT))
      end
      if @index != last_index
        Sound.play_cursor
      end
    end
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    if visible && active
      if String === CURSOR_RECT[2]
        if Graphics.frame_count % CURSOR_RECT[4] == 0
          self.ox = (self.ox + bitmap.width / CURSOR_RECT[3]) % bitmap.width
        end
      else
        self.opacity += @blink ? -8 : 8
        @blink = true if self.opacity == 255
        @blink = false if self.opacity < 64
      end
    end
    unless @index < 0
      row = (CURSOR_TYPE == 0) ? 1 : CURSOR_TYPE
      if @index < top_row
        if CURSOR_TYPE < 2 && @index < row
          self.top_row = 0
        else
          self.top_row -= row
        end
      elsif @index > bottom_row
        if CURSOR_TYPE < 2 && @index >= @item_max - row
          self.bottom_row = @item_max / row - 1
        else
          self.bottom_row += row
        end
      else
        index = (@index - top_row) % WINDOW_POSITION.size
        self.viewport.rect.x = WINDOW_POSITION[index][0] + CURSOR_RECT[0]
        self.viewport.rect.y = WINDOW_POSITION[index][1] + CURSOR_RECT[1]
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを下に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    if CURSOR_TYPE != 0
      if (@index < @item_max - CURSOR_TYPE)
        @index = (@index + CURSOR_TYPE) % @item_max
      elsif wrap && CURSOR_TYPE != 0
        @index %= CURSOR_TYPE
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを上に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
    if CURSOR_TYPE != 0
      if (@index >= CURSOR_TYPE)
        @index = (@index - CURSOR_TYPE + @item_max) % @item_max
      elsif wrap && CURSOR_TYPE != 0
        index_max = (@item_max + (CURSOR_TYPE - @item_max % CURSOR_TYPE))
        @index = [index_max - (CURSOR_TYPE - @index), @item_max - 1].min
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    if CURSOR_TYPE != 1
      if @index < @item_max - 1 || wrap
        @index = (@index + 1) % @item_max
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    if CURSOR_TYPE != 1
      if @index > 0 || wrap
        @index = (@index - 1 + @item_max) % @item_max
      end
    end
  end
end

class Spriteset_CustomMenuStatus
  include CAO::CM::ST
  #--------------------------------------------------------------------------
  # ● オブジェクトの初期化
  #--------------------------------------------------------------------------
  def initialize
    @cursor_sprite = Sprite_MenuCursor.new
    @status_window = []
    for i in 0...[WINDOW_POSITION.size, $game_party.members.size].min
      @status_window[i] = Sprite_CustomMenuStatus.new(i)
      @status_window[i].actor = $game_party.members[i]
      @status_window[i].refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    @cursor_sprite.bitmap.dispose
    @cursor_sprite.dispose
    for window in @status_window
      window.bitmap.dispose
      window.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    last_top_row = @cursor_sprite.top_row
    @status_window.each {|w| w.update }
    @cursor_sprite.update
    refresh if @cursor_sprite.top_row != last_top_row
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    for i in 0...@status_window.size
      @status_window[i].actor = $game_party.members[@cursor_sprite.top_row+i]
      @status_window[i].refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルの可視状態の取得
  #--------------------------------------------------------------------------
  def active
    return @cursor_sprite.active
  end
  #--------------------------------------------------------------------------
  # ● カーソルの可視状態の設定
  #--------------------------------------------------------------------------
  def active=(value)
    @cursor_sprite.active = value
    @cursor_sprite.visible = value
  end
  #--------------------------------------------------------------------------
  # ● 項目の最大数の取得
  #--------------------------------------------------------------------------
  def item_max
    @cursor_sprite.item_max
  end
  #--------------------------------------------------------------------------
  # ● カーソルスプライトの取得
  #--------------------------------------------------------------------------
  def cursor_sprite(cursor_sprite = nil)
    @cursor_sprite = cursor_sprite if cursor_sprite
    return @cursor_sprite
  end
  #--------------------------------------------------------------------------
  # ● カーソル位置の取得
  #--------------------------------------------------------------------------
  def index
    return @cursor_sprite.index
  end
  #--------------------------------------------------------------------------
  # ● カーソル位置の設定
  #     index : 新しいカーソル位置
  #--------------------------------------------------------------------------
  def index=(index)
    @cursor_sprite.index = index
  end
end

class Scene_Menu < Scene_Base
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの作成
  #--------------------------------------------------------------------------
  def create_status_window
    @status_window = Spriteset_CustomMenuStatus.new
    @component[:status] = @status_window
    @component[:sta_sp] = @status_window
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
  #--------------------------------------------------------------------------
  # ○ アクター選択の開始
  #--------------------------------------------------------------------------
  alias _cao_start_actor_selection_cm_st start_actor_selection
  def start_actor_selection
    _cao_start_actor_selection_cm_st
    unless $game_party.members.size <= CAO::CM::ST::WINDOW_POSITION.size
      if $game_party.last_actor_index < CAO::CM::ST::WINDOW_POSITION.size
        @status_window.cursor_sprite.top_row = 0
      else
        row = (CAO::CM::ST::CURSOR_TYPE == 0) ? 1 : CAO::CM::ST::CURSOR_TYPE
        @status_window.cursor_sprite.top_row = [
          $game_party.last_actor_index / row,
          $game_party.members.size - CAO::CM::ST::WINDOW_POSITION.size
        ].min
      end
      @status_window.refresh
    end
  end
end
