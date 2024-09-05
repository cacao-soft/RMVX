#=============================================================================
#  [RGSS2] Custom Menu Canvas Plus - v1.1.4
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

  カスタムメニューのベーススクリプトの拡張パッチです。
  主に他サイトのステータス項目を描画する際に使用されます。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトは、Custom Menu Canvas の下に導入してください。
  ※ 追加項目のスクリプトは、このスクリプトより上に設置してください。
  ※ 現在、ステータスによっては対応していないものがあります。
  ※ 拡張機能は競合などの関係で変更・削除される場合があります。

 -- 追加項目 ----------------------------------------------------------------

  ・ KGC「オーバードライブ」Ver.2009/11/01
  ・ KGC「汎用ゲージ描画」Ver.2009/09/26

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class CustomMenu_Canvas
  #============================================================================
  # ● 初期設定
  #============================================================================
  $imported ||= {}                        # ＫＧＣ導入スクリプト確認用
  #--------------------------------------------------------------------------
  # ○ ステータス拡張項目の描画
  #     actor  : アクター
  #     x      : 描画先 X 座標
  #     y      : 描画先 Y 座標
  #     params : オプション
  #--------------------------------------------------------------------------
  def draw_ext_item(actor, x, y, params)
    case params[0]
    when :name_od
      width = params[3] ? params[3] : 120
      draw_actor_od_name(actor, x, y, width)
    when :od
      width = params[3] ? params[3] : 120
      draw_actor_od_gauge(actor, x, y, width)
    end
  end
end

#==============================================================================
# ■ オーバードライブ
#------------------------------------------------------------------------------
# 　KGC Software
#==============================================================================
if $imported["OverDrive"]
class CustomMenu_Canvas
  #--------------------------------------------------------------------------
  # ● ドライブゲージの通常時の色 1 の取得
  #--------------------------------------------------------------------------
  def od_gauge_normal_color1
    color = KGC::OverDrive::GAUGE_NORMAL_START_COLOR
    return (color.is_a?(Integer) ? text_color(color) : color)
  end
  #--------------------------------------------------------------------------
  # ● ドライブゲージの通常時の色 2 の取得
  #--------------------------------------------------------------------------
  def od_gauge_normal_color2
    color = KGC::OverDrive::GAUGE_NORMAL_END_COLOR
    return (color.is_a?(Integer) ? text_color(color) : color)
  end
  #--------------------------------------------------------------------------
  # ● ドライブゲージの最大時の色 1 の取得
  #--------------------------------------------------------------------------
  def od_gauge_max_color1
    color = KGC::OverDrive::GAUGE_MAX_START_COLOR
    return (color.is_a?(Integer) ? text_color(color) : color)
  end
  #--------------------------------------------------------------------------
  # ● ドライブゲージの最大時の色 2 の取得
  #--------------------------------------------------------------------------
  def od_gauge_max_color2
    color = KGC::OverDrive::GAUGE_MAX_END_COLOR
    return (color.is_a?(Integer) ? text_color(color) : color)
  end
  #--------------------------------------------------------------------------
  # ● 名前の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #--------------------------------------------------------------------------
  def draw_actor_od_name(actor, x, y, width = 108)
    draw_actor_od_gauge(actor, x, y, width)
    draw_actor_name(actor, x, y, width)
  end
  #--------------------------------------------------------------------------
  # ● ドライブゲージの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_od_gauge(actor, x, y, width = 120)
    return unless actor.od_gauge_visible?
    n = actor.overdrive % KGC::OverDrive::GAUGE_MAX
    n = KGC::OverDrive::GAUGE_MAX if actor.overdrive_max?
    if KGC::OverDrive::ENABLE_GENERIC_GAUGE && $imported["GenericGauge"]
      # 汎用ゲージ
      file = (actor.overdrive_max? ?
        KGC::OverDrive::GAUGE_MAX_IMAGE : KGC::OverDrive::GAUGE_IMAGE)
      draw_gauge(file,
        x, y, width, n, KGC::OverDrive::GAUGE_MAX,
        KGC::OverDrive::GAUGE_OFFSET,
        KGC::OverDrive::GAUGE_LENGTH,
        KGC::OverDrive::GAUGE_SLOPE)
    else
      # デフォルトゲージ
      gy = y + WLH + KGC::OverDrive::GAUGE_OFFSET_Y
      gw = width * n / KGC::OverDrive::GAUGE_MAX
      gc1 = (gw == width ? od_gauge_max_color1 : od_gauge_normal_color1)
      gc2 = (gw == width ? od_gauge_max_color2 : od_gauge_normal_color2)
      self.fill_rect(x, gy, width, 6, gauge_back_color)
      self.gradient_fill_rect(x, gy, gw, 6, gc1, gc2)
    end
    draw_actor_od_gauge_value(actor, x, y, width)
  end
  #--------------------------------------------------------------------------
  # ● ドライブゲージの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_od_gauge_value(actor, x, y, width = 120)
    text = ""
    value = actor.overdrive * 100.0 / KGC::OverDrive::GAUGE_MAX
    case KGC::OverDrive::GAUGE_VALUE_STYLE
    when KGC::OverDrive::ValueStyle::IMMEDIATE
      text = actor.overdrive.to_s
    when KGC::OverDrive::ValueStyle::RATE
      text = sprintf("%d%%", actor.overdrive * 100 / KGC::OverDrive::GAUGE_MAX)
    when KGC::OverDrive::ValueStyle::RATE_DETAIL1
      text = sprintf("%0.1f%%", value)
    when KGC::OverDrive::ValueStyle::RATE_DETAIL2
      text = sprintf("%0.2f%%", value)
    when KGC::OverDrive::ValueStyle::NUMBER
      text = "#{actor.overdrive / KGC::OverDrive::GAUGE_MAX}"
    else
      return
    end
    last_font_size = self.font.size
    new_font_size = KGC::OverDrive::GAUGE_VALUE_FONT_SIZE
    self.font.size = new_font_size
    y += WLH + KGC::OverDrive::GAUGE_OFFSET_Y - new_font_size / 2
    self.draw_text(x, y, width, new_font_size, text, 2)
    self.font.size = last_font_size
  end
