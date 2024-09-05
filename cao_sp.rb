#==============================================================================
# ■ RPGツクールVX Fan Patch - 2011.11.11
#------------------------------------------------------------------------------
#   プリセットスクリプトの不都合を修正します。
#   不具合でなくとも問題のある処理は修正しています。
#   また、不具合と思える処理でも仕様と割り切れるものは修正していません。
#==============================================================================


#------------------------------------------------------------------------------
# 【はじめに】
#------------------------------------------------------------------------------
# ■ このスクリプトは、VX_SP2 のすぐ下に導入して下さい。
#    再定義を多用していますので、他スクリプトより上に導入する必要があります。
# ■ このスクリプトに限り、転載・再配布・改変・改変物の配布を許可しています。
#    積極的に情報を広めていただければと思います。
# ■ メソッドのマークの意味は次の通りです。
#     ● 新しく定義  ○ 再定義  ◎ オーバーライド (新しく追加したもの)
# ■ 修正内容ごとに番号を付けていますので、スクリプトを確認したいときや
#    修正を無効にしたいときなどは、『# 番号』で検索してください。
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 【修正内容】
#------------------------------------------------------------------------------
# [01]【重要】オブジェクトＩＤを取得するメソッド id の定義を取り消しました。
# [02] Color と Rect と Tone を自身のクラス以外のオブジェクトと == で比較すると
#      エラーが出る不都合を修正しました。
# [03] Plane クラスの viewport と viewport= メソッドを使用した際にエラーが出る
#      不都合をなんとかしました。
# [04] Viewport#disposed? を使用した際にエラーが出る不都合をなんとかしました。
# [05] Tilemap#visible で、タイルが非表示にならない不都合をなんとかしました。
# [06] Bitmap#gradient_fill_rect(x,y,width,height,color1,color2[,vertical]) の
#      引数 vertical が無視される不都合をなんとかしました。
# [07] Bitmap.new(width,height) で、16 MBより大きい画像を作るとエラーになる
#      不都合をなんとかしました。(一時ファイルを介して作成するように変更)
# [08] アイテム・スキル・ターゲットウィンドウを開いた状態で戦闘の中断を行うと
#      それらのウィンドウが表示されたままになってしまう不都合を修正しました。
# [09] スキル選択画面でＬＲボタンの操作が重複している不都合を修正しました。
#      "アクター切り替え"と"ページ送り"のうち『アクター切り替え』を当てました。
# [10] スキル画面のビューポートの解放し忘れを修正しました。
# [11] ステートＡの解除ステートにステートＢが含まれていても、
#      ステートＢ付加の成功メッセージが表示される不都合を修正しました。
# [12] アイテムでの能力アップを回復処理より先に処理するように修正しました。
# [13]『プレイヤーの方/逆を向く』の処理で対象となるイベントとプレイヤーとの
#      座標差が同値の場合に向き変更を行わない不都合を修正しました。
# [14]『移動ルートの設定：グラフィックの変更』でプレイヤーの歩行グラを変更すると
#      アクターのグラフィック変更やパーティ変更後に歩行グラが元に戻ってしまう
#      不都合を修正しました。(更新のタイミングは、先頭アクターが変更された時)
# [15] イベントコマンドで戦闘不能の敵にステートを付加すると
#      消滅アニメーションが再表示される不都合を修正しました。
# [16] 逃走した敵にステートが付いていると可視状態になる不都合を修正しました。
#      見えていない敵のステートのメッセージは表示しないように変更しています。
# [17] アイテムが使用可能かの判定で、ステート付加に失敗すると使用不可と
#      判断されてしまう不都合を修正しました。
#      (ステートの変化に失敗しても、アイテムが消費されるようになります。)
# [18]『移動ルートの設定：ジャンプ』で正しく向き変更しない不都合を修正しました。
# [19]『移動ルートの設定：ジャンプ』の処理が
#      マップスクロール(ループ)に対応していない不都合を修正しました。
# [20] マップスクロール(ループ)の境界線を挟むと
#      イベントが正しく向き変更しない不都合を修正しました。
# [21]『天候エフェクトの設定』の雪が、雪に見えない不都合を修正しました。
# [22] ステート『戦闘不能』のメッセージが空だと敵を倒しても、
#      敵グラフィックが消えない不都合を修正しました。
# [23] スキルの使用可能判定で、スキルのオブジェクトか判別されずに処理されている
#      不都合を修正しました。
# [24] Window_SaveFile#draw_playtime(x, y, width, align) の引数 align が
#      無視される不都合を修正しました。
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 【そのほか】
#------------------------------------------------------------------------------
# ■ イベントの実行後にエンカウントを発生させたくない。
# □ エンカウントを発生させたくないイベントで次のスクリプトを実行してください。
#    エンカウントが発生する場合、カウント数を１にして次の一歩で発生させます。
#~ if $game_player.encounter_count < 1
#~   $game_player.instance_variable_set(
#~     :@encounter_count, 1
#~   )
#~ end
# ■ ヘルプ RPG::Enemy#element_ranks, RPG::Enemy#state_ranks の有効度
# □ 一次元配列 (Table) .. (1:A、2:B、3:C、4:D、5:E、6:F)
#------------------------------------------------------------------------------


