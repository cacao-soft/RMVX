#=============================================================================
#  [RGSS2] コマンドにアイコンを追加 - v1.0.1
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/mit-license.php
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- 概    要 ----------------------------------------------------------------

  タイトル、戦闘、メニューのコマンドにアイコンを表示します。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================

module CAO_COMMAND
  #--------------------------------------------------------------------------
  # ◇ アイコンインデックス
  #--------------------------------------------------------------------------
    NUMBER_ATTACKICON   = 2         # 攻撃
    NUMBER_GUARDICON    = 52        # 防御
    NUMBER_SKILLICON    = 128       # スキル
    NUMBER_ITEMICON     = 144       # アイテム
   
    NUMBER_EQUIPICON    = 40        # 装備
    NUMBER_STATUSICON   = 129       # ステータス
    NUMBER_SAVEICON     = 159       # セーブ
    NUMBER_GAMEENDICON  = 112       # やめる
    NUMBER_FIGHTICON    = 131       # 戦う
    NUMBER_ESCAPEICON   = 136       # 逃げる
    
    NUMBER_NEWGAMEICON  = 153       # ニューゲーム
    NUMBER_CONTINUEICON = 154       # コンティニュー
    NUMBER_SHUTDOWNICON = 155       # シャットダウン
    
    NUMBER_GOLDICON     = 147       # ゴールド
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


#==============================================================================
# ■ Window_Command
#------------------------------------------------------------------------------
# 　一般的なコマンド選択を行うウィンドウです。
#==============================================================================

class Window_Command < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #     index   : 項目番号
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item(index, enabled = true)
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    self.contents.clear_rect(rect)
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = enabled ? 255 : 128
    
    # 描画する項目の先頭に"<番号>"が含まれているなら
    if @commands && /^<(\d+)>/ =~ @commands[index].to_s
      # 項目の左にアイコンを追加
      draw_icon($1.to_i, rect.x, rect.y, enabled)
      # アイコン分ずらす
      rect.x += 26
      rect.width -= 26
      # 項目を描画
      self.contents.draw_text(rect, $')
    else
      # そのまま描画
      self.contents.draw_text(rect, commands[index])
    end
  end
end
#==============================================================================
# ■ Window_Base
#------------------------------------------------------------------------------
# 　ゲーム中のすべてのウィンドウのスーパークラスです。
#==============================================================================

class Window_Base < Window
  #--------------------------------------------------------------------------
  # ● 通貨単位つきの数値描画
  #     value : 数値 (所持金など)
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_currency_value(value, x, y, width)
    width -= 24
    draw_icon(CAO_COMMAND::NUMBER_GOLDICON, x, y)
    cx = contents.text_size(Vocab::gold).width
    self.contents.font.color = normal_color
    self.contents.draw_text(x + 24, y, width-cx-2, WLH, value, 2)
    self.contents.font.color = system_color
    self.contents.draw_text(x + 24, y, width, WLH, Vocab::gold, 2)
  end
end
#==============================================================================
# ■ Window_PartyCommand
#------------------------------------------------------------------------------
# 　バトル画面で、戦うか逃げるかを選択するウィンドウです。
#==============================================================================

class Window_PartyCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    s1 = "<#{CAO_COMMAND::NUMBER_FIGHTICON}>#{Vocab::fight}"
    s2 = "<#{CAO_COMMAND::NUMBER_ESCAPEICON}>#{Vocab::escape}"
    super(128, [s1, s2], 1, 4)
    draw_item(0, true)
    draw_item(1, $game_troop.can_escape)
    self.active = false
  end
end
#==============================================================================
# ■ Window_ActorCommand
#------------------------------------------------------------------------------
# 　バトル画面で、戦うか逃げるかを選択するウィンドウです。
#==============================================================================

class Window_ActorCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● セットアップ
  #     actor : アクター
  #--------------------------------------------------------------------------
  def setup(actor)
    s1 = "<#{CAO_COMMAND::NUMBER_ATTACKICON}>#{Vocab::attack}"
    s2 = "<#{CAO_COMMAND::NUMBER_SKILLICON}>#{Vocab::skill}"
    s3 = "<#{CAO_COMMAND::NUMBER_GUARDICON}>#{Vocab::guard}"
    s4 = "<#{CAO_COMMAND::NUMBER_ITEMICON}>#{Vocab::item}"
    if actor.class.skill_name_valid     # スキルのコマンド名が有効？
      s2 = actor.class.skill_name       # コマンド名を置き換える
    end
    @commands = [s1, s2, s3, s4]
    @item_max = 4
    refresh
    self.index = 0
  end
end
#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　タイトル画面の処理を行うクラスです。
#==============================================================================

class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    s1 = "<#{CAO_COMMAND::NUMBER_NEWGAMEICON}>#{Vocab::new_game}"
    s2 = "<#{CAO_COMMAND::NUMBER_CONTINUEICON}>#{Vocab::continue}"
    s3 = "<#{CAO_COMMAND::NUMBER_SHUTDOWNICON}>#{Vocab::shutdown}"
    @command_window = Window_Command.new(172, [s1, s2, s3])
    @command_window.x = (544 - @command_window.width) / 2
    @command_window.y = 288
    if @continue_enabled                    # コンティニューが有効な場合
      @command_window.index = 1             # カーソルを合わせる
    else                                    # 無効な場合
      @command_window.draw_item(1, false)   # コマンドを半透明表示にする
    end
    @command_window.openness = 0
    @command_window.open
  end
end
#==============================================================================
# ■ Scene_Menu
#------------------------------------------------------------------------------
# 　メニュー画面の処理を行うクラスです。
#==============================================================================

class Scene_Menu < Scene_Base
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    s1 = "<#{CAO_COMMAND::NUMBER_ITEMICON}>#{Vocab::item}"
    s2 = "<#{CAO_COMMAND::NUMBER_SKILLICON}>#{Vocab::skill}"
    s3 = "<#{CAO_COMMAND::NUMBER_EQUIPICON}>#{Vocab::equip}"
    s4 = "<#{CAO_COMMAND::NUMBER_STATUSICON}>#{Vocab::status}"
    s5 = "<#{CAO_COMMAND::NUMBER_SAVEICON}>#{Vocab::save}"
    s6 = "<#{CAO_COMMAND::NUMBER_GAMEENDICON}>#{Vocab::game_end}"
    @command_window = Window_Command.new(160, [s1, s2, s3, s4, s5, s6])
    @command_window.index = @menu_index
    if $game_party.members.size == 0          # パーティ人数が 0 人の場合
      @command_window.draw_item(0, false)     # アイテムを無効化
      @command_window.draw_item(1, false)     # スキルを無効化
      @command_window.draw_item(2, false)     # 装備を無効化
      @command_window.draw_item(3, false)     # ステータスを無効化
    end
    if $game_system.save_disabled             # セーブ禁止の場合
      @command_window.draw_item(4, false)     # セーブを無効化
    end
  end
end
