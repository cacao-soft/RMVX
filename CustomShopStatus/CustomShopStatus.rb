#=============================================================================
#  [RGSS2] カスタムショップステータス - v1.1.3
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

  ショップステータスの内容を拡張します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を多く行っております。なるべく上部に配置してください。
  ※ 項目名やアイコンが重なる場合は、設定を見直してください。


=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module ShopStatus
  #--------------------------------------------------------------------------
  # ◇ 選択中のアイテムの所持数を表示する
  #--------------------------------------------------------------------------
  DISPLAY_POSSESSION = true
  #--------------------------------------------------------------------------
  # ◇ 未設定パラメータの変化値も表示する
  #--------------------------------------------------------------------------
  DISPLAY_NODATA = true
  #--------------------------------------------------------------------------
  # ◇ アクターの切り替えにＬＲボタンを使用する
  #--------------------------------------------------------------------------
  LR_CHANGE = false
  #--------------------------------------------------------------------------
  # ◇ 表示するパラメータ
  #--------------------------------------------------------------------------
  PARAMS = [:atk, :def, :spi, :agi, :hit, :eva]
  #--------------------------------------------------------------------------
  # ◇ パラメータ名の設定
  #--------------------------------------------------------------------------
  VOCAB_PARAMS = {}
  VOCAB_PARAMS[:maxhp] = "Ｈ　Ｐ"
  VOCAB_PARAMS[:maxmp] = "Ｍ　Ｐ"
  VOCAB_PARAMS[:atk]   = "攻撃力"
  VOCAB_PARAMS[:def]   = "防御力"
  VOCAB_PARAMS[:spi]   = "精神力"
  VOCAB_PARAMS[:agi]   = "敏捷性"
  VOCAB_PARAMS[:hit]   = "命中率"
  VOCAB_PARAMS[:eva]   = "回避率"
  VOCAB_PARAMS[:cri]   = "会心率"
  VOCAB_PARAMS[:odds]  = "存在感"
  VOCAB_PARAMS[:mdef]  = "抵抗力"
  #--------------------------------------------------------------------------
  # ◇ 用語設定
  #--------------------------------------------------------------------------
  VOCAB_POSSESSION = "個"                 # 所持数の単位
  VOCAB_SEPARATOR  = "≫"                 # 数値の区切り
  VOCAB_ZERO       = "0"                  # 数値 0
  VOCAB_NONE       = "----"               # 数値非表示
  VOCAB_NOICON     = "なし"               # 属性・ステートなし
  VOCAB_POWER      = ["-", "▲", "▼"]    # [変化なし, UP, DOWN]
  #--------------------------------------------------------------------------
  # ◇ 表示する属性とステートの設定
  #--------------------------------------------------------------------------
  USABLE_ELEMENTS = Array(9..16)          # 属性
  USABLE_STATES   = Array(1..8)           # ステート
  #--------------------------------------------------------------------------
  # ◇ 属性のアイコン・色の設定
  #--------------------------------------------------------------------------
  ICON_ELEMENTS = {}
  ICON_ELEMENTS["炎"]   = Color.new(230, 30, 30)
  ICON_ELEMENTS["冷気"] = 105
  ICON_ELEMENTS["雷"]   = Color.new(255, 230, 0)
  ICON_ELEMENTS["水"]   = Color.new(100, 180, 255)
  ICON_ELEMENTS["大地"] = 108
  ICON_ELEMENTS["風"]   = Color.new(120, 200, 60)
  ICON_ELEMENTS["神聖"] = 110
  ICON_ELEMENTS["暗黒"] = 111
  #--------------------------------------------------------------------------
  # ◇ 属性のグループ設定
  #--------------------------------------------------------------------------
  GROUP_ELEMENTS = {}
  GROUP_ELEMENTS[Array(9..16)] = "すべての属性"
  #--------------------------------------------------------------------------
  # ◇ ステートのグループ設定
  #--------------------------------------------------------------------------
  GROUP_STATES = {}
  GROUP_STATES[[1]]  = "戦闘不能"
  GROUP_STATES[[9,10,11,12]]  = "すべてのステータス上昇"
  GROUP_STATES[Array(13..16)] = "すべてのステータス低下"
  #--------------------------------------------------------------------------
  # ◇ ファイル名の設定
  #--------------------------------------------------------------------------
  FILE_ACTOR_ICON = ""      # アクターアイコン
  FILE_EQUIP_ICON = ""      # 装備済みマーク
  #--------------------------------------------------------------------------
  # ◇ 文字色の設定
  #--------------------------------------------------------------------------
  COLOR_PUP   = 24          # パワーアップ
  COLOR_PDOWN = 25          # パワーダウン