$CAO_SP = true          # CAO_SP 導入フラグ
alias $cao_sp $CAO_SP   # <obsolete>

module Kernel
  #--------------------------------------------------------------------------
  # ● メソッドの定義を確認後エイリアス
  #--------------------------------------------------------------------------
  def alias_once(new, old)
    return if public_method_defined?(new)
    return if private_method_defined?(new)
    instance_eval("alias_method(:#{new}, :#{old})")
  end
  alias once_alias alias_once   # <obsolete>
end

# 01
class Object
  #--------------------------------------------------------------------------
  # ● メソッド定義の取り消し
  #--------------------------------------------------------------------------
  undef id rescue nil
end

# 02
class Rect
  alias_once :_cao_sp_equate?, :==
  def ==(other)
    return other.is_a?(Rect) && _cao_sp_equate?(other)
  end
end
class Color
  alias_once :_cao_sp_equate?, :==
  def ==(other)
    return other.is_a?(Color) && _cao_sp_equate?(other)
  end
end
class Tone
  alias_once :_cao_sp_equate?, :==
  def ==(other)
    return other.is_a?(Tone) && _cao_sp_equate?(other)
  end
end

# 06
class Bitmap
  #--------------------------------------------------------------------------
  # ○ 矩形をグラデーションで塗り潰す
  #--------------------------------------------------------------------------
  alias_once :_cao_sp_gradient_fill_rect, :gradient_fill_rect
  def gradient_fill_rect(*args)
    if (6..7) === args.size
      x, y, width, height, color1, color2, vertical = args
      rect = Rect.new(x, y, width, height)
      _cao_sp_gradient_fill_rect(rect, color1, color2, vertical)
    else
      _cao_sp_gradient_fill_rect(*args)
    end
  rescue => error
    raise error.class, error.message, caller.first
  end
end

# 07
class << Bitmap
  #--------------------------------------------------------------------------
  # ○ Bitmap オブジェクトを生成
  #--------------------------------------------------------------------------
  alias_once :_cao_sp_new, :new
  def new(*args)
    if args.size == 2
      if args[0] * args[1] <= 0
        msg = "zero or negative bitmap size"
        raise ArgumentError, msg, caller.first
      elsif args[0] * args[1] > 4194304
        return create_large_bitmap(args[0], args[1])
      end
    end
    return _cao_sp_new(*args)
  rescue => error
    raise error.class, error.message, caller.first
  end
  private
  #--------------------------------------------------------------------------
  # ● 一時ファイルを介して、Bitmap オブジェクトを生成
  #     width  : ビットマップの幅
  #     height : ビットマップの高さ
  #--------------------------------------------------------------------------
  def create_large_bitmap(width, height)
    # 識別
    sgnt = "\x89PNG\r\n\x1a\n"
    # ヘッダ
    ihdr = chunk('IHDR', [width, height, 1, 0, 0, 0, 0].pack('N2C5'))
    # 画像データ
    data = (1 + (width + (8 - width % 8) % 8) / 8) * height
    idat = chunk('IDAT', Zlib::Deflate.deflate("\0" * data))
    # 終端
    iend = chunk('IEND', "")
    # ファイルに書き出す
    filename = "tmp"
    File.open(filename, 'wb') do |file|
      file.write(sgnt)
      file.write(ihdr)
      file.write(idat)
      file.write(iend)
    end
    # Bitmap オブジェクトを生成
    bmp = Bitmap.new(filename)
    bmp.clear
    File.delete(filename) rescue nil
    return bmp
  end
  #--------------------------------------------------------------------------
  # ● チャンクの作成
  #     name : チャンク名
  #     data : データ
  #--------------------------------------------------------------------------
  def chunk(name, data)
    return [data.size, name, data, Zlib.crc32(name + data)].pack('NA4A*N')
  end
