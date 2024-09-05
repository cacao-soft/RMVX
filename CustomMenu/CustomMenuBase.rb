#=============================================================================
#  [RGSS2] Custom Menu Base - v2.2.1
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

  カスタムメニューのベーススクリプトです。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトは、なるべく下のほうのに導入してください。
  ※ カスタムメニュー関連のスクリプトより上に導入してください。
  ※ コマンドとステータスのスクリプトを必ず導入してください。
  ※ メニュー項目を変更するには、以下の設定を変更する必要があります。
      １．メニュー項目名  ２．項目処理  ３．システム項目  ４．禁止処理

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
module CM
  #--------------------------------------------------------------------------
  # ◇ メニュー項目名
  #--------------------------------------------------------------------------
  #   ここで記述したとおりに項目が並びます。
  #     ['スクリプト', "分岐Ａ", "分岐Ｂ", "分岐Ｃ", ... ]
  #     ['$game_switches[n]', "ＯＮテキスト", "ＯＦＦテキスト"]  # スイッチ
  #     ['$game_variables[n]', "分岐 0", "分岐 1", "分岐 2"]     # ＥＶ変数
  #--------------------------------------------------------------------------
  CMD_NAME = [
    "アイテム",
    "スキル",
    "装備",
    "ステータス",
    "セーブ",
    "ゲーム終了"
  ]

  #--------------------------------------------------------------------------
  # ◇ 項目処理
  #--------------------------------------------------------------------------
  #   項目を決定した場合に行う処理です。
  #   文字列で処理を記述します。（インスタンス生成：シーンクラス.new）
  #   また、呼び出しメソッドが用意されている場合も、文字列で記述します。
  #   シーン切り替えが定義されていない場合は、先頭に % を入れます。
  #   アクター選択を行う場合は、先頭に & を入れます。
  #  【コモンイベントの実行】
  #     "%Commands.call_common(c_index, コモンＩＤ)"
  #       メニューに戻るには、ラベルに「メニューへ戻る」と記入する。
  #  【イベント変数の増加】
  #     "%Commands.add_variable_value(変数の番号, 変化範囲[, 増加値[, 初期値]])"
  #  【各ウィンドウの再描画】
  #     項目処理とは ; で区切ってください。
  #       全ウィンドウ : Commands.refresh_all
  #       コマンド     : Commands.refresh_command
  #       ステータス   : Commands.refresh_status
  #       オプション   : Commands.refresh_option
  #   次のように置き換えて記述する事もできます。
  #     actor   : $game_party.members[@status_window.index]
  #     c_index : @command_window.index
  #     s_index : @status_window.index
  #--------------------------------------------------------------------------
  CMD_SCENE = [
    "Scene_Item.new",
    "Scene_Skill.new(s_index)",
    "Scene_Equip.new(s_index)",
    "Scene_Status.new(s_index)",
    "Scene_File.new(true, false, false)",
    "Scene_End.new"
  ]

  #--------------------------------------------------------------------------
  # ◇ システム項目
  #--------------------------------------------------------------------------
  #   パーティが０人でも使用できる項目かを設定します。
  #   true で選択可、false で選択不可
  #--------------------------------------------------------------------------
  CMD_SYSTEM = [false, false, false, false, true, true]

  #--------------------------------------------------------------------------
  # ◇ 禁止処理
  #--------------------------------------------------------------------------
  #   項目が選択禁止かを判定するための変数を文字列で指定します。
  #   判定しない場合は、true で常に禁止、false で常に許可します。
  #--------------------------------------------------------------------------
  CMD_DISABLE = [
    false, false, false, false, "$game_system.save_disabled", false
  ]

  #--------------------------------------------------------------------------
  # ◇ １人メニュー
  #--------------------------------------------------------------------------
  #   true  : メニューでアクター選択を行いません。
  #   false : 通常通りアクター選択を行います。
  #--------------------------------------------------------------------------
  SOLO_MENU = false

  #--------------------------------------------------------------------------
  # ◇ 背景画像
  #--------------------------------------------------------------------------
  #   メニュー全体の背景の設定です。
  #   使用しない場合の値は、"" で、マップ画像を表示します。
  #--------------------------------------------------------------------------
  BACKGROUND_IMAGE = ""

  #--------------------------------------------------------------------------
  # ◇ サイドメニュー
  #--------------------------------------------------------------------------
  #   項目選択の時に指定したボタンを押すと、処理を開始します。
  #--------------------------------------------------------------------------
  SIDE_KEY = nil    # ボタンの種類（Input::A）
  SIDE_SCENE = ""   # 実行する処理（Scene_Debug.new）
end
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class CustomizeError < StandardError; end