end # ShopStatus
end # CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_ShopStatus
  include CAO::ShopStatus
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     x : ウィンドウの X 座標
  #     y : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  alias _cao_shopstatus_initialize initialize
  def initialize(x, y)
    @page = 0
    _cao_shopstatus_initialize(x, y)
    self.active = false
  end
  #--------------------------------------------------------------------------
  # ● ページ切り替えの処理が必要か
  #--------------------------------------------------------------------------
  def switch_page?
    return false
  end
  #--------------------------------------------------------------------------
  # ● 最大ページ数
  #--------------------------------------------------------------------------
  def page_max
    return 1
  end

  #--------------------------------------------------------------------------
  # ● パーティの配列を取得
  #--------------------------------------------------------------------------
  def members
    return $game_party.members
  end
  #--------------------------------------------------------------------------
  # ● ダミーの配列を取得
  #--------------------------------------------------------------------------
  def dummy_members
    return members.map {|actor| Marshal.load(Marshal.dump(actor)) }
  end
  #--------------------------------------------------------------------------
  # ● ダミーキャッシュのクリア
  #--------------------------------------------------------------------------
  def clear_dummy_members
    @__dummy_members = dummy_members
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def each_members!
    return unless block_given?
    members.size.times do |i|
      yield $game_party.members[i], @__dummy_members[i], i
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def each_members
    return unless block_given?
    dm = dummy_members
    members.size.times do |i|
      yield $game_party.members[i],dm[i], i
    end
  end

  #--------------------------------------------------------------------------
  # ● 元と装備変更後のパラメータを配列で取得
  #--------------------------------------------------------------------------
  def actor_parameter(symbol, actor, dummy)
    old_param = actor.__send__(symbol)
    new_param = nil
    if actor.equippable?(@item)
      dummy.change_equip(equip_type(actor), @item, true)
      new_param = dummy.__send__(symbol)
    end
    unless DISPLAY_NODATA
      if !@item.respond_to?(symbol) || @item.__send__(symbol) == 0
        new_param = nil
      end
    end
    return [old_param, new_param]
  end
  #--------------------------------------------------------------------------
  # ● 装備部位の取得
  #--------------------------------------------------------------------------
  def equip_type(actor)
    case @item
    when RPG::Weapon
      return weaker_weapon_index(actor)
    when RPG::Armor
      return 1 + @item.kind
    else
      raise "must not happen"
    end
  end
  #--------------------------------------------------------------------------
  # ● パラメータの描画色を変更
  #--------------------------------------------------------------------------
  def change_parameter_color(value)
    if value < 0
      self.contents.font.color = power_down_color
    elsif value > 0
      self.contents.font.color = power_up_color
    else
      self.contents.font.color = normal_color
    end
  end
  #--------------------------------------------------------------------------
  # ○ 装備画面のパワーアップ色の取得
  #--------------------------------------------------------------------------
  def power_up_color
    case COLOR_PUP
    when Integer
      return text_color(COLOR_PUP)
    when Color
      return COLOR_PUP
    else
      return super
    end
  end
  #--------------------------------------------------------------------------
  # ○ 装備画面のパワーダウン色の取得
  #--------------------------------------------------------------------------
  def power_down_color
    case COLOR_PDOWN
    when Integer
      return text_color(COLOR_PDOWN)
    when Color
      return COLOR_PDOWN
    else
      return super
    end
  end

  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_input
  end
  #--------------------------------------------------------------------------
  # ● 入力情報の更新
  #--------------------------------------------------------------------------
  def update_input
    return unless self.switch_page? && self.active
    if Input.trigger?(LR_CHANGE ? Input::L : Input::LEFT)
      Sound.play_cursor
      @page = (@page - 1) % self.page_max
      refresh
    elsif Input.trigger?(LR_CHANGE ? Input::R : Input::RIGHT)
      Sound.play_cursor
      @page = (@page + 1) % self.page_max
      refresh
    end
  end

  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    @last_y = 0
    self.contents.clear
    case @item
    when RPG::Item
      draw_item_parameter
    when RPG::Weapon
      draw_weapon_parameter
    when RPG::Armor
      draw_armor_parameter
    end
  end
  #--------------------------------------------------------------------------
  # ● アイテムパラメータの描画
  #--------------------------------------------------------------------------
  def draw_item_parameter
    draw_possession(0, 0)
  end
  #--------------------------------------------------------------------------
  # ● 装備パラメータの描画
  #--------------------------------------------------------------------------
  def draw_equip_parameter
    draw_possession(0, 0)
    for actor in $game_party.members
      draw_actor_parameter_change(actor, 4, WLH * (2 + actor.index * 2))
    end
  end
  #--------------------------------------------------------------------------
  # ● 武器パラメータの描画
  #--------------------------------------------------------------------------
  def draw_weapon_parameter
    draw_equip_parameter
  end
  #--------------------------------------------------------------------------
  # ● 防具パラメータの描画
  #--------------------------------------------------------------------------
  def draw_armor_parameter
    draw_equip_parameter
  end

  #--------------------------------------------------------------------------
  # ● 所持数の描画
  #--------------------------------------------------------------------------
  def draw_possession(x, y, yy = 16)
    return unless DISPLAY_POSSESSION
    number = $game_party.item_number(@item)
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 208, WLH, Vocab::Possession)
    self.contents.draw_text(x + 182, y, 24, WLH, VOCAB_POSSESSION, 2)
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, 182, WLH, number, 2)
    @last_y = WLH + yy
  end
  #--------------------------------------------------------------------------
  # ● アクター画像
  #--------------------------------------------------------------------------
  def actor_bitmap(actor)
    bitmap = Cache.character(actor.character_name)
    sign = actor.character_name[/^[\!\$]./]
    if sign != nil and sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    return bitmap, cw, ch
  end
  #--------------------------------------------------------------------------
  # ○ アクターの歩行グラフィック描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_graphic(actor, x, y)
    return if actor.character_name == nil
    bitmap, cw, ch = actor_bitmap(actor)
    n = actor.character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, (ch < 32) ? ch : 32)
    self.contents.blt(x - cw / 2, y - 32, bitmap, src_rect)
  end
  #--------------------------------------------------------------------------
  # ● アクターアイコンの描画
  #--------------------------------------------------------------------------
  def draw_actor_icon(actor, x, y)
    if @item.is_a?(RPG::Item) || (actor && actor.equippable?(@item))
      opacity = 255
    else
      opacity = 128
    end

    back_color = Color.new(0, 0, 0, opacity)
    self.contents.fill_rect(x, y, 24, 24, back_color)
    back_color.set(255, 255, 255, opacity)
    self.contents.fill_rect(x + 1, y + 1, 22, 22, back_color)

    return unless actor
    if FILE_ACTOR_ICON.empty?
      return unless actor.character_name
      bitmap, cw, ch = actor_bitmap(actor)
      n = actor.character_index
      src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, 20, 20)
      src_rect.x += (cw - src_rect.width) / 2
      src_rect.y += (ch - src_rect.height) / 4
      self.contents.blt(x + 2, y + 2, bitmap, src_rect, opacity)
    else
      index = actor.id - 1
      src_rect = Rect.new(index % 8 * 24, index / 8 * 24, 24, 24)
      self.contents.blt(x, y, Cache.system(FILE_ACTOR_ICON), src_rect, opacity)
    end
  end
  #--------------------------------------------------------------------------
  # ● 装備済みマークの描画
  #--------------------------------------------------------------------------
  def draw_equip_icon(actor, x, y, size = 24)
    return unless actor
    return unless actor.equips.include?(@item)
    return if FILE_EQUIP_ICON.empty?

    bitmap = Cache.system(FILE_EQUIP_ICON)
    x -= (bitmap.width - size) / 2
    y -= (bitmap.height - size) / 2
    self.contents.blt(x, y, bitmap, bitmap.rect)
  end
  #--------------------------------------------------------------------------
  # ● 属性・ステートの描画
  #--------------------------------------------------------------------------
  def draw_additive(param, x, y, name, double, dext, max = 8)
    dext = true unless double
    width = 208 - x
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, width, WLH, name)
    if double
      y += WLH
      @last_y += WLH * 2
    else
      @last_y += WLH
    end
    if param.is_a?(String)
      self.contents.font.color = normal_color
      self.contents.draw_text(x + 14, y, width - 16, WLH, param, dext ? 2 : 0)
    else
      if dext
        x += 2 + [0, width - (26 * param.size)].max
      elsif width - (26 * max - 2) >= 14
        x += 14
      end
      param.each_with_index {|item,i| draw_additive_icon(item, x + 26 * i, y) }
    end
  end
  #--------------------------------------------------------------------------
  # ● 属性・ステートアイコンの描画
  #--------------------------------------------------------------------------
  def draw_additive_icon(param, x, y, enabled = true)
    if param.is_a?(RPG::State)
      draw_icon(param.icon_index, x, y, enabled)
    else
      if ICON_ELEMENTS[param].is_a?(Integer)
        draw_icon(ICON_ELEMENTS[param], x, y, enabled)
      else
        self.contents.font.color = ICON_ELEMENTS[param] || normal_color
        self.contents.draw_text(x, y, 26, WLH, param, 1)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● アクターが装備している弱いほうの武器の取得 (二刀流用)
  #--------------------------------------------------------------------------
  def weaker_weapon_index(actor)
    result = 0
    min_atk = 9999
    actor.weapons.each_with_index do |weapon,index|
      weapon_atk = weapon ? weapon.atk : 0
      if weapon_atk < min_atk
        result = index
        min_atk = weapon_atk
      end
    end
    return result
  end
