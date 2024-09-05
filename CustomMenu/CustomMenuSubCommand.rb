#=============================================================================
#  [RGSS2] サブコマンドウィンドウ - v1.0.3
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

  メニューコマンドから呼び出せるサブコマンドの機能を追加します。
  ウィンドウは、複数設定する事が出来ます。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの動作には、Custom Menu Base が必要です。
  ※ サブコマンドからサブコマンドを呼び出すことできません。
  ※ サブコマンドからアクターの選択を行うことはできません。
  ※ 最前面に表示させるには、他のパーツより下に導入してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ サブコマンドを表示する
   Custom Menu Base の項目処理の設定
     '%start_subcommand_selection(サブコマンドID)'
     '%start_subcommand_selection(サブコマンドID, s_index)'
   ※ サブコマンドの設定で設定した COMMANDS[0] = {} の 0 の部分がIDです。
   ※ 第２引数を s_index とすると、アクターの選択を行います。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::CM::SUBCMD
  #--------------------------------------------------------------------------
  # ◇ サブコマンドの設定
  #--------------------------------------------------------------------------
  #   サンプルに倣って変更してください。
  #     COMMANDS[ＩＤ]
  #     :pos  => [ｘ座標, ｙ座標, 横幅, 文字位置 (0-2)],
  #     :text => [項目Ａ, 項目Ｂ, ...],
  #     :func => [項目Ａの処理, 項目Ｂの処理, ...],
  #     :disable => [項目Ａ処理可能？, 項目Ｂ処理可能？, ...], (省略可能)
  #--------------------------------------------------------------------------
  #   :pos の設定は、Custom Menu Base のメニュー項目名の設定と同じです。
  #     ['スクリプト', "分岐Ａ", "分岐Ｂ", "分岐Ｃ", ... ]
  #     ['$game_switches[n]', "ＯＮテキスト", "ＯＦＦテキスト"]  # スイッチ
  #     ['$game_variables[n]', "分岐 0", "分岐 1", "分岐 2"]     # ＥＶ変数
  #--------------------------------------------------------------------------
  #   :func の設定は、Custom Menu Base の項目処理の設定とほぼ同じです。
  #   ただし、Scene_Menu ではなく Windowset_MenuSubCommand で実行されます。
  #   もし、実行時に NameError, NoMethodError が発生した場合は、Scene_Menu で
  #   実行し直します。エラーメッセージに惑わされないようにご注意ください。
  #  【シーンの移動】
  #     'Scene_Item.new' など文字列で記述します。
  #     'Scene_File.new(true, false, false)' 引数の指定も同様に可能です。
  #  【スクリプトの実行】
  #     文字列の先頭に % を加えると、シーン移動を行わなずに実行します。
  #     イベント変数の操作も同様に行えます。
  #       '%add_variable_value(変数の番号, 変化範囲[, 増加値[, 初期値]])'
  #  【各ウィンドウの再描画】
  #     項目処理とは ; で区切ってください。
  #       全ウィンドウ : refresh_all      コマンド   : refresh_command
  #       ステータス   : refresh_status   オプション : refresh_option
  #  【サブコマンドを閉じる】
  #     項目処理とは ; で区切ってください。
  #       メニュー項目へ戻る : quit       アクター選択へ戻る : back
  #  【コモンイベントの実行】
  #     '%call_common(@c_index, コモンＩＤ)'
  #       メニューに戻るには、ラベルに「メニューへ戻る」と記入してください。
  #  【ステータスウィンドウの選択位置を変更】
  #     sindex(value) : value の値だけ位置を進めます。負数の場合は戻します。
  #  【その他】
  #     コマンドウィンドウのインデックスは、@c_index で取得できます。
  #     ステータスウィンドウのインデックスは、@s_index で取得できます。
  #     サブコマンドの選択項目のインデックスは、@select_id で取得できます。
  #     ※ :disable の判定では使用できません。
  #--------------------------------------------------------------------------
  COMMANDS = []   # この行は必要なものですので、削除しないでください。
  COMMANDS[0] = {
    :pos  => [160, 0, 160],
    :text => ["アイテム", "セーブ ON/OFF", "コモン１", "隊列変更禁止"],
    :func => [ 'Scene_Item.new',
              '%$game_system.save_disabled^=true;refresh_command',
              '%call_common(@c_index, 1)',
              '%$game_switches[1]=true;refresh_command;quit' ]
  }
  COMMANDS[1] = {
    :pos  => [160, 144, 160],
    :text => ["セーブ", "ロード"],
    :func => ['Scene_File.new(true, false, false)',
              'Scene_File.new(false, false, false)'],
    :disable => ['$game_system.save_disabled', false]
  }
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::CM::SUBCMD
  #--------------------------------------------------------------------------
  # ● 項目禁止判定 (禁止されている場合は、false を返す)
  #--------------------------------------------------------------------------
  def self.is_command_usable(id, index)
    return false unless Array === COMMANDS[id][:disable]
    return false unless COMMANDS[id][:disable][index]
    return eval(COMMANDS[id][:disable][index].sub(/^%/, ""))
  end
