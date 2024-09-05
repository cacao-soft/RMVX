#=============================================================================
#  [RGSS2] Custom Menu Canvas - v2.1.6
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

  カスタムメニューのベーススクリプトの１つです。
  ステータス項目を描画するためのメソッドが定義されています。

 -- 注意事項 ----------------------------------------------------------------

  ※ ステータスによっては、すべての機能に対応していないものもあります。

 -- 使用方法 ----------------------------------------------------------------

  ★ 顔グラ・立ち絵の変更
   CAO::CM::Commands.set_body_graphic(actor_id, filename)
   $game_actors[アクターＩＤ].body_name = "ファイル名"
  ※ ファイル名を数値にすると、識別番号のみの変更になります。
  ※ イベントコマンドで実行する場合、「CAO::CM::Commands.」は不要です。

=end


module CAO::CM::Canvas
  #--------------------------------------------------------------------------
  # ◇ 残りＨＰで顔グラを変化させる
  #--------------------------------------------------------------------------
  EXPRESSION_FACE = false
    #--------------------------------------------------------------------------
    # ◇ 残りＨＰのパーセント (設定以下で顔グラを変更) (最大３つ)
    #--------------------------------------------------------------------------
    #   ※ アクターの顔グラファイルを編集する必要があります。
    #   インデックス０が常時表示、１～３が設定値以下で変更する画像
    #--------------------------------------------------------------------------
    SWITCH_EXPRESSION = [50, 30, 0]
  
  #--------------------------------------------------------------------------
  # ◇ 戦闘不能アクターの顔グラの不透明度
  #--------------------------------------------------------------------------
  DIDE_FACE_OPACITY = 128
  
  #--------------------------------------------------------------------------
  # ◇ 歩行グラの向き変更
  #--------------------------------------------------------------------------
  WALK_CHANGE_DIRECTION = true
  
  #--------------------------------------------------------------------------
  # ◇ 顔グラ・立ち絵のファイル名
  #--------------------------------------------------------------------------
  #   初期化の際とファイル名変更時に使用されます。
  #   ["ファイル名", "フォーマット"] : ["MActor", "%s%d-%d"]
  #   フォーマット：%s ファイル名、%d １つ目にアクターのID、２つ目に識別番号
  #--------------------------------------------------------------------------
  MENU_FACE_NAME = ["MActor", "%s%d"]

  #--------------------------------------------------------------------------
  # ◇ 経験値の表示方法 (％で表示)
  #--------------------------------------------------------------------------
  #   true  : レベルアップに必要な経験値がいくら貯まっているか百分率で表示
  #   false : レベルアップに必要な経験値を数値で表示
  #--------------------------------------------------------------------------
  EXP_PERCENT = true
  
  #--------------------------------------------------------------------------
  # ◇ 経験値の名称
  #--------------------------------------------------------------------------
  TEXT_EXP = ["経験値", "EXP"]   # ["名称", "略称"]
  
  #--------------------------------------------------------------------------
  # ◇ メニューステータスの文字設定
  #--------------------------------------------------------------------------
  MENU_FONT = {}  # この行の設定は変更・削除しないでください。
  MENU_FONT[:name] = nil    # フォント名
  MENU_FONT[:size] = 20     # 文字サイズ
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module Vocab
  # 経験値
  def self.exp
    return CAO::CM::Canvas::TEXT_EXP[0]
  end
  # 経験値の略称
  def self.exp_a
    return CAO::CM::Canvas::TEXT_EXP[1]
  end
end