end

if CAO::ShopStatus::LR_CHANGE
class Window_ShopBuy
  #--------------------------------------------------------------------------
  # ○ カーソルを 1 ページ後ろに移動
  #--------------------------------------------------------------------------
  def cursor_pagedown
  end
  #--------------------------------------------------------------------------
  # ○ カーソルを 1 ページ前に移動
  #--------------------------------------------------------------------------
  def cursor_pageup
  end
end
end # if CAO::ShopStatus::LR_CHANGE

class Scene_Shop
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_shopstatus_update update
  def update
    _cao_shopstatus_update
    @status_window.active = @buy_window.active
  end
end

# KAMESOFT 装備拡張対応
if $imported && $imported["EquipExtension"]
class Window_ShopStatus
  #--------------------------------------------------------------------------
  # ○ 装備部位の取得
  #--------------------------------------------------------------------------
  alias _cao_shopstatus_equip_type equip_type
  def equip_type(actor)
    if @item.is_a?(RPG::Armor)
      return 1 + weaker_armor_index(actor, @item.kind)
    end
    _cao_shopstatus_equip_type(actor)
  end
  #--------------------------------------------------------------------------
  # ● アクターが装備している最も弱い防具の取得 (装備拡張用)
  #     kind  : 防具の種類
  #--------------------------------------------------------------------------
  def weaker_armor_index(actor, kind)
    result = [actor.equip_type.index(kind), 9999]
    actor.armors.each_with_index do |item,i|
      # 種類が違う場合はスキップ
      next if actor.equip_type[i] != kind
      # 前のアイテムとの総合的な性能を比較して低い方を保存
      new = [i, item ? item.atk + item.def + item.spi + item.agi : 0]
      result = new if new[1] < result[1]
    end
    return result[0]
  end
