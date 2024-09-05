#=============================================================================
#  [RGSS2] ＜拡張＞ ショップステータス - v1.0.3
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

  デフォルトのショップステータスウィンドウの内容を拡張します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を多く行っております。なるべく上部に配置してください。

 -- 画像規格 ----------------------------------------------------------------

  ★ ショップアイコン
   96 x 48 の画像（ShopSet）を "Graphics/System" にご用意ください。
   ※ 詳細はサイトの説明をご覧ください。

  ★ ショップフェイス
   96 x 24 の画像（ShopFase）を "Graphics/Fases" にご用意ください。
   ※ 詳細はサイトの説明をご覧ください。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO_ExSHOP
  # ステータス項目名（ＨＰ, ＭＰ, 攻撃力, 防御力, 精神力, 俊敏性）
  # 命中率と回避率は、Window_ShopStatus#refresh
  PARA_NAME = ["ＨＰ", "ＭＰ", "攻撃力", "防御力", "精神力", "俊敏性"]
  
  # 命中率と回避率を表示する
  PARA_PLUS = true
  
  # 画像を使用しない（true で、TEXT_ITEM_KIND "無効"）
  NO_GRAPHICS = true
  
  # アイテム分類名（アイテム、片手武器、両手武器、盾、頭防具、身体防具、装飾品）
  TEXT_ITEM_KIND = ["道具", "片手武器", "両手武器", "盾", "兜", "鎧", "装飾品"]
  
  # 装備中文字（画像を使用する場合は"無効"）
  TEXT_EQUIPS_ICON = "Ｅ"
  
  # 装備中文字の色
  COLOR_EQUIPS_ICON = Color.new(255, 216, 32)
  
  # アクターの画像を別に用意する
  SHOP_FASE = false
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_ShopStatus < Window_Base
  #--------------------------------------------------------------------------
  # ◎ 定数
  #--------------------------------------------------------------------------
  SLH = 28              # 行の高さ基準値 (Status Line Height)
  SMT = 16              # ステータス項目の位置調整 (Status Margin Top)
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    if @item != nil
      # 所持数の描画
      number = $game_party.item_number(@item)
      self.contents.font.color = system_color
      self.contents.draw_text(4, 0, 200, SLH, Vocab::Possession)
      self.contents.draw_text(4, 0, 200, SLH, "個", 2)
      self.contents.font.color = normal_color
      self.contents.draw_text(4, 0, 176, SLH, number, 2)
      # アイテムの分類アイコン描画
      draw_select_item(20, SLH * 2)
      # ステータスの項目名の描画
      self.contents.font.color = system_color
      if @item.is_a?(RPG::Item)
        for i in 0...6
          text = CAO_ExSHOP::PARA_NAME[i]
          self.contents.draw_text(0, SLH * (i + 3) + SMT, 64, SLH, text, 1)
        end
      else
        # 装備済み項目名の描画
        self.contents.draw_text(0, SLH * 3 + SMT, 64, SLH, "装備済", 1)
        # ステータスの増減
        for i in 0...4
          text = CAO_ExSHOP::PARA_NAME[i + 2]
          self.contents.draw_text(0, SLH * (i + 4) + SMT, 64, SLH, text, 1)
        end
        if CAO_ExSHOP::PARA_PLUS
          if @item.is_a?(RPG::Weapon)
            self.contents.draw_text(0, SLH * 8 + SMT, 64, SLH, "命中率", 1)
          else
            self.contents.draw_text(0, SLH * 8 + SMT, 64, SLH, "回避率", 1)
          end
        end
      end
      # アクターごとの項目描画
      for i in 0...$game_party.members.size
        x = 64 + 36 * i
        y = SLH * 2
        draw_character_face($game_party.members[i], x, y)
        draw_actor_parameter_item($game_party.members[i], x, y + SMT)
        draw_actor_parameter_change($game_party.members[i], x, y + SMT)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ アイテムの分類
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_select_item(x, y)
    if CAO_ExSHOP::NO_GRAPHICS
      if @item.is_a?(RPG::Item)
        text = CAO_ExSHOP::TEXT_ITEM_KIND[0]
      elsif @item.is_a?(RPG::Weapon)
        text = CAO_ExSHOP::TEXT_ITEM_KIND[@item.two_handed ? 1 : 2]
      else
        text = CAO_ExSHOP::TEXT_ITEM_KIND[@item.kind + 3]
      end
      self.contents.font.color = system_color
      self.contents.draw_text(0, SLH * 2, 64, SLH, text, 1)
    else
      if @item.is_a?(RPG::Item)
        rect = Rect.new(48, 0, 24, 24)
      elsif @item.is_a?(RPG::Weapon)
        rect = Rect.new(@item.two_handed ? 24 : 0, 0, 24, 24)
      else
        rect = Rect.new(24 * @item.kind, 24, 24, 24)
      end
      self.contents.blt(20, SLH * 2, Cache.system("ShopSet"), rect)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ アクターの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_character_face(actor, x, y)
    y += (SLH - 24) / 2
    alpha = @item.is_a?(RPG::Item) ? 255 : actor.equippable?(@item) ? 255 : 128
    rect = Rect.new(0, 0, 20, 20)
    rect.x = 96 * (actor.character_index % 4) + 38
    rect.y = 128 * (actor.character_index / 4) + 2
    self.contents.fill_rect(x + 6, y, 24, 24, Color.new(0, 0, 0, alpha))
    self.contents.fill_rect(x + 7, y + 1, 22, 22, Color.new(255,255,255,alpha))
    bitmap = Cache.character(actor.character_name)
    self.contents.blt(x + 8, y + 2, bitmap, rect, alpha)
  end
  # アクターの画像を別に用意する場合
  if CAO_ExSHOP::SHOP_FASE
  def draw_character_face(actor, x, y)
    index = actor.id - 1
    alpha = @item.is_a?(RPG::Item) ? 255 : actor.equippable?(@item) ? 255 : 128
    rect = Rect.new(index % 4 * 24, index / 4 * 24, 24, 24)
    bitmap = Cache.face("ShopFace")
    self.contents.blt(x + 6, y + (SLH - 24) / 2, bitmap, rect, alpha)
  end
  end  
  #--------------------------------------------------------------------------
  # ◎ アイテムの効果値の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_parameter_item(actor, x, y)
    return unless @item.is_a?(RPG::Item)    # アイテム以外なら中断
    for i in 0...6
      if @item.parameter_type != 0 && @item.parameter_type == i + 1
        self.contents.font.color = power_up_color
        text = sprintf("%+d", @item.parameter_points)
      else
        self.contents.font.color = normal_color
        text = "-"
      end
      self.contents.draw_text(x, y + SLH * (i + 1), 32, SLH, text, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ○ アクターの現装備と能力値変化の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_parameter_change(actor, x, y)
    return if @item.is_a?(RPG::Item)          # アイテムなら中断
    enabled = actor.equippable?(@item)        # 装備の有無
    alpha = enabled ? 255 : 128               # 装備不可なら半透明
    item_max = CAO_ExSHOP::PARA_PLUS ? 5 : 4  # 描画する項目数
    # 装備中のアイテムを取得
    if @item.is_a?(RPG::Weapon)
      equip_item = weaker_weapon(actor)
    elsif actor.two_swords_style and @item.kind == 0
      equip_item = nil
    else
      equip_item = actor.equips[1 + @item.kind]
    end
    # ステータスの増加量を描画
    if enabled
      # 装備済アイコン
      if (actor.equips[0] == @item) ||
          (@item.is_a?(RPG::Weapon) && actor.equips[1] == @item) ||
          (!@item.is_a?(RPG::Weapon) && actor.equips[1 + @item.kind] == @item)
        if CAO_ExSHOP::NO_GRAPHICS
          self.contents.font.color = CAO_ExSHOP::COLOR_EQUIPS_ICON
          t = CAO_ExSHOP::TEXT_EQUIPS_ICON
          self.contents.draw_text(x + 6, y + SLH, 24, SLH, t, 1)
        else
          rect = Rect.new(72, 0, 24, 24)
          self.contents.blt(x + 6, y + SLH, Cache.system("ShopSet"), rect)
        end
      end
      # 装備アイテムとの性能差
      change = []
      atk1 = equip_item == nil ? 0 : equip_item.atk
      atk2 = @item == nil ? 0 : @item.atk
      change << atk2 - atk1
      def1 = equip_item == nil ? 0 : equip_item.def
      def2 = @item == nil ? 0 : @item.def
      change << def2 - def1
      spi1 = equip_item == nil ? 0 : equip_item.spi
      spi2 = @item == nil ? 0 : @item.spi
      change << spi2 - spi1
      agi1 = equip_item == nil ? 0 : equip_item.agi
      agi2 = @item == nil ? 0 : @item.agi
      change << agi2 - agi1
      if CAO_ExSHOP::PARA_PLUS
        if @item.is_a?(RPG::Weapon)
          hit1 = equip_item == nil ? 0 : equip_item.hit
          hit2 = @item == nil ? 0 : @item.hit
          change << hit2 - hit1
        else
          eva1 = equip_item == nil ? 0 : equip_item.eva
          eva2 = @item == nil ? 0 : @item.eva
          change << eva2 - eva1
        end
      end
      for i in 0...item_max
        self.contents.font.color = text_color([0, 24, 25][change[i] <=> 0])
        text = change[i].zero? ? "-" : sprintf("%+d", change[i])
        self.contents.draw_text(x, y + SLH * (i + 2), 32, SLH, text, 1)
      end
    else  # 装備不可時
      for i in 0...item_max
        self.contents.font.color = normal_color
        self.contents.draw_text(x, y + SLH * (i + 2), 32, SLH, "-", 1)
      end
    end
  end
end