class CustomMenu_Canvas < Bitmap
  include CAO::CM::Canvas
  #===============================初期設定===================================

  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  WLH = MENU_FONT[:size] + 4          # 行の高さ基準値 (Window Line Height)
  WALK_PATTERN_SET = [0, 1, 2, 1]     # ホコグラの足踏みの順序
  WALK_DIRECTION_SET = [0, 1, 3, 2]   # ホコグラの向き変更の順序
  WAIT_WALK_PATTERN = 10              # ホコグラの足踏み
  WAIT_WALK_DIRECTION = 100           # ホコグラの向き変更
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(*args)
    super
    init_walk
    self.font.name = MENU_FONT[:name] if MENU_FONT[:name]
    self.font.size = MENU_FONT[:size]
  end
  #--------------------------------------------------------------------------
  # ● 足踏みアニメの初期化
  #--------------------------------------------------------------------------
  def init_walk
    @frame_count = 0
    @walk_pattern = 1
    @walk_direction = 0
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update_walk
    if @frame_count % WAIT_WALK_PATTERN == 0 && @frame_count != 0
      # 歩行パターンを進める
      @walk_pattern = (@walk_pattern + 1) % 4
      # 向きを変更する
      if WALK_CHANGE_DIRECTION && @frame_count % WAIT_WALK_DIRECTION == 0
        @walk_direction = (@walk_direction + 1) % 4
      end
    end
    @frame_count += 1
  end
  #===============================色の設定===================================

  #--------------------------------------------------------------------------
  # ● 通常文字色の取得
  #--------------------------------------------------------------------------
  def normal_color
    return text_color(0)
  end
  #--------------------------------------------------------------------------
  # ● システム文字色の取得
  #--------------------------------------------------------------------------
  def system_color
    return text_color(16)
  end
  #--------------------------------------------------------------------------
  # ● ピンチ文字色の取得
  #--------------------------------------------------------------------------
  def crisis_color
    return text_color(17)
  end
  #--------------------------------------------------------------------------
  # ● 戦闘不能文字色の取得
  #--------------------------------------------------------------------------
  def knockout_color
    return text_color(18)
  end
  #--------------------------------------------------------------------------
  # ● ゲージ背景色の取得
  #--------------------------------------------------------------------------
  def gauge_back_color
    return text_color(19)
  end
  #--------------------------------------------------------------------------
  # ● HP ゲージの色 1 の取得
  #--------------------------------------------------------------------------
  def hp_gauge_color1
    return text_color(20)
  end
  #--------------------------------------------------------------------------
  # ● HP ゲージの色 2 の取得
  #--------------------------------------------------------------------------
  def hp_gauge_color2
    return text_color(21)
  end
  #--------------------------------------------------------------------------
  # ● MP ゲージの色 1 の取得
  #--------------------------------------------------------------------------
  def mp_gauge_color1
    return text_color(22)
  end
  #--------------------------------------------------------------------------
  # ● MP ゲージの色 2 の取得
  #--------------------------------------------------------------------------
  def mp_gauge_color2
    return text_color(23)
  end
  #--------------------------------------------------------------------------
  # ● EXP ゲージの色 1 の取得
  #--------------------------------------------------------------------------
  def exp_gauge_color1
    return text_color(28)
  end
  #--------------------------------------------------------------------------
  # ● EXP ゲージの色 2 の取得
  #--------------------------------------------------------------------------
  def exp_gauge_color2
    return text_color(29)
  end
  #--------------------------------------------------------------------------
  # ● 装備画面のパワーアップ色の取得
  #--------------------------------------------------------------------------
  def power_up_color
    return text_color(24)
  end
  #--------------------------------------------------------------------------
  # ● 装備画面のパワーダウン色の取得
  #--------------------------------------------------------------------------
  def power_down_color
    return text_color(25)
  end
  
  #==========================================================================
  
  #--------------------------------------------------------------------------
  # ● HP の文字色を取得
  #     actor : アクター
  #--------------------------------------------------------------------------
  def hp_color(actor)
    return knockout_color if actor.hp == 0
    return crisis_color if actor.hp < actor.maxhp / 4
    return normal_color
  end
  #--------------------------------------------------------------------------
  # ● MP の文字色を取得
  #     actor : アクター
  #--------------------------------------------------------------------------
  def mp_color(actor)
    return crisis_color if actor.mp < actor.maxmp / 4
    return normal_color
  end
  
  #===============================描画処理===================================
  
  #--------------------------------------------------------------------------
  # ● ステータス項目の描画
  #     actor  : アクター
  #     x      : 描画先 X 座標
  #     y      : 描画先 Y 座標
  #     params : オプション
  #--------------------------------------------------------------------------
  def draw_item(actor, x, y, params)
    case params[0]
    when :name
      width = params[3] ? params[3] : 120
      align = params[4] ? params[4] : 0
      draw_actor_name(actor, x, y, width, align)
    when :level
      width = params[3] ? params[3] : 120
      align = params[4] ? params[4] : 0
      draw_actor_level(actor, x, y, width, align)
    when :level_g
      width = params[3] ? params[3] : 120
      align = params[4] ? params[4] : 0
      draw_actor_level_g(actor, x, y, width, align)
    when :class
      width = params[3] ? params[3] : 120
      align = params[4] ? params[4] : 0
      draw_actor_class(actor, x, y, width, align)
    when :state
      width = params[3] ? params[3] : 120
      draw_actor_state(actor, x, y, width)
    when :hp
      width = params[3] ? params[3] : 120
      draw_actor_hp(actor, x, y, width)
    when :mp
      width = params[3] ? params[3] : 120
      draw_actor_mp(actor, x, y, width)
    when :exp
      width = params[3] ? params[3] : 120
      draw_actor_exp(actor, x, y, width)
    when :position
      width = params[3] ? params[3] : 120
      align = params[4] ? params[4] : 0
      draw_actor_position(actor, x, y, width, align)
    when :face
      size = params[3] ? params[3] : 96
      if EXPRESSION_FACE
        draw_actor_expression(actor, x, y, size)
      else
        draw_actor_face(actor, x, y, size)
      end
    when :chara
      bottom = params[3] ? params[3] : false
      draw_actor_graphic(actor, x, y, bottom)
    when :walk
      bottom = params[3] ? params[3] : false
      draw_move_actor_graphic(actor, x, y, bottom, true)
    when :body
      draw_actor_body(actor, x, y)
    else
      draw_ext_item(actor, x, y, params)
    end
  end
  #--------------------------------------------------------------------------
  # ● ステータス拡張項目の描画
  #--------------------------------------------------------------------------
  def draw_ext_item(actor, x, y, params)
    # 内容は、拡張キャンバスで定義
  end
  #--------------------------------------------------------------------------
  # ● 文字色取得
  #     n : 文字色番号 (0～31)
  #--------------------------------------------------------------------------
  def text_color(n)
    x = 64 + (n % 8) * 8
    y = 96 + (n / 8) * 8
    return Cache.system("Window").get_pixel(x, y)
  end
  #--------------------------------------------------------------------------
  # ● ゲージの描画
  #     x        : 描画先 X 座標
  #     y        : 描画先 Y 座標
  #     gc1      : 最初の色・文字色番号 (0～31)
  #     gc2      : 最後の色・文字色番号 (0～31)
  #     gw       : ゲージの描画幅
  #     width    : 横幅
  #     height   : 縦幅
  #     vertical : グラデーション方向 (true .. 縦, false .. 横)
  #--------------------------------------------------------------------------
  def draw_gauge(x, y, gc1, gc2, gw, width = 120, height = 6, vertical = false)
    gc1 = text_color(gc1) unless gc1.is_a?(Color)
    gc2 = text_color(gc2) unless gc2.is_a?(Color)
    self.fill_rect(x, y, width, height, gauge_back_color)
    self.gradient_fill_rect(Rect.new(x, y, gw, height), gc1, gc2, vertical)
  end
  #--------------------------------------------------------------------------
  # ● アイコンの描画
  #     bitmap     : 描画先ビットマップ
  #     icon_index : アイコン番号
  #     x          : 描画先 X 座標
  #     y          : 描画先 Y 座標
  #     enabled    : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_icon(icon_index, x, y, enabled = true)
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    self.blt(x, y, Cache.system("Iconset"), rect, enabled ? 255 : 128)
  end
  #--------------------------------------------------------------------------
  # ● 顔グラフィックの描画
  #     face_name  : 顔グラフィック ファイル名
  #     face_index : 顔グラフィック インデックス
  #     x          : 描画先 X 座標
  #     y          : 描画先 Y 座標
  #     size       : 表示サイズ
  #--------------------------------------------------------------------------
  def draw_face(face_name, face_index, x, y, size = 96, opacity = 255)
    if Array === size
      width, height = size
    else
      width, height = size, size
    end
    rect = Rect.new(0, 0, width, height)
    rect.x = face_index % 4 * 96 + (96 - width) / 2
    rect.y = face_index / 4 * 96 + (96 - height) / 2
    self.blt(x, y, Cache.face(face_name), rect, opacity)
  end
  #--------------------------------------------------------------------------
  # ● 歩行グラフィックの描画
  #     character_name  : 歩行グラフィック ファイル名
  #     character_index : 歩行グラフィック インデックス
  #     x               : 描画先 X 座標
  #     y               : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_character(character_name, character_index, x, y, bottom = false)
    return if character_name == nil
    bitmap = Cache.character(character_name)
    sign = character_name[/^[\!\$]./]
    if sign != nil and sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    n = character_index
    src_rect = Rect.new((n % 4 * 3 + 1) * cw, (n / 4 * 4) * ch, cw, ch)
    if bottom
      self.blt(x - cw / 2, y - ch, bitmap, src_rect)
    else
      self.blt(x, y, bitmap, src_rect)
    end
  end
  #--------------------------------------------------------------------------
  # ● アクターの歩行グラフィック描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_graphic(actor, x, y, bottom = false)
    draw_character(actor.character_name, actor.character_index, x, y, bottom)
  end
  #--------------------------------------------------------------------------
  # ● 歩行グラフィックアニメーション描画
  #     actor     : アクター
  #     x         : 描画先 X 座標
  #     y         : 描画先 Y 座標
  #     pattern   : 足踏み
  #     direction : 向き
  #     bottom    : 足元を基準に描画
  #     forced    : 強制的に描画
  #--------------------------------------------------------------------------
  def draw_move_actor_graphic(actor, x, y, bottom = false, forced = false)
    return if actor.character_name == nil
    return if @frame_count % WAIT_WALK_PATTERN != 0 && !forced
    bitmap = Cache.character(actor.character_name)
    sign = actor.character_name[/^[\!\$]./]
    if sign != nil and sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    n = actor.character_index
    src_rect = Rect.new(0, 0, cw, ch)
    src_rect.x = (n % 4 * 3 + WALK_PATTERN_SET[@walk_pattern]) * cw
    src_rect.y = (n / 4 * 4 + WALK_DIRECTION_SET[@walk_direction]) * ch
    x, y = (x - cw / 2), (y - ch) if bottom   # 足元を基点
    self.clear_rect(x, y, cw, ch)
    self.blt(x, y, bitmap, src_rect)
  end
  #--------------------------------------------------------------------------
  # ● 立ち絵の描画
  #     actor      : 立ち絵 ファイル名
  #     x          : 描画先 X 座標
  #     y          : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_body(actor, x, y)
    bitmap = Cache.picture(actor.body_name)
    self.blt(x, y, bitmap, bitmap.rect)
  end
  #--------------------------------------------------------------------------
  # ● 顔グラフィック描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     size  : 表示サイズ
  #--------------------------------------------------------------------------
  def draw_actor_face(actor, x, y, size = 96)
    opacity = actor.hp.zero? ? DIDE_FACE_OPACITY : 255
    draw_face(actor.face_name, actor.face_index, x, y, size, opacity)
  end
  #--------------------------------------------------------------------------
  # ● アクターの表情グラフィック描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     size  : 表示サイズ
  #--------------------------------------------------------------------------
  def draw_actor_expression(actor, x, y, size = 96)
    opacity = actor.hp.zero? ? DIDE_FACE_OPACITY : 255
    hp = (actor.hp * 100 / actor.maxhp).ceil
    for i in 0...SWITCH_EXPRESSION.size
      if hp > SWITCH_EXPRESSION[i]
        face_index = i
        break
      end
      face_index = SWITCH_EXPRESSION.size
    end
    draw_face(actor.face_name, face_index, x, y, size, opacity)
  end
  #--------------------------------------------------------------------------
  # ● 名前の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_name(actor, x, y, width = 120, align = 0)
    self.font.color = hp_color(actor)
    self.draw_text(x, y, width, WLH, actor.name, align)
  end
  #--------------------------------------------------------------------------
  # ● クラスの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_class(actor, x, y, width = 120, align = 0)
    self.font.color = normal_color
    self.draw_text(x, y, width, WLH, actor.class.name, align)
  end
  #--------------------------------------------------------------------------
  # ● レベルの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_level(actor, x, y, width = 120, align = 0)
    x = x + [0, (width - 56) / 2, width - 56][align]
    self.font.color = system_color
    self.draw_text(x, y, 32, WLH, Vocab::level_a)
    self.font.color = normal_color
    self.draw_text(x + 32, y, 24, WLH, actor.level, 2)
  end
  #--------------------------------------------------------------------------
  # ● レベルの描画 (ゲージ付き)
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_level_g(actor, x, y, width = 120, align = 0)
    x = x + [0, (width - 56) / 2, width - 56][align]
    draw_actor_exp_gauge(actor, x, y, 56)
    self.font.color = system_color
    self.draw_text(x, y, 32, WLH, Vocab::level_a)
    self.font.color = normal_color
    self.draw_text(x + 32, y, 24, WLH, actor.level, 2)
  end
  #--------------------------------------------------------------------------
  # ● ステートの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 描画先の幅
  #--------------------------------------------------------------------------
  def draw_actor_state(actor, x, y, width = 120)
    count = 0
    for state in actor.states
      draw_icon(state.icon_index, x + 24 * count, y)
      count += 1
      break if (24 * count > width - 24)
    end
  end
  #--------------------------------------------------------------------------
  # ● HP の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_hp(actor, x, y, width = 120)
    draw_actor_hp_gauge(actor, x, y, width)
    self.font.color = system_color
    self.draw_text(x, y, 30, WLH, Vocab::hp_a)
    self.font.color = hp_color(actor)
    xr = x + width
    if width < 120
      self.draw_text(xr - 40, y, 40, WLH, actor.hp, 2)
    else
      self.draw_text(xr - 90, y, 40, WLH, actor.hp, 2)
      self.font.color = normal_color
      self.draw_text(xr - 50, y, 10, WLH, "/", 2)
      self.draw_text(xr - 40, y, 40, WLH, actor.maxhp, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● HP ゲージの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_hp_gauge(actor, x, y, width = 120)
    gw = width * actor.hp / actor.maxhp
    draw_gauge(x, y + WLH - 8, hp_gauge_color1, hp_gauge_color2, gw, width)
  end
  #--------------------------------------------------------------------------
  # ● MP の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_mp(actor, x, y, width = 120)
    draw_actor_mp_gauge(actor, x, y, width)
    self.font.color = system_color
    self.draw_text(x, y, 30, WLH, Vocab::mp_a)
    self.font.color = mp_color(actor)
    xr = x + width
    if width < 120
      self.draw_text(xr - 40, y, 40, WLH, actor.mp, 2)
    else
      self.draw_text(xr - 90, y, 40, WLH, actor.mp, 2)
      self.font.color = normal_color
      self.draw_text(xr - 50, y, 10, WLH, "/", 2)
      self.draw_text(xr - 40, y, 40, WLH, actor.maxmp, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● MP ゲージの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_mp_gauge(actor, x, y, width = 120)
    gw = width * actor.mp / [actor.maxmp, 1].max
    draw_gauge(x, y + WLH - 8, mp_gauge_color1, mp_gauge_color2, gw, width)
  end
  #--------------------------------------------------------------------------
  # ● 経験値の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_exp(actor, x, y, width = 120)
    # 次のレベル
    next_level = actor.level + 1
    # 経験値リスト
    exp_list = actor.instance_variable_get(:@exp_list)
    # レベルアップに必要な経験値
    level_up_exp = [0, exp_list[next_level] - exp_list[actor.level]].max
    # レベルアップまでの残り経験値
    next_rest_exp = [0, exp_list[next_level] - actor.exp].max
    # レベル単位での取得経験値
    level_exp = level_up_exp - next_rest_exp
    if EXP_PERCENT
      exp = (level_up_exp == 0 ? 100 : 100 - next_rest_exp * 100 / level_up_exp)
      exp = sprintf("%d%%", exp)
    else
      exp = next_rest_exp
    end
    # ゲージの描画
    draw_actor_exp_gauge(actor, x, y, width)
    self.font.color = system_color
    self.draw_text(x, y, 60, WLH, Vocab.exp_a)
    self.font.color = normal_color
    self.draw_text(x + width - 60, y, 60, WLH, exp, 2)
  end
  #--------------------------------------------------------------------------
  # ● 経験値ゲージの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_exp_gauge(actor, x, y, width = 120)
    # 次のレベル
    next_level = actor.level + 1
    # 経験値リスト
    exp_list = actor.instance_variable_get(:@exp_list)
    # レベルアップに必要な経験値
    level_up_exp = [0, exp_list[next_level] - exp_list[actor.level]].max
    # レベルアップまでの残り経験値
    next_rest_exp = [0, exp_list[next_level] - actor.exp].max
    # レベル単位での取得経験値
    level_exp = level_up_exp - next_rest_exp
    # ゲージの描画
    gw = (level_up_exp == 0 ? width : width / level_up_exp.to_f * level_exp)
    draw_gauge(x, y + WLH - 8, exp_gauge_color1, exp_gauge_color2, gw, width)
  end
  #--------------------------------------------------------------------------
  # ● ポジションの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_position(actor, x, y, width = 120, align = 0)
    text = ["前衛", "中衛", "後衛"][actor.class.position]
    self.draw_text(x, y, width, WLH, text, align)
  end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :body_name                # 立ち絵 ファイル名
  #--------------------------------------------------------------------------
  # 〇 セットアップ
  #     actor_id : アクター ID
  #--------------------------------------------------------------------------
  alias _cao_setup_cm setup
  def setup(actor_id)
    filename = CAO::CM::Canvas::MENU_FACE_NAME[0]
    format = CAO::CM::Canvas::MENU_FACE_NAME[1]
    @body_name = sprintf(format, filename, actor_id, 0)
    _cao_setup_cm(actor_id)
  end
  #--------------------------------------------------------------------------
  # ● 立ち絵の変更
  #     filename : 新しい立ち絵 ファイル名 or インデックス
  #--------------------------------------------------------------------------
  def body_name=(filename)
    if String === filename
      @body_name = filename
    else
      number = "#{@actor_id}-#{filename}"
      @body_name = CAO::CM::Canvas::MENU_FACE_NAME[0] + number
    end
  end
end

module CAO::CM::Commands
  module_function
  #--------------------------------------------------------------------------
  # ● 立ち絵の変更
  #--------------------------------------------------------------------------
  #     actor_id : アクターのＩＤ
  #     filename : ファイル名 or 識別番号
  #--------------------------------------------------------------------------
  def set_body_graphic(actor_id, filename)
    $game_actors[actor_id].body_name = filename
  end
end