end

class Window_MenuSubCommand < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :commands                 # コマンド
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     id : ウィンドウのID
  #--------------------------------------------------------------------------
  def initialize(id)
    commands = CAO::CM::SUBCMD::COMMANDS[id][:text]
    x = CAO::CM::SUBCMD::COMMANDS[id][:pos][0]
    y = CAO::CM::SUBCMD::COMMANDS[id][:pos][1]
    width = CAO::CM::SUBCMD::COMMANDS[id][:pos][2]
    height = commands.size * WLH + 32
    align = CAO::CM::SUBCMD::COMMANDS[id][:pos][3]
    super(x, y, width, height)
    @id = id
    @commands = commands
    @item_max = commands.size
    @align = (align ? align : 0)
    refresh
    self.index = 0
    self.active = false
    self.visible = false
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
    enabled = !CAO::CM::SUBCMD.is_command_usable(@id, index)
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    self.contents.clear_rect(rect)
    self.contents.font.color = normal_color
    self.contents.font.color.alpha = enabled ? 255 : 128
    text = CAO::CM::Commands.convert_text(@commands[index])
    self.contents.draw_text(rect, text, @align)
  end
end

class Windowset_MenuSubCommand
  include CAO::CM::Commands
  include CAO::CM::SUBCMD
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :select_id                # 選択中のサブコマンド
  attr_accessor :need_back                # 戻る要求
  attr_accessor :need_close               # 閉じる要求
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    create_command_window
    @select_id = -1
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    for w in @command_windows
      w.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● 各コマンドウィンドウの生成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_windows = []
    for i in 0...COMMANDS.size
      @command_windows[i] = Window_MenuSubCommand.new(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 選択中のウィンドウを取得
  #--------------------------------------------------------------------------
  def active_window
    return @command_windows[@select_id]
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    active_window.update
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    active_window.refresh
  end
  #--------------------------------------------------------------------------
  # ● サブコマンドを表示
  #--------------------------------------------------------------------------
  def show(id, c_index, s_index)
    @c_index = c_index
    @s_index = s_index
    @select_id = id
    active_window.index = 0
    active_window.active = true
    active_window.visible = true
    active_window.refresh
  end
  #--------------------------------------------------------------------------
  # ● サブコマンドを非表示
  #--------------------------------------------------------------------------
  def close
    @need_close = false
    @need_back = false
    active_window.active = false
    active_window.visible = false
    @select_id = -1
  end
  #--------------------------------------------------------------------------
  # ● サブコマンドを閉じる要求
  #--------------------------------------------------------------------------
  def quit
    @need_close = true
  end
  #--------------------------------------------------------------------------
  # ● アクター選択へ戻る要求
  #--------------------------------------------------------------------------
  def back
    @need_back = true
  end
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの選択項目の変更
  #--------------------------------------------------------------------------
  def sindex(index)
    @s_index += index
    if @s_index < 0
      @s_index = $game_party.members.size - 1
    else
      @s_index = @s_index % $game_party.members.size
    end
    $scene.component[:status].index = @s_index
    $game_party.last_actor_index = @s_index
  end
  #--------------------------------------------------------------------------
  # ● シーンの切り替え
  #--------------------------------------------------------------------------
  def change_scene
    actor = $game_party.members[@s_index]
    expr = COMMANDS[@select_id][:func][active_window.index]
    case expr
    when /^%/
      for e in expr.sub("%", "").split(";")
        begin
          eval(e)
        rescue NameError, NoMethodError
          $scene.instance_eval(e)
        end
      end
    when String
      $scene = eval(expr)
    else
      $scene = expr.new
    end
  end
end

class Scene_Menu < Scene_Base
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_create_option_window_cm_csw create_option_window
  def create_option_window
    _cao_create_option_window_cm_csw
    @select_window = Windowset_MenuSubCommand.new
    @component[:option] << @select_window
    @component[:opt_subcmd] = @select_window
  end
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの解放
  #--------------------------------------------------------------------------
  alias _cao_dispose_option_window_cm_csw dispose_option_window
  def dispose_option_window
    _cao_dispose_option_window_cm_csw
    @select_window.dispose
  end
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの更新
  #--------------------------------------------------------------------------
  alias _cao_update_option_window_cm_csw update_option_window
  def update_option_window
    _cao_update_option_window_cm_csw
    update_subcommand_selection
  end
  #--------------------------------------------------------------------------
  # ● 追加項目選択の開始
  #--------------------------------------------------------------------------
  def start_subcommand_selection(id, s_index = -1)
    # キー入力のリセット
    Input.update
    # 設定ミスの判定 (Windowset_MenuSubCommand#show 内では異常終了)
    if SUBCMD::COMMANDS[id] == nil
      msg = "ID #{id} のサブコマンドが設定されていません。"
      raise CustomizeError, msg, __FILE__
    end
    @command_window.active = false
    @status_window.active = false
    @select_window.show(id, @command_window.index, s_index)
  end
  #--------------------------------------------------------------------------
  # ● 追加項目選択の終了
  #--------------------------------------------------------------------------
  def end_subcommand_selection
    @command_window.active = true
    @status_window.index = -1
    @select_window.close
  end
  #--------------------------------------------------------------------------
  # ● 追加項目選択の更新
  #--------------------------------------------------------------------------
  def update_subcommand_selection
    # サブコマンドが選択されていないなら処理を中断
    return if @select_window.select_id < 0
    @select_window.update
    if @select_window.need_close      # 必要ならサブコマンドを閉じる
      end_subcommand_selection
    elsif @select_window.need_back    # 必要ならアクター選択へ戻る
      @select_window.close
      start_actor_selection
    end
    if Input.trigger?(Input::B)
      Sound.play_cancel
      if @status_window.index < 0     # メニュー項目から呼ばれている
        end_subcommand_selection      # メニュー項目へ戻る
      else                            # アクター選択から呼ばれている
        @select_window.close
        start_actor_selection         # アクター選択へ戻る
      end
    elsif Input.trigger?(Input::C)
      change_scene_subcmd
    end
  end
  #--------------------------------------------------------------------------
  # ● シーンの切り替え
  #--------------------------------------------------------------------------
  def change_scene_subcmd
    id = @select_window.select_id
    index = @select_window.active_window.index
    if SUBCMD.is_command_usable(id, index)
      Sound.play_buzzer             # 項目処理が禁止されている
    else
      # 設定ミスの判定 (Windowset_MenuSubCommand#change_scene 内では異常終了)
      if @status_window.index < 0
        reg = /[\[( ,;](?:actor|@s_index)(?:[\]) ,.]|$)/
        if SUBCMD::COMMANDS[id][:func][index].match(reg)
          msg = "アクターの選択が行われていません。"
          raise CustomizeError, msg, __FILE__
        end
      end
      Sound.play_decision
      @select_window.change_scene   # 項目処理を実行
    end
  end
end
