#=============================================================================
#  [RGSS2] コマンドスプライト - v1.0.3
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

  カスタムメニューの画像を使用するメニュー項目です。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの動作には、Custom Menu Base が必要です。
  ※ 項目の設定は、Custom Menu Base で行ってください。

 -- 画像規格 ----------------------------------------------------------------

  ★ 項目画像
   項目名の画像を "Graphics/System" にご用意ください。
   ファイル名やサイズに制限はありません。
   詳細は、配布ページをご覧ください。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::CMD
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの位置
  #--------------------------------------------------------------------------
  POSITION = [
    [0, 56], [0, 88], [0, 120], [0, 152], [0, 184], [0, 216]
  ]
  #--------------------------------------------------------------------------
  # ◇ カーソルの移動距離
  #--------------------------------------------------------------------------
  CURSOR_DX = 0
  CURSOR_DY = 1
  #--------------------------------------------------------------------------
  # ◇ 項目の画像
  #--------------------------------------------------------------------------
  COMMANDS_IMAGE = "MenuCommands"
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_MenuCommand
  include CAO::CM::CMD
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  CMD_WIDTH = Cache.system(COMMANDS_IMAGE).width / 4
  CMD_HEIGHT = Cache.system(COMMANDS_IMAGE).height / POSITION.size
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :item_max                 # 項目数
  attr_reader   :index                    # カーソル位置
  attr_reader   :commands                 # コマンド
  attr_reader   :visible                  # 
  attr_accessor :active                   # 
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     commands   : コマンド文字列の配列
  #--------------------------------------------------------------------------
  def initialize(commands)
    @commands = commands
    @item_max = commands.size
    create_contents
    @active = true
    @visible = true
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def visible=(val)
    for sprite in @command_sprite
      sprite.visible = val
    end
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    for sprite in @command_sprite
      sprite.bitmap.dispose
      sprite.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の作成
  #--------------------------------------------------------------------------
  def create_contents
    @command_sprite = []
    for i in 0...@item_max
      @command_sprite[i] = Sprite.new
      @command_sprite[i].x = POSITION[i][0]
      @command_sprite[i].y = POSITION[i][1]
      @command_sprite[i].bitmap = Bitmap.new(CMD_WIDTH, CMD_HEIGHT)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動可能判定
  #--------------------------------------------------------------------------
  def cursor_movable?
    return false if (!@visible or !@active)
    return false if (@index < 0 or @index > @item_max or @item_max == 0)
    return true
  end
  #--------------------------------------------------------------------------
  # ● カーソルを下に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    @index += CURSOR_DY
    @index -= (wrap ? @item_max : CURSOR_DY) if @index >= @item_max
  end
  #--------------------------------------------------------------------------
  # ● カーソルを上に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
    @index -= CURSOR_DY
    @index += (wrap ? @item_max : CURSOR_DY) if @index < 0
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    @index += CURSOR_DX
    @index -= (wrap ? @item_max : CURSOR_DX) if @index >= @item_max
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    @index -= CURSOR_DX
    @index += (wrap ? @item_max : CURSOR_DX) if @index < 0
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
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
        draw_item(last_index)
        draw_item(@index)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソル位置の設定
  #     index : 新しいカーソル位置
  #--------------------------------------------------------------------------
  def index=(index)
    @index = index
    draw_item(@index)
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new(0, 0, CMD_WIDTH, CMD_HEIGHT)
    rect.x += CMD_WIDTH if index == @index
    rect.x += CMD_WIDTH * 2 if !CAO::CM::Commands.is_command_usable(index)
    rect.y = index * CMD_HEIGHT
    return rect
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index   : 項目番号
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    @command_sprite[index].bitmap.clear
    bitmap = Cache.system(COMMANDS_IMAGE)
    @command_sprite[index].bitmap.blt(0, 0, bitmap, item_rect(index))
  end
end

class Scene_Menu < Scene_Base
  #--------------------------------------------------------------------------
  # ○ コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_MenuCommand.new(CMD_NAME)
    @command_window.index = @menu_index
    @component[:command] = @command_window
    @component[:cmd_sp] = @command_window
  end
  #--------------------------------------------------------------------------
  # ○ コマンドウィンドウの解放
  #--------------------------------------------------------------------------
  def dispose_command_window
    @command_window.dispose
  end
  #--------------------------------------------------------------------------
  # ○ コマンドウィンドウの更新
  #--------------------------------------------------------------------------
  def update_command_window
    @command_window.update
    if @command_window.active
      update_command_selection
    elsif @status_window.active
      update_actor_selection
    end
  end
end