end

# 03
class Plane
  #--------------------------------------------------------------------------
  # ● 別名定義
  #--------------------------------------------------------------------------
  alias_once :_cao_sp_initialize, :initialize   # オブジェクトの初期化
  alias_once :set_viewport, :viewport           # ビューポートの割り当て
  #--------------------------------------------------------------------------
  # ○ オブジェクトの初期化
  #--------------------------------------------------------------------------
  def initialize(v = nil)
    @viewport = v
    _cao_sp_initialize(v)
  end
  #--------------------------------------------------------------------------
  # ○ ビューポートの取得
  #--------------------------------------------------------------------------
  def viewport
    raise RGSSError, "disposed plane", caller if self.disposed?
    return @viewport
  end
  #--------------------------------------------------------------------------
  # ● ビューポートの設定
  #--------------------------------------------------------------------------
  def viewport=(v)
    raise RGSSError, "disposed plane", caller if self.disposed?
    @viewport = set_viewport(v)
  end
end

# 04
class Viewport
  #--------------------------------------------------------------------------
  # ● ビューポートの有無
  #--------------------------------------------------------------------------
  def disposed?
    begin
      self.visible
    rescue RGSSError
      return true
    end
    return false
  end
end

# 05
class Tilemap
  #--------------------------------------------------------------------------
  # ● 別名定義
  #--------------------------------------------------------------------------
  alias_once :_cao_sp_dispose,   :dispose     # オブジェクトの解放
  alias_once :_cao_sp_viewport,  :viewport    # ビューポートの取得
  alias_once :_cao_sp_viewport=, :viewport=   # ビューポートの設定
  alias_once :_cao_sp_visible=,  :visible=    # 可視状態の設定
  #--------------------------------------------------------------------------
  # ○ 解放
  #--------------------------------------------------------------------------
  def dispose
    @hide_viewport.dispose if @hide_viewport
    self._cao_sp_dispose
  end
  #--------------------------------------------------------------------------
  # ○ ビューポートの取得
  #--------------------------------------------------------------------------
  def viewport
    raise RGSSError, "disposed tilemap", caller if self.disposed?
    return @last_viewport unless self.visible
    return self._cao_sp_viewport
  end
  #--------------------------------------------------------------------------
  # ○ ビューポートの設定
  #--------------------------------------------------------------------------
  def viewport=(v)
    raise RGSSError, "disposed tilemap", caller if self.disposed?
    if self.visible
      self._cao_sp_viewport = v
    else
      @last_viewport = v
    end
  end
  #--------------------------------------------------------------------------
  # ○ 可視状態の設定
  #--------------------------------------------------------------------------
  def visible=(value)
    raise RGSSError, "disposed tilemap", caller if self.disposed?
    @hide_viewport ||= Viewport.new(0, 0, 32, 32)
    @last_viewport ||= self._cao_sp_viewport
    if value
      self._cao_sp_viewport = @last_viewport
    else
      self._cao_sp_viewport = @hide_viewport
      @hide_viewport.visible = false
    end
    self._cao_sp_visible = value
  end
end

# 08
class Scene_Battle
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  alias _cao_sp_terminate terminate
  def terminate
    _cao_sp_terminate
    @target_actor_window.dispose if @target_actor_window
    @target_enemy_window if @target_enemy_window
    @help_window.dispose if @help_window
    @skill_window.dispose if @skill_window
    @item_window.dispose if @item_window
  end
end

# 09
class Window_Skill
  #--------------------------------------------------------------------------
  # ◎ カーソルを 1 ページ後ろに移動
  #--------------------------------------------------------------------------
  alias_once :_cao_sp_cursor_pagedown, :cursor_pagedown
  def cursor_pagedown
    return if $scene.is_a?(Scene_Skill)
    _cao_sp_cursor_pagedown
  end
  #--------------------------------------------------------------------------
  # ◎ カーソルを 1 ページ前に移動
  #--------------------------------------------------------------------------
  alias_once :_cao_sp_cursor_pageup, :cursor_pageup
  def cursor_pageup
    return if $scene.is_a?(Scene_Skill)
    _cao_sp_cursor_pageup
  end
end

# 10
class Scene_Skill
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  alias _cao_sp_terminate terminate
  def terminate
    _cao_sp_terminate
    @viewport.dispose
  end
end

