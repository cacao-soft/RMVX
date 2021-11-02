#=============================================================================
#  [RGSS2] ＜拡張＞ ショップステータス ＋ - v1.0.3
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

  ＫＧＣさんの「装備拡張」スクリプトに対応させます。
  同種の防具がある場合は、最も性能の低い防具で比較します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 「＜拡張＞ ショップステータス」v1.0.3 で動作確認を行っております。
  ※ ＫＧＣさんの「装備拡張」Ver.2009/08/18 で動作確認を行っております。

 -- 使用方法 ----------------------------------------------------------------

  ★ 次の順番で設置してください。
   「装備拡張」、「＜拡張＞ ショップステータス」、「このスクリプト」。

  ★ ショップアイコン
   96 x 48~ の画像（ShopSet）を "Graphics/System" にご用意ください。
   １アイコン 24x24 の画像を横に４つ縦に２つ以上並べたものを使用します。
   １列目は、『アイテム・片手武器・両手武器・装備中』と決まっています。
   ２列目以降は、左から順に防具のアイコンを並べてください。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_ShopStatus < Window_Base
  #--------------------------------------------------------------------------
  # ◎ アイテムの分類
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_select_item(x, y)
    if CAO_ExSHOP::NO_GRAPHICS
      t = CAO_ExSHOP::TEXT_ITEM_KIND + KGC::EquipExtension::EXTRA_EQUIP_KIND
      if @item.is_a?(RPG::Item)
        text = t[0]
      elsif @item.is_a?(RPG::Weapon)
        text = t[@item.two_handed ? 1 : 2]
      else
        text = t[@item.kind + 3]
      end
      self.contents.font.color = system_color
      self.contents.draw_text(0, SLH * 2, 64, SLH, text, 1)
    else
      if @item.is_a?(RPG::Item)
        rect = Rect.new(48, 0, 24, 24)
      elsif @item.is_a?(RPG::Weapon)
        rect = Rect.new(@item.two_handed ? 24 : 0, 0, 24, 24)
      else
        x = @item.kind % 4 * 24
        y = @item.kind / 4 * 24 + 24
        rect = Rect.new(x, y, 24, 24)
      end
      self.contents.blt(20, SLH * 2, Cache.system("ShopSet"), rect)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ アクターの現装備と能力値変化の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_parameter_change(actor, x, y)
    return if @item.is_a?(RPG::Item)    # アイテムなら中断
    enabled = actor.equippable?(@item)  # 装備の有無
    alpha = enabled ? 255 : 128         # 装備不可なら半透明
    item_max = CAO_ExSHOP::PARA_PLUS ? 5 : 4  # 描画する項目数
    # 装備中のアイテムを取得
    if @item.is_a?(RPG::Weapon)
      equip_item = weaker_weapon(actor)
    elsif actor.two_swords_style and @item.kind == 0
      equip_item = nil
    else
      equip_item = weaker_armor(actor, @item.kind)
    end
    # 装備可能ならばステータスを描画
    if enabled
      # 装備中マークの判定
      if @item.is_a?(RPG::Weapon)
        armed_with = (actor.weapons[0] == @item) || (actor.weapons[1] == @item)
      else
        for armor in actor.armors
          armed_with = (armor == @item)
          break if armed_with
        end
      end
      if armed_with
        if CAO_ExSHOP::NO_GRAPHICS  # 装備中マーク（テキスト）
          self.contents.font.color = CAO_ExSHOP::COLOR_EQUIPS_ICON
          t = CAO_ExSHOP::TEXT_EQUIPS_ICON
          self.contents.draw_text(x + 6, y + SLH, 24, SLH, t, 1)
        else                        # 装備中マーク（画像）
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
      if @item.is_a?(RPG::Weapon)
        hit1 = equip_item == nil ? 0 : equip_item.hit
        hit2 = @item == nil ? 0 : @item.hit
        change << hit2 - hit1
      else
        eva1 = equip_item == nil ? 0 : equip_item.eva
        eva2 = @item == nil ? 0 : @item.eva
        change << eva2 - eva1
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
  #--------------------------------------------------------------------------
  # ◎ アクターが装備している最も弱い防具の取得
  #     actor : アクター
  #     kind  : 防具の種類
  #--------------------------------------------------------------------------
  def weaker_armor(actor, kind)
    armors = []
    actor.equip_type.each_with_index do |k,i|
      next if kind != k
      return nil unless actor.armors[i]
      armors << actor.armors[i]
    end
    armors.sort! {|a,b| a.atk+a.def+a.spi+a.agi <=> b.atk+b.def+b.spi+b.agi }
    return armors.first
  end
end