end # CustomMenu_Canvas
end # $imported["OverDrive"]

#==============================================================================
# ■ 汎用ゲージ描画
#------------------------------------------------------------------------------
# 　KGC Software
#==============================================================================
if $imported["GenericGauge"]
class CustomMenu_Canvas
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  # ゲージ転送元座標 [x, y]
  GAUGE_SRC_POS = {
    :normal   => [ 0, 24],
    :decrease => [ 0, 48],
    :increase => [72, 48],
  }
  #--------------------------------------------------------------------------
  # ● クラス変数
  #--------------------------------------------------------------------------
  @@__gauge_buf = Bitmap.new(320, 24)
  #--------------------------------------------------------------------------
  # ● ゲージ描画
  #     file       : ゲージ画像ファイル名
  #     x, y       : 描画先 X, Y 座標
  #     width      : 幅
  #     value      : 現在値
  #     limit      : 上限値
  #     offset     : 座標調整 [x, y]
  #     len_offset : 長さ調整
  #     slope      : 傾き
  #     gauge_type : ゲージタイプ
  #--------------------------------------------------------------------------
  def draw_gauge(file, x, y, width, value, limit, offset, len_offset, slope,
      gauge_type = :normal)
    img    = Cache.system(file)
    x     += offset[0]
    y     += offset[1]
    width += len_offset
    draw_gauge_base(img, x, y, width, slope)
    gw = width * value / limit
    draw_gauge_bar(img, x, y, width, gw, slope, GAUGE_SRC_POS[gauge_type])
  end
  #--------------------------------------------------------------------------
  # ● ゲージベース描画
  #     img   : ゲージ画像
  #     x, y  : 描画先 X, Y 座標
  #     width : 幅
  #     slope : 傾き
  #--------------------------------------------------------------------------
  def draw_gauge_base(img, x, y, width, slope)
    rect = Rect.new(0, 0, 24, 24)
    if slope != 0
      self.skew_blt(x, y, img, rect, slope)
      rect.x = 96
      self.skew_blt(x + width + 24, y, img, rect, slope)

      rect.x     = 24
      rect.width = 72
      dest_rect = Rect.new(0, 0, width, 24)
      @@__gauge_buf.clear
      @@__gauge_buf.stretch_blt(dest_rect, img, rect)
      self.skew_blt(x + 24, y, @@__gauge_buf, dest_rect, slope)
    else
      self.blt(x, y, img, rect)
      rect.x = 96
      self.blt(x + width + 24, y, img, rect)
      rect.x     = 24
      rect.width = 72
      dest_rect = Rect.new(x + 24, y, width, 24)
      self.stretch_blt(dest_rect, img, rect)
    end
  end
  #--------------------------------------------------------------------------
  # ● ゲージ内部描画
  #     img     : ゲージ画像
  #     x, y    : 描画先 X, Y 座標
  #     width   : 全体幅
  #     gw      : 内部幅
  #     slope   : 傾き
  #     src_pos : 転送元座標 [x, y]
  #     start   : 開始位置
  #--------------------------------------------------------------------------
  def draw_gauge_bar(img, x, y, width, gw, slope, src_pos, start = 0)
    rect = Rect.new(src_pos[0], src_pos[1], 72, 24)
    dest_rect = Rect.new(0, 0, width, 24)
    @@__gauge_buf.clear
    @@__gauge_buf.stretch_blt(dest_rect, img, rect)
    dest_rect.x     = start
    dest_rect.width = gw
    x += start
    if slope != 0
      self.skew_blt(x + 24, y, @@__gauge_buf, dest_rect, slope)
    else
      self.blt(x + 24, y, @@__gauge_buf, dest_rect)
    end
  end
  #--------------------------------------------------------------------------
  # ○ HP ゲージの描画
  #     actor : アクター
  #     x, y  : 描画先 X, Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_hp_gauge(actor, x, y, width = 120)
    draw_gauge(KGC::GenericGauge::HP_IMAGE,
      x, y, width, actor.hp, actor.maxhp,
      KGC::GenericGauge::HP_OFFSET,
      KGC::GenericGauge::HP_LENGTH,
      KGC::GenericGauge::HP_SLOPE
    )
  end
  #--------------------------------------------------------------------------
  # ○ MP ゲージの描画
  #     actor : アクター
  #     x, y  : 描画先 X, Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_mp_gauge(actor, x, y, width = 120)
    draw_gauge(KGC::GenericGauge::MP_IMAGE,
      x, y, width, actor.mp, [actor.maxmp, 1].max,
      KGC::GenericGauge::MP_OFFSET,
      KGC::GenericGauge::MP_LENGTH,
      KGC::GenericGauge::MP_SLOPE
    )
  end
  #--------------------------------------------------------------------------
  # ○ Exp ゲージの描画
  #     actor : アクター
  #     x, y  : 描画先 X, Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_exp_gauge(actor, x, y, width = 120)
    diff = [actor.next_diff_exp, 1].max
    rest = [actor.next_rest_exp, 1].max
    draw_gauge(KGC::GenericGauge::EXP_IMAGE,
      x, y, width, diff - rest, diff,
      KGC::GenericGauge::EXP_OFFSET,
      KGC::GenericGauge::EXP_LENGTH,
      KGC::GenericGauge::EXP_SLOPE
    )
  end
end # class CustomMenu_Canvas

class Window_CustomMenuStatus < Window_Selectable
  #--------------------------------------------------------------------------
  # ○ NextExp の描画
  #     actor : アクター
  #     x, y  : 描画先 X, Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_exp(actor, x, y, width = 120)
    draw_actor_next_exp(actor, x, y, width)
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, width, WLH, Vocab.exp_a)
  end
end # class Window_CustomMenuStatus
end # if $imported["GenericGauge"]
