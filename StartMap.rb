#=============================================================================
#  [RGSS2] スタートマップ - v1.0.0
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

  タイトル画面を表示する前に指定のマップへ飛ばします。
  イベントでタイトルの処理をすることでタイトル画面を省略できます。

 -- 注意事項 ----------------------------------------------------------------

  ※ スタートマップでは、メニューの使用が禁止されています。

 -- 使用方法 ----------------------------------------------------------------

  ★ スタートマップでの初期位置
   イベント名を 初期位置 として、イベントを配置してください。
  ※ イベントのオプションの設定は、そのままプレイヤーに適用されます。

  ★ タイトル画面の処理
   イベントコマンド「ラベル」に以下の文字を入力してください。
     <タイトル>        .. タイトル画面へ移動します。
     <ニューゲーム>    .. ニューゲームで開始します。
     <ロードゲーム>    .. ロード画面を表示します。
     <シャットダウン>  .. ゲームを終了します。

  ★ スクリプト
   以下のスクリプトは、条件分岐のスクリプトで使用できます。
     CAO::Commands.sm_continue?      # コンティニュー判定
     CAO::Commands.sm_softreset?     # リセット判定

=end


#==============================================================================
# ◆ 設定設定
#==============================================================================
module CAO
module StartMap
  
  # スタートマップのＩＤ
  START_MAP_ID = 2
  
  # パーティのアクターのＩＤ
  START_ACTOR_ID = 0
  
  # リセット時にスタートマップをスキップ
  RESET_SKIP = false
  
end # module StartMap
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Reset < Exception; end

module CAO::StartMap
  REGEXP_START = /^(?:START|初期位置)$/i
  REGEXP_TITLE = /^<タイトル>$/
  REGEXP_NEW   = /^<ニューゲーム>$/
  REGEXP_LOAD  = /^<ロードゲーム>$/
  REGEXP_END   = /^<シャットダウン>$/
end

module CAO::Commands
  module_function
  #--------------------------------------------------------------------------
  # ● コンティニュー判定
  #--------------------------------------------------------------------------
  def sm_continue?
    return Scene_Title.new.check_continue
  end
  #--------------------------------------------------------------------------
  # ● リセット判定
  #--------------------------------------------------------------------------
  def sm_softreset?
    return $!.instance_of?(Reset)
  end
  #--------------------------------------------------------------------------
  # ● スキップ判定
  #--------------------------------------------------------------------------
  def sm_skip_startmap?
    return CAO::StartMap::RESET_SKIP && sm_softreset?
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_startmap_command_118 command_118
  def command_118
    case @params[0]
    # タイトル
    when CAO::StartMap::REGEXP_TITLE
      return false if $game_message.visible
      $scene = Scene_Title.new
      $scene.start_title = true
    # ニューゲーム
    when CAO::StartMap::REGEXP_NEW
      return false if $game_message.visible
      RPG::BGM.fade(1500)
      title = Scene_Title.new
      title.load_database                           # データベースをロード
      title.create_game_objects                     # ゲームオブジェクトを作成
      title.confirm_player_location                 # 初期位置存在チェック
      $game_party.setup_starting_members            # 初期パーティ
      $game_map.setup($data_system.start_map_id)    # 初期位置のマップ
      $game_player.moveto($data_system.start_x, $data_system.start_y)
      $game_player.refresh
      $scene = Scene_Map.new
      Graphics.frame_count = 0
      Graphics.fadeout(60)
      Graphics.wait(40)
      RPG::BGM.stop
      $game_map.autoplay
    # ロードゲーム
    when CAO::StartMap::REGEXP_LOAD
      return false if $game_message.visible
      $scene = Scene_File.new(false, false, true)
    # シャットダウン
    when CAO::StartMap::REGEXP_END
      return false if $game_message.visible
      $scene = nil
    else
      _cao_startmap_command_118
    end
    return true
  end
end

class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :start_title              # タイトル画面の処理フラグ
  #--------------------------------------------------------------------------
  # ○ メイン処理
  #--------------------------------------------------------------------------
  def main
    if $BTEST
      battle_test           # 戦闘テストの開始処理
    elsif CAO::Commands.sm_skip_startmap? || @start_title
      super                 # 本来のメイン処理
    else
      start_game            # スタートマップへ移動
    end
  end
  #--------------------------------------------------------------------------
  # ● タイトル前の処理
  #--------------------------------------------------------------------------
  def start_game
    load_database           # データベースをロード
    create_game_objects     # ゲームオブジェクトを作成
    # 初期パーティ
    actor_id = CAO::StartMap::START_ACTOR_ID
    if actor_id == 0
      $game_party.instance_variable_get(:@actors).clear
    else
      $game_party.instance_variable_set(:@actors, [actor_id])
    end
    $game_map.setup(CAO::StartMap::START_MAP_ID)  # 初期マップ
    $game_player.moveto(0, 0)                     # 初期位置
    for ev in $game_map.events
      event = ev[1].instance_variable_get(:@event)
      next unless event.name[CAO::StartMap::REGEXP_START]
      ev[1].erase
      # イベントとプレイヤーを置き換える
      $game_player.moveto(event.x, event.y)
      # イベントのオプションをプレイヤーに反映
      set_start_map_player(event.pages[0])        # １ページ目
      set_start_map_player(event.pages[1])        # ２ページ目
    end
    # $game_player.refresh
    $scene = Scene_Map.new
    Graphics.frame_count = 0
    $game_map.autoplay
    $game_system.menu_disabled = true
  end
  #--------------------------------------------------------------------------
  # ● プレイヤーグラフィックの設定
  #--------------------------------------------------------------------------
  def set_start_map_player(page)
    return if page == nil
    $game_player.instance_variable_set(     # タイルＩＤ
      :@tile_id, page.graphic.tile_id)
    $game_player.instance_variable_set(     # ファイル名
      :@character_name, page.graphic.character_name)
    $game_player.instance_variable_set(     # インデックス
      :@character_index, page.graphic.character_index)
    $game_player.instance_variable_set(     # 歩行アニメ
      :@walk_anime, page.walk_anime)
    $game_player.instance_variable_set(     # 足踏みアニメ
      :@walk_anime, page.step_anime)
    $game_player.instance_variable_set(     # 向き固定
      :@direction_fix, page.direction_fix)
    $game_player.instance_variable_set(     # すり抜け
      :@through, page.through)
  end
end

class Scene_File
  #--------------------------------------------------------------------------
  # ● 元の画面へ戻る
  #--------------------------------------------------------------------------
  alias _cao_startmap_return_scene return_scene
  def return_scene
    _cao_startmap_return_scene
    $scene.start_title = true if @from_title
  end
end
