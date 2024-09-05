#=============================================================================
#  [RGSS2] ショップコメント - v1.0.0
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
  メモ欄によるアイテムの詳細情報入力機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 再定義を多く行っております。なるべく上部に配置してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ コメントの設定
   データベースのメモ欄に">SHOP_TEXT"と">END"を記述し、
   その間にコメントを記述してください。

  ★ 未設定コメントの変更
   Window_ShopStatus#read_item_note 内の "NO DATA" を
   変更することで未設定アイテムの表示内容を変更できます。
   何も表示したくない場合は、""としてください。


=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#      このスクリプトには設定項目はありません。そのままお使いください。       #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_ShopStatus < Window_Base
  alias _cao_initialize_ExShop2 initialize
  def initialize(x, y)
    @slide_l = false
    @slide_r = false
    @item_bak = nil
    _cao_initialize_ExShop2 (x, y)
  end
  def create_contents
    self.contents.dispose
    self.contents = Bitmap.new((width - 32) * 2, height - 32)
  end
  def update
    super
    if self.visible
      refresh_right if self.ox >= self.width - 32 && @item_bak != @item
      @item_bak = @item
      if @slide_l
        self.ox += 32
        if self.ox > self.width - 32
          self.ox = self.width - 32
          @slide_l = false
        end
      elsif @slide_r
        self.ox -= 32
        if self.ox < 0
          self.ox = 0
          @slide_r = false
        end
      end
      if Input.trigger?(Input::A)
        Sound.play_decision
        if self.ox < self.width - 32
          refresh_right
          @slide_l = true
          @slide_r = false
        else
          @slide_l = false
          @slide_r = true
        end
      end
    end
  end
  def refresh_right
    if @item != nil
      w = self.contents.width / 2
      self.contents.font.color = normal_color
      self.contents.clear_rect(w, 0, w, self.contents.height)
      text = read_item_note
      for i in 0...text.size
        self.contents.draw_text(w, WLH * i, 204, WLH, text[i])
      end
    end
  end
  def read_item_note
    text = "NO DATA"
    if /^>SHOP_TEXT\n(.*?)\n>END$/m =~ @item.note.delete("\r")
      text = $1.gsub("\\n", "\n")
    end
    return text.split("\n")
  end
end
