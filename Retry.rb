#=============================================================================
#  [RGSS2] リトライ機能 - v1.0.1
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

  戦闘中にゲームオーバーになっても戦闘をやり直せる機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 他の素材スクリプトより上に導入してください。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   このスクリプトには設定項目はありません。                  #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class RetryFile < Scene_File
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  FILE_RETRY = "retry"
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● セーブの実行
  #--------------------------------------------------------------------------
  def do_save
    File.open(FILE_RETRY, "wb") {|file| write_save_data(file) }
  end
  #--------------------------------------------------------------------------
  # ● ロードの実行
  #--------------------------------------------------------------------------
  def do_load
    File.open(FILE_RETRY, "rb") {|file| read_save_data(file) }
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  class << self
    def save
      self.new.do_save
    end
    def load
      self.new.do_load
    end
    def delete
      File.delete(FILE_RETRY) rescue nil
    end
  end
end

class Scene_Battle
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  alias _cao_retry_start start
  def start
    _cao_retry_start
    RetryFile.save
  end
  #--------------------------------------------------------------------------
  # ○ ゲームオーバー画面への切り替え
  #--------------------------------------------------------------------------
  def call_gameover
    $game_temp.next_scene = nil
    $scene = Scene_Gameover.new
    $scene.in_battle = true
    @message_window.clear
  end
end

class Scene_Gameover
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  RETRY_COMMANDS = ["リトライ", "タイトル", "やめる"]
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :in_battle                # 戦闘で敗北
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  alias _cao_retry_start start
  def start
    _cao_retry_start
    create_command_window
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    case @command_window.index
    when 0
      RetryFile.load
      $game_temp.next_scene = nil
      RPG::BGM.stop
      RPG::BGS.stop
      RPG::ME.stop
      # Sound.play_battle_start
      $game_system.battle_bgm.play
      $scene = Scene_Battle.new
    when 2
      $scene = nil
    else
      $scene = Scene_Title.new
      $scene = nil if $BTEST
    end
    dispose_gameover_graphic
    dispose_command_window
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_Command.new(172, RETRY_COMMANDS)
    @command_window.x = (Graphics.width - @command_window.width) / 2
    @command_window.y = Graphics.height / 2
    @command_window.openness = 0
    @command_window.open if @in_battle
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの解放
  #--------------------------------------------------------------------------
  def dispose_command_window
    @command_window.dispose
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if @in_battle
      @command_window.update
      update_command_selection
      if @command_window.openness == 0
        $scene = nil
        Graphics.fadeout(60)
      end
    elsif Input.trigger?(Input::C)
      @command_window.index = -1
      $scene = nil
      Graphics.fadeout(120)
    end
  end
  #--------------------------------------------------------------------------
  # ● コマンド選択の更新
  #--------------------------------------------------------------------------
  def update_command_selection
    return if @command_window.openness != 255
    if Input.trigger?(Input::C)
      Sound.play_decision
      @command_window.close
    end
  end
end