# 11
class Game_Battler
  #--------------------------------------------------------------------------
  # ○ ステート無効化判定
  #     state_id : ステート ID
  #--------------------------------------------------------------------------
  def state_resist?(state_id)
    return state_ignore?(state_id)
  end
end
class Game_Actor
  #--------------------------------------------------------------------------
  # ○ ステート無効化判定
  #     state_id : ステート ID
  #--------------------------------------------------------------------------
  def state_resist?(state_id)
    for armor in armors.compact
      return true if armor.state_set.include?(state_id)
    end
    super
  end
end

# 12
class Game_Battler
  #--------------------------------------------------------------------------
  # ○ アイテムの効果適用
  #     user : アイテムの使用者
  #     item : アイテム
  #--------------------------------------------------------------------------
  def item_effect(user, item)
    clear_action_results
    unless item_effective?(user, item)
      @skipped = true
      return
    end
    if rand(100) >= calc_hit(user, item)          # 命中判定
      @missed = true
      return
    end
    if rand(100) < calc_eva(user, item)           # 回避判定
      @evaded = true
      return
    end
    hp_recovery = calc_hp_recovery(user, item)    # HP 回復量計算
    mp_recovery = calc_mp_recovery(user, item)    # MP 回復量計算
    make_obj_damage_value(user, item)             # ダメージ計算
    item_growth_effect(user, item)                # 成長効果適用
    @hp_damage -= hp_recovery                     # HP 回復量を差し引く
    @mp_damage -= mp_recovery                     # MP 回復量を差し引く
    make_obj_absorb_effect(user, item)            # 吸収効果計算
    execute_damage(user)                          # ダメージ反映
    if item.physical_attack and @hp_damage == 0   # 物理ノーダメージ判定
      return                                    
    end
    apply_state_changes(item)                     # ステート変化
  end
end

# 13
class Game_Character
  #--------------------------------------------------------------------------
  # ○ プレイヤーの方を向く
  #--------------------------------------------------------------------------
  def turn_toward_player
    sx = distance_x_from_player
    sy = distance_y_from_player
    if sx.abs > sy.abs                    # 横の距離のほうが長い
      sx > 0 ? turn_left : turn_right
    else                                  # 縦の距離のほうが長い
      sy > 0 ? turn_up : turn_down
    end
  end
  #--------------------------------------------------------------------------
  # ○ プレイヤーの逆を向く
  #--------------------------------------------------------------------------
  def turn_away_from_player
    sx = distance_x_from_player
    sy = distance_y_from_player
    if sx.abs > sy.abs                    # 横の距離のほうが長い
      sx > 0 ? turn_right : turn_left
    else                                  # 縦の距離のほうが長い
      sy > 0 ? turn_down : turn_up
    end
  end
end

# 14
class Game_Actor
  #--------------------------------------------------------------------------
  # ○ グラフィックの変更
  #     character_name  : 新しい歩行グラフィック ファイル名
  #     character_index : 新しい歩行グラフィック インデックス
  #     face_name       : 新しい顔グラフィック ファイル名
  #     face_index      : 新しい顔グラフィック インデックス
  #--------------------------------------------------------------------------
  alias _cao_sp_set_graphic set_graphic
  def set_graphic(character_name, character_index, face_name, face_index)
    _cao_sp_set_graphic(character_name, character_index, face_name, face_index)
    if $game_party.members[0] == self
      $game_player.set_graphic(character_name, character_index)
    end
  end
end
class Game_Player
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_sp_initialize initialize
  def initialize
    _cao_sp_initialize
    @last_actor_id = 0                  # アクターのＩＤ (記憶用)
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    if $game_party.members.size == 0
      @character_name = ""
      @character_index = 0
      @last_actor_id = 0
    else
      actor = $game_party.members[0]    # 先頭のアクターを取得
      if actor.id != @last_actor_id
        @character_name = actor.character_name
        @character_index = actor.character_index
        @last_actor_id = actor.id
      end
    end
  end
end
# 「アクターのグラフィック変更」と同じものにするための変更 (上記の変更は不要)
#~ class Game_Player
#~   #--------------------------------------------------------------------------
#~   # ◎ グラフィックの変更
#~   #     character_name  : 新しい歩行グラフィック ファイル名
#~   #     character_index : 新しい歩行グラフィック インデックス
#~   #--------------------------------------------------------------------------
#~   def set_graphic(character_name, character_index)
#~     @tile_id = 0
#~     @character_name = character_name
#~     @character_index = character_index
#~     actor = $game_party.members[0]      # 先頭のアクターを取得
#~     if actor != nil
#~       actor.set_graphic(character_name, character_index,
#~         actor.face_name, actor.face_index)
#~     end
#~   end
#~ end