module CAO::CM::Commands
  include CAO::CM
  module_function
  #--------------------------------------------------------------------------
  # ● 項目禁止判定 (禁止されている場合は、false を返す)
  #--------------------------------------------------------------------------
  def is_command_usable(index)
    # パーティ人数が 0 人の場合
    if $game_party.members.size == 0 && !CMD_SYSTEM[index]
      return false
    end
    # 禁止の場合
    if String === CMD_DISABLE[index] && eval(CMD_DISABLE[index])
      return false
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● コモンイベントの呼び出し予約
  #--------------------------------------------------------------------------
  def call_common(c_index, event_id)
    $game_temp.last_menu_index = c_index    # 戻り位置
    $game_temp.common_event_id = event_id   # コモン予約
    $scene = Scene_Map.new                  # シーン切り替え
  end
  #--------------------------------------------------------------------------
  # ● スイッチの値でテキストを変化
  #--------------------------------------------------------------------------
  #     nember : スイッチの番号または、ブール型
  #     t1     : スイッチがＯＮの時のテキスト
  #     t2     : スイッチがＯＦＦの時のテキスト
  #--------------------------------------------------------------------------
  def set_switche_text(number, t1, t2)
    if number.is_a?(Integer)
      return $game_switches[number] ? t1 : t2
    else
      return number ? t1 : t2
    end
  end
  #--------------------------------------------------------------------------
  # ● 変数の値でテキストを変化
  #--------------------------------------------------------------------------
  #     nember : 変数の番号または、数値
  #     text   : テキスト配列
  #     event  : イベント変数なら "ture", 変数の値なら "false"
  #--------------------------------------------------------------------------
  def set_variable_text(number, text, event = true)
    if event
      return text[$game_variables[number]]
    else
      return text[number]
    end
  end
  #--------------------------------------------------------------------------
  # ● 変数の値を増加
  #--------------------------------------------------------------------------
  #     nember : 変数の番号
  #     size   : 変数を増加させる範囲(例：０～３の場合は、４となる。)
  #     value  : 増加させる数値
  #     start  : 最初の数値
  #--------------------------------------------------------------------------
  def add_variable_value(number, size, value = 1, start = 0)
    $game_variables[number] += value
    if $game_variables[number] >= size
      $game_variables[number] = start
    end
  end
  #--------------------------------------------------------------------------
  # ● 文字列の変換
  #--------------------------------------------------------------------------
  #     text : スクリプトの可能性がある文字列
  #--------------------------------------------------------------------------
  def convert_text(text)
    if Array === text
      value = eval(text[0].sub(/^%/, ""))
      text = (Fixnum === value ? text[value + 1] : text[value ? 1 : 2])
    end
    return eval(text.sub(/^%/, "")) if text.match(/^%/)
    return text
  end
  #--------------------------------------------------------------------------
  # ● 項目名にスクリプトを使用しているか。
  #--------------------------------------------------------------------------
  #     index : カーソル位置
  #--------------------------------------------------------------------------
  def use_command_script?(index)
    return true if Array === CMD_NAME[index]
    return true if CMD_NAME[index].match(/^%/)
    return false
  end
  #--------------------------------------------------------------------------
  # ● 全コンポーネントの再描画
  #--------------------------------------------------------------------------
  def refresh_all
    refresh_command
    refresh_status
    refresh_option
  end
  #--------------------------------------------------------------------------
  # ● 全メニューコマンドの再描画
  #--------------------------------------------------------------------------
  def refresh_command
    $scene.component[:command].refresh
  end
  #--------------------------------------------------------------------------
  # ● 全メニューステータスの再描画
  #--------------------------------------------------------------------------
  def refresh_status
    $scene.component[:status].refresh
  end
  #--------------------------------------------------------------------------
  # ● 全オプションの再描画
  #--------------------------------------------------------------------------
  def refresh_option
    for obj in $scene.component[:option]
      if Array === obj
        obj.each {|o| o.refresh }
      else
        obj.refresh
      end
    end
  end
end

class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :last_menu_index          # カーソル記憶用：メニュー
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_cm initialize
  def initialize
    _cao_initialize_cm
    @last_menu_index = -1
  end
end

class Game_Interpreter
  include CAO::CM::Commands
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_cm command_118
  def command_118
    if /^メニューへ戻る(?:\((\d+)\))?/ =~ @params[0]
      return false if $game_message.visible
      if $1.nil?
        $scene = Scene_Menu.new($game_temp.last_menu_index)
      else
        $game_temp.last_menu_index = -1
        $scene = Scene_Menu.new($1.to_i)
      end
      clear
    else
      return _cao_command_118_cm
    end
    return true
  end
end