end
class Game_Actor
  #--------------------------------------------------------------------------
  # ○ 装備の変更 (オブジェクトで指定)
  #     equip_type : 装備部位
  #     item       : 武器 or 防具 (nil なら装備解除)
  #     test       : テストフラグ (戦闘テスト、または装備画面での一時装備)
  #--------------------------------------------------------------------------
  def change_equip(equip_type, item, test = false)
    n = (item != nil ? $game_party.item_number(item) : 0)
    change_equip_KGC_EquipExtension(equip_type, item, test)
    # 拡張防具欄がある場合のみ
    if extra_armor_number > 0 && (test || item == nil || n > 0)
      item_id = item == nil ? 0 : item.id
      case equip_type
      when 5..armor_number  # 拡張防具欄
        @extra_armor_id = [] if @extra_armor_id == nil
        @extra_armor_id[equip_type - 5] = item_id
      end
    end

    restore_battle_skill if $imported["SkillCPSystem"]
  end
end
end # if $imported && $imported["EquipExtension"]

# KAMESOFT 多人数パーティ対策
if $imported && $imported["LargeParty"]
class Window_ShopStatus
  KGC::LargeParty::SHOP_STATUS_SCROLL_BUTTON = nil  # スクロールを無効化
  remove_method :create_contents
end
end # if $imported && $imported["LargeParty"]