# 15
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ステートの変更
  #--------------------------------------------------------------------------
  def command_313
    iterate_actor_id(@params[0]) do |actor|
      if @params[1] == 0
        live = !actor.state?(1)             # ステート変更前の生存判定
        actor.add_state(@params[2])
        actor.perform_collapse if live      # 戦闘不能ではなかった場合
      else
        actor.remove_state(@params[2])
      end
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 敵キャラのステート変更
  #--------------------------------------------------------------------------
  def command_333
    iterate_enemy_index(@params[0]) do |enemy|
      if @params[2] == 1                    # 戦闘不能の変更なら
        enemy.immortal = false              # 不死身フラグをクリア
      end
      if @params[1] == 0
        live = !enemy.state?(1)             # ステート変更前の生存判定
        enemy.add_state(@params[2])
        enemy.perform_collapse if live      # 戦闘不能ではなかった場合
      else
        enemy.remove_state(@params[2])
      end
    end
    return true
  end
end

# 16
class Scene_Battle
  #--------------------------------------------------------------------------
  # ○ 現在のステートの表示
  #--------------------------------------------------------------------------
  alias _cao_sp_display_current_state display_current_state
  def display_current_state
    return if @active_battler.hidden
    _cao_sp_display_current_state
  end
  #--------------------------------------------------------------------------
  # ○ ステート自然解除
  #--------------------------------------------------------------------------
  def remove_states_auto
    last_st = @active_battler.states
    @active_battler.remove_states_auto
    if @active_battler.states != last_st && !@active_battler.hidden
      wait(5)
      display_state_changes(@active_battler)
      wait(30)
      @message_window.clear
    end
  end
end

# 17
class Game_Battler
  #--------------------------------------------------------------------------
  # ● ステート変化の確認
  #     obj : スキル、アイテム、または攻撃者
  #--------------------------------------------------------------------------
  def states_changed?(obj)
    added_states = []
    removed_states = []
    for state_id in obj.plus_state_set      # ステート変化 (+)
      break if dead?                        # 戦闘不能？
      next if state_id == 1 and @immortal   # 不死身？
      next if state_resist?(state_id)       # 無効化されている？
      next if state?(state_id)              # すでに付加されている？
      added_states << state_id
    end
    for state_id in obj.minus_state_set     # ステート変化 (-)
      next unless state?(state_id)          # 付加されていない？
      removed_states << state_id
    end
    for state_id in added_states & removed_states
      added_states.delete(state_id)         # 付加と解除の両方に記録されている
      removed_states.delete(state_id)       # ステートがあれば両方削除する
    end
    return true unless added_states.empty?
    return true unless removed_states.empty?
    return false
  end
  #--------------------------------------------------------------------------
  # ○ スキルの適用テスト
  #     user  : スキルの使用者
  #     skill : スキル
  #    使用対象が全快しているときの回復禁止などを判定する。
  #--------------------------------------------------------------------------
  def skill_test(user, skill)
    tester = self.clone
    tester.make_obj_damage_value(user, skill)
    if tester.hp_damage < 0
      return true if tester.hp < tester.maxhp     # ＨＰが全快ではない
    end
    if tester.mp_damage < 0
      return true if tester.mp < tester.maxmp     # ＭＰが全快ではない
    end
    return true if tester.states_changed?(skill)  # ステートが変化する
    return false
  end
  #--------------------------------------------------------------------------
  # ○ アイテムの適用テスト
  #     user : アイテムの使用者
  #     item : アイテム
  #    使用対象が全快しているときの回復禁止などを判定する。
  #--------------------------------------------------------------------------
  def item_test(user, item)
    tester = self.clone
    tester.make_obj_damage_value(user, item)
    if tester.hp_damage < 0 or tester.calc_hp_recovery(user, item) > 0
      return true if tester.hp < tester.maxhp     # ＨＰが全快ではない
    end
    if tester.mp_damage < 0 or tester.calc_mp_recovery(user, item) > 0
      return true if tester.mp < tester.maxmp     # ＭＰが全快ではない
    end
    return true if tester.states_changed?(item)   # ステートが変化する
    return true if item.parameter_type > 0        # 能力値が変化する
    return false
  end
end