class Scene_Menu
  include CAO::CM
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :component                # 構成オブジェクト
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     menu_index : コマンドのカーソル初期位置
  #--------------------------------------------------------------------------
  def initialize(menu_index = 0)
    if $game_temp.last_menu_index < 0
      @menu_index = [0, [menu_index, CMD_NAME.size-1].min].max
    else
      @menu_index = $game_temp.last_menu_index
    end
  end
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    @component = {}
    @component[:option] = []
    create_menu_background
    create_command_window
    create_status_window
    create_option_window
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    if $scene.is_a?(Scene_Map) && $game_temp.common_event_id <= 0
      $game_temp.last_menu_index = -1
    else
      $game_temp.last_menu_index = @command_window.index
    end
    super
    dispose_menu_background
    dispose_command_window
    dispose_status_window
    dispose_option_window
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    update_command_window
    update_status_window
    update_option_window
  end
  #--------------------------------------------------------------------------
  # ○ メニュー画面系の背景作成
  #--------------------------------------------------------------------------
  def create_menu_background
    @menuback_sprite = Sprite.new
    if BACKGROUND_IMAGE == ""
      @menuback_sprite.bitmap = $game_temp.background_bitmap
      @menuback_sprite.color.set(16, 16, 16, 128)
    else
      @menuback_sprite.bitmap = Cache.system(BACKGROUND_IMAGE)
    end
    update_menu_background
  end
  #--------------------------------------------------------------------------
  # ○ コマンド選択の更新
  #--------------------------------------------------------------------------
  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      # パーティが０のとき
      unless Commands.is_command_usable(@command_window.index)
        Sound.play_buzzer
        return
      end
      # 項目処理の実行
      Sound.play_decision
      cmd = CMD_SCENE[@command_window.index]
      reg = /[\[( ,](?:actor|s_index|@status_window.index)(?:[\]) ,.]|$)/
      if cmd.match(/^&/) || cmd.match(reg)
        if SOLO_MENU && $game_party.members.size == 1
          change_scene(0)
        else
          start_actor_selection
        end
      else
        change_scene
      end
      # 項目名にスクリプトを使っている
      if Commands.use_command_script?(@command_window.index)
        @command_window.draw_item(@command_window.index)
      end
    end
    # サイドキーの処理を実行
    if SIDE_KEY != nil && Input.trigger?(SIDE_KEY)
      case SIDE_SCENE
      when /^%/
        eval(SIDE_SCENE.sub(/^%/, ""))
      when String
        $scene = eval(SIDE_SCENE)
      else
        msg = "(サイドキー) 項目処理の設定は文字列で行ってください。"
        raise CustomizeError, msg, __FILE__
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● シーンの切り替え
  #--------------------------------------------------------------------------
  def change_scene(s_index = nil)
    c_index = @command_window.index
    s_index = @status_window.index if s_index.nil?
    actor = $game_party.members[s_index]
    case CMD_SCENE[@command_window.index]
    when /^%/
      eval(CMD_SCENE[@command_window.index].sub("%", ""))
    when /^&/
      eval(CMD_SCENE[@command_window.index].sub("&", ""))
    when String
      $scene = eval(CMD_SCENE[@command_window.index])
    else
      msg = "項目処理の設定は文字列で行ってください。"
      raise CustomizeError, msg, __FILE__
    end
  end
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの作成
  #--------------------------------------------------------------------------
  def create_option_window
  end
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの解放
  #--------------------------------------------------------------------------
  def dispose_option_window
  end
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの更新
  #--------------------------------------------------------------------------
  def update_option_window
  end
  #--------------------------------------------------------------------------
  # ○ アクター選択の更新
  #--------------------------------------------------------------------------
  def update_actor_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      end_actor_selection
    elsif Input.trigger?(Input::C)
      $game_party.last_actor_index = @status_window.index
      Sound.play_decision
      change_scene
    end
  end
end

module CAO::CM::MenuStatusBack
  #--------------------------------------------------------------------------
  # ○ 背景画像の生成
  #--------------------------------------------------------------------------
  def create_background
    @back_sprite = Sprite.new
    @back_sprite.x = self.x
    @back_sprite.y = self.y
    @back_sprite.bitmap = Cache.system(CAO::CM::ST::BACKGROUND_IMAGE)
  end
  #--------------------------------------------------------------------------
  # ○ 背景画像の解放
  #--------------------------------------------------------------------------
  def dispose_background
    @back_sprite.dispose if @back_sprite
  end
  #--------------------------------------------------------------------------
  # ○ 解放
  #--------------------------------------------------------------------------
  def dispose
    dispose_background
    super
  end
  #--------------------------------------------------------------------------
  # ◎ x
  #--------------------------------------------------------------------------
  def x=(value)
    super
    @back_sprite.x = self.x if @back_sprite
  end
  #--------------------------------------------------------------------------
  # ◎ y
  #--------------------------------------------------------------------------
  def y=(value)
    super
    @back_sprite.y = self.y if @back_sprite
  end
  #--------------------------------------------------------------------------
  # ◎ 非表示
  #--------------------------------------------------------------------------
  def visible=(value)
    super
    @back_sprite.visible = value if @back_sprite
  end
end
