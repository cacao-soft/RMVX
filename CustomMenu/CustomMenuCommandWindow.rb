#=============================================================================
#  [RGSS2] コマンドウィンドウ - v1.0.3
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

  カスタムメニューのウィンドウをベースとしたメニュー項目です。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの動作には、Custom Menu Base が必要です。
  ※ 項目の設定は、Custom Menu Base で行ってください。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::CMD
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの位置 (左上基点)
  #--------------------------------------------------------------------------
  WINDOW_X = 0    # ｘ座標
  WINDOW_Y = 0    # ｙ座標
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの横幅 (余白 32 px を含む)
  #--------------------------------------------------------------------------
  WINDOW_WIDTH  = 160
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの縦幅
  #--------------------------------------------------------------------------
  #   項目数に合わせるのなら、nil を
  #   それ以外は、縦幅を px で指定してください。
  #   入りきらなかった項目は、スクロールで表示されます。
  #   幅の算出方法としては、表示する項目数 x 24 + 32 をしてください。
  #--------------------------------------------------------------------------
  WINDOW_HEIGHT = nil

  #--------------------------------------------------------------------------
  # ◇ 項目を横に並べる数
  #--------------------------------------------------------------------------
  #   縦表示にする場合は、1 を
  #   横に並べる場合は、2 以上を設定してください。
  #   横一列で表示する場合は、最大項目数か -1 と記入してください。
  #--------------------------------------------------------------------------
  COLUMN_MAX = 1

  #--------------------------------------------------------------------------
  # ◇ 横に項目が並ぶときの空白の幅
  #--------------------------------------------------------------------------
  SPACING = 8

  #--------------------------------------------------------------------------
  # ◇ 項目の表示位置
  #--------------------------------------------------------------------------
  #   value : アラインメント (0..左揃え、1..中央揃え、2..右揃え)
  #--------------------------------------------------------------------------
  TEXT_ALIGN = 0

  #--------------------------------------------------------------------------
  # ◇ ウィンドウの表示
  #--------------------------------------------------------------------------
  #   false : ウィンドウ枠が非表示になります。
  #--------------------------------------------------------------------------
  WINDOW_DISPLAY = true

  #--------------------------------------------------------------------------
  # ◇ 項目名の左にアイコンの表示
  #--------------------------------------------------------------------------
  #   項目名順にアイコンのインデックスを設定します。
  #    例）ICON_SET = [144, 128, 40, 137, 149, 182]
  #   アイコンを表示しない場合は、空配列にしてください。
  #--------------------------------------------------------------------------
  ICON_SET = []

  #--------------------------------------------------------------------------
  # ◇ メニューコマンドの文字設定
  #--------------------------------------------------------------------------
  COMMAND_FONT = {}  # この行の設定は変更・削除しないでください。
  COMMAND_FONT[:name] = nil    # フォント名
  COMMAND_FONT[:size] = 20     # 文字サイズ
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_MenuCommand < Window_Selectable
  include CAO::CM::CMD
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :commands                 # コマンド
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     commands   : コマンド文字列の配列
  #--------------------------------------------------------------------------
  def initialize(commands)
    column_max = (COLUMN_MAX < 0 ? commands.size : COLUMN_MAX)
    row_max = (commands.size + column_max - 1) / column_max
    super(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, row_max * WLH + 32, SPACING)
    self.height = WINDOW_HEIGHT if WINDOW_HEIGHT
    self.opacity = 0 unless WINDOW_DISPLAY
    self.contents.font.name = COMMAND_FONT[:name] if COMMAND_FONT[:name]
    self.contents.font.size = COMMAND_FONT[:size]
    @commands = commands
    @item_max = commands.size
    @column_max = column_max
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    for i in 0...@item_max
      draw_item(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index   : 項目番号
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    enabled = CAO::CM::Commands.is_command_usable(index)
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    # アイコンの描画
    if ICON_SET.empty?
      rect.x += 4
      rect.width -= 8
    else
      draw_icon(ICON_SET[index], rect.x + 2, rect.y, enabled)
      rect.x += 28
      rect.width -= 30
    end
    # 項目の描画
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = enabled ? 255 : 128
    text = CAO::CM::Commands.convert_text(@commands[index])
    self.contents.draw_text(rect, text, TEXT_ALIGN)
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
    @component[:cmd_win] = @command_window
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