# 18, 19
class Game_Character
  #--------------------------------------------------------------------------
  # ○ ジャンプ時の更新
  #--------------------------------------------------------------------------
  def update_jump
    @jump_count -= 1
    @real_x = (@real_x * @jump_count + @jump_x * 256) / (@jump_count + 1)
    @real_y = (@real_y * @jump_count + @jump_y * 256) / (@jump_count + 1)
    if @jump_count == 0
      @real_x = (@real_x * @jump_count + @x * 256) / (@jump_count + 1)
      @real_y = (@real_y * @jump_count + @y * 256) / (@jump_count + 1)
    end
    update_bush_depth
  end
  #--------------------------------------------------------------------------
  # ○ ジャンプ
  #     x_plus : X 座標加算値
  #     y_plus : Y 座標加算値
  #--------------------------------------------------------------------------
  def jump(x_plus, y_plus)
    if x_plus.abs > y_plus.abs            # 横の距離のほうが長い
      x_plus < 0 ? turn_left : turn_right
    elsif x_plus.abs < y_plus.abs         # 縦の距離のほうが長い
      y_plus < 0 ? turn_up : turn_down
    end
    @jump_x = @x + x_plus
    @jump_y = @y + y_plus
    @x = $game_map.round_x(@jump_x)
    @y = $game_map.round_y(@jump_y)
    distance = Math.sqrt(x_plus * x_plus + y_plus * y_plus).round
    @jump_peak = 10 + distance - @move_speed
    @jump_count = @jump_peak * 2
    @stop_count = 0
    straighten
  end
end

# 20
class Game_Character
  #--------------------------------------------------------------------------
  # ○ プレイヤーからの X 距離計算
  #--------------------------------------------------------------------------
  def distance_x_from_player
    sx = @x - $game_player.x
    if $game_map.loop_horizontal? && sx.abs > $game_map.width / 2
      if $game_player.x > $game_map.width / 2
        sx += $game_map.width
      else
        sx -= $game_map.width
      end
    end
    return sx
  end
  #--------------------------------------------------------------------------
  # ○ プレイヤーからの Y 距離計算
  #--------------------------------------------------------------------------
  def distance_y_from_player
    sy = @y - $game_player.y
    if $game_map.loop_vertical? && sy.abs > $game_map.height / 2
      if $game_player.y > $game_map.height / 2
        sy += $game_map.height
      else
        sy -= $game_map.height
      end
    end
    return sy
  end
end

# 21
class Spriteset_Weather
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    return if @type == 0
    for i in 1..@max
      sprite = @sprites[i]
      break if sprite == nil
      case @type
      when 1  # 雨
        sprite.x -= 2
        sprite.y += 16
        sprite.opacity -= 8
      when 2  # 嵐
        sprite.x -= 8
        sprite.y += 16
        sprite.opacity -= 12
      when 3  # 雪
        sprite.x += rand(5) - 2
        sprite.y += 2
        sprite.opacity -= 4
      end
      x = sprite.x - @ox
      y = sprite.y - @oy
      if sprite.opacity < 64
        sprite.x = rand(800) - 100 + @ox
        sprite.y = rand(600) - 200 + @oy
        sprite.opacity = 255
      end
    end
  end
end

# 22
class Scene_Battle
  #--------------------------------------------------------------------------
  # ○ 付加されたステートの表示
  #     target : 対象者
  #     obj    : スキルまたはアイテム
  #--------------------------------------------------------------------------
  def display_added_states(target, obj = nil)
    for state in target.added_states
      target.perform_collapse if state.id == 1  # 戦闘不能
      if target.actor?
        next if state.message1.empty?
        text = target.name + state.message1
      else
        next if state.message2.empty?
        text = target.name + state.message2
      end
      @message_window.replace_instant_text(text)
      wait(20)
    end
  end
end

# 23
class Game_Actor
  #--------------------------------------------------------------------------
  # ○ スキルの習得済み判定
  #     skill : スキル
  #--------------------------------------------------------------------------
  def skill_learn?(skill)
    return false unless skill.is_a?(RPG::Skill)
    return @skills.include?(skill.id)
  end
end

# 24
class Window_SaveFile
  #--------------------------------------------------------------------------
  # ○ プレイ時間の描画
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #     align : 配置
  #--------------------------------------------------------------------------
  def draw_playtime(x, y, width, align)
    hour = @total_sec / 60 / 60
    min = @total_sec / 60 % 60
    sec = @total_sec % 60
    time_string = sprintf("%02d:%02d:%02d", hour, min, sec)
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, width, WLH, time_string, align)
  end
end
