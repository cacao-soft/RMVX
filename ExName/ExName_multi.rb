#=============================================================================
#  [RGSS2] マルチインプット - v2.0.2
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

  - 全角・半角で入力文字数を制限します。
  - 半角カナ入力が可能になります。
  - 最大文字数、全角１６文字・半角３２文字。

 -- 注意事項 ----------------------------------------------------------------

  ※ 『＜拡張＞ 名前入力の処理』の拡張スクリプトです。
  ※ 『＜拡張＞ 名前入力の処理』より下に配置してください。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   このスクリプトには設定項目はありません。                  #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_NameEdit < Window_Base
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     actor    : アクター
  #--------------------------------------------------------------------------
  def initialize(actor)
    case CAO::ExInput::EDIT_TYPE
    when 0  # 歩行グラ（中）
      super(22, 44, 500, 64)
    when 1  # 歩行グラ（下）
      super(22, 52, 500, 64)
    else    # 顔グラ
      super(22, 20, 500, 128)
    end
    self.active = false
    self.opacity = 0 unless CAO::ExInput::WINDOW_VISIBLE
    if actor.is_a?(Game_Actor)
      @actor = actor
      @name = actor.name
    else
      @actor = $game_variables[$game_temp.name_actor_id]
      @name = @actor.is_a?(String) ? @actor : ""
    end
    @max_char = $game_temp.name_max_char  # 最大入力文字数
    @max_half = @max_char * 2             # 最大入力文字数（半角）
    name_array = []
    size = 0
    for s in @name.split(//)
      size += char_size(s)
      break if @max_half < size
      name_array.push(s)
    end
    @name = name_array.to_s     # 入力文字
    @default_name = @name       # 最初の入力文字
    @index = name_array.size
    refresh
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ○ 文字の追加
  #     character : 追加する文字
  #--------------------------------------------------------------------------
  def add(character)
    if can_input?(character) and character != ""
      @name += character
      @index += character.split(//).size
      refresh
      update_cursor
    end
  end
  #--------------------------------------------------------------------------
  # ○ 文字の削除
  #--------------------------------------------------------------------------
  def back
    if @index > 0
      name_array = @name.split(//)          # 一字削除
      @name = ""
      for i in 0...name_array.size-1
        @name += name_array[i]
      end
      @index -= 1
      refresh
      update_cursor
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 全角・半角の判定（サイズ）
  #--------------------------------------------------------------------------
  def char_size(str)
    return (str.nil? || str.size == 1 || str.match(/^[｡-ﾟ]$/)) ? 1 : 2
  end
  #--------------------------------------------------------------------------
  # ◎ 半角に換算した場合の文字列のサイズ
  #--------------------------------------------------------------------------
  def half_size(name)
    size = 0
    name_array = name.split(//)
    for c in name_array
      size += char_size(c)
    end
    return size
  end
  #--------------------------------------------------------------------------
  # ◎ 半角に換算した場合の文字配列
  #--------------------------------------------------------------------------
  def half_array
    name_array = @name.split(//)
    half_array = []
    for c in name_array
      half_array.push(c)
      half_array.push(c) if char_size(c) == 2
    end
    return half_array
  end
  #--------------------------------------------------------------------------
  # ◎ 入力可能判定
  #--------------------------------------------------------------------------
  def can_input?(str = "")
    if str && str != ""
      return char_size(str) <= (@max_half - half_size(@name))
    else
      return half_size(@name) < @max_half
    end
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    if $game_temp.name_walk
      if CAO::ExInput::EDIT_TYPE < 2
        draw_actor_graphic(@actor, 16, 32)
      else
        draw_actor_face(@actor, 0, 0)
        draw_actor_graphic(@actor, 20, 92) if CAO::ExInput::EDIT_TYPE == 3
      end
    end
    name_array = @name.split(//)
    if CAO::ExInput::EDIT_TYPE < 2
      gw = ($game_temp.name_walk ? 36 : 0)
      rect = Rect.new(0, 6, 12, WLH)
    else
      gw = ($game_temp.name_walk ? 100 : 0)
      rect = Rect.new(0, 36, 12, WLH)
    end
    self.contents.font.color = normal_color
    last_name = ""
    for i in 0...name_array.size
      rect.x = 12 * half_size(last_name) + gw + margin_graphics
      rect.width = 12 * char_size(name_array[i])
      self.contents.draw_text(rect, name_array[i], 1)
      last_name += name_array[i]
    end
    rect.width = 12
    for i in 0...((@max_char * 2) - half_size(last_name))
      rect.x = 12 * (i + half_size(last_name)) + gw + margin_graphics
      self.contents.draw_text(rect, '_', 1)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    if CAO::ExInput::EDIT_TYPE < 2
      gw = ($game_temp.name_walk ? 36 : 0)
    else
      gw = ($game_temp.name_walk ? 100 : 0)
    end
    name_array = @name.split(//)
    lw = 0
    for i in 0...index
      lw += 12 * char_size(name_array[i])
    end
    rect = Rect.new(0, 0, 0, 0)
    rect.x = lw + gw + margin_graphics
    rect.y = (CAO::ExInput::EDIT_TYPE < 2) ? 6 : 38
    rect.width = 12 * char_size(name_array[index])
    rect.height = WLH
    return rect
  end
  #--------------------------------------------------------------------------
  # ◎ 定型名のランダム取得
  #--------------------------------------------------------------------------
  def random_name
    if FIXED_PHRASE != []
      name = FIXED_PHRASE[rand(FIXED_PHRASE.size)]
      @name = ""
      size = 0
      for s in name.split(//)
        size += char_size(s)
        break if @max_half < size
        @name.concat(s)
      end
      @index = @name.split(//).size
      refresh
      return true
    end
    return false
  end
end
