#=============================================================================
#  [RGSS2] Cacao Base Script - v1.3.2
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

  ＣＡＣＡＯが制作したスクリプトを使う際に必要になります。

 -- 注意事項 ----------------------------------------------------------------

  ※ 必ず他のＣＡＣＡＯ製スクリプトより上に配置してください。
  ※ できるだけ他のスクリプトより上に配置してください。
  ※ 特に理由がない限り、最新版をお使いください。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


CAO = Module.new
CustomizeError = Class.new(StandardError)

class Object
  #--------------------------------------------------------------------------
  # ● 深いコピー
  #--------------------------------------------------------------------------
  def marshal_copy
    return Marshal.load(Marshal.dump(self))
  end
end

class Array
  #--------------------------------------------------------------------------
  # ● 要素の入れ替え
  #     pos1   : 入れ替える要素の位置 Ａ
  #     pos2   : 入れ替える要素の位置 Ｂ
  #     return : 自身の配列
  #--------------------------------------------------------------------------
  def swap(pos1, pos2)
    self[pos1], self[pos2] = self[pos2], self[pos1]
    return self
  end
  #--------------------------------------------------------------------------
  # ● 要素の移動
  #     src_pos  : 移動する要素の位置
  #     dest_pos : 移動先の位置
  #     return   : 自身の配列
  #--------------------------------------------------------------------------
  def move(src_pos, dest_pos)
    self.insert(dest_pos, self.delete_at(src_pos))
    return self
  end
end

class Rect
  #--------------------------------------------------------------------------
  # ◎ 配列に変換
  #     return : [ｘ座標, ｙ座標, 横幅, 縦幅]
  #--------------------------------------------------------------------------
  def to_a
    return self.x, self.y, self.width, self.height
  end
end

class Point
  attr_accessor :x, :y
  #--------------------------------------------------------------------------
  # ● オブジェクトの初期化
  #--------------------------------------------------------------------------
  def initialize(x, y)
    @x = x
    @y = y
  end
  #--------------------------------------------------------------------------
  # ◎ 配列に変換
  #     return : [ｘ座標, ｙ座標]
  #--------------------------------------------------------------------------
  def to_a
    return @x, @y
  end
end

class Color
  #--------------------------------------------------------------------------
  # ◎ 配列に変換
  #     return : [赤, 緑, 青, 不透明度]
  #--------------------------------------------------------------------------
  def to_a
    return self.red, self.green, self.blue, self.alpha
  end
end

class RPG::Time
  #--------------------------------------------------------------------------
  # ● ゲーム開始からの合計秒数の取得
  #--------------------------------------------------------------------------
  def self.total
    return Graphics.frame_count / Graphics.frame_rate
  end
  #--------------------------------------------------------------------------
  # ● プレイ時間を配列で取得 (時間, 分数, 秒数)
  #--------------------------------------------------------------------------
  def self.to_a
    total = RPG::Time.total
    return (total / 3600), (total / 60 % 60), (total % 60)
  end
  #--------------------------------------------------------------------------
  # ● プレイ時間を文字列で取得 (999/59/59)
  #--------------------------------------------------------------------------
  def self.to_s(format = "%03d:%02d:%02d")
    return sprintf(format, *RPG::Time.to_a)
  end
end

module Cache
  #--------------------------------------------------------------------------
  # ● キャッシュの有無を確認
  #     filename : ファイル名
  #--------------------------------------------------------------------------
  def self.bitmap?(filename)
    @cache ||= {}
    return false if @cache[filename] == nil
    return false if @cache[filename].disposed?
    return true
  end
  #--------------------------------------------------------------------------
  # ● ビットマップの取得と設定
  #     filename : ファイル名
  #     bitmap   : キャッシュするビットマップ
  #--------------------------------------------------------------------------
  def self.bitmap(filename, bitmap = nil)
    @cache ||= {}
    if bitmap
      @cache[filename].dispose if bitmap?(filename)
      @cache[filename] = bitmap
    end
    return @cache[filename]
  end
  #--------------------------------------------------------------------------
  # ● ビットマップの消去
  #     filename : ファイル名
  #--------------------------------------------------------------------------
  def self.remove(filename)
    @cache ||= {}
    return unless @cache[filename]
    @cache[filename].dispose
    @cache.delete(filename)
  end
end

class Bitmap
  #--------------------------------------------------------------------------
  # ● ビットマップをキャッシュ
  #--------------------------------------------------------------------------
  def to_cache(filename)
    Cache.bitmap(filename, self)
  end
end

class Game_Map
  #--------------------------------------------------------------------------
  # ● データベースのロード
  #--------------------------------------------------------------------------
  $data_mapinfos ||= load_data("Data/MapInfos.rvdata")
  #--------------------------------------------------------------------------
  # ● 現在地名
  #--------------------------------------------------------------------------
  #     check_area : エリア名を含めた現在地名を取得する
  #     convert    : 制御文字を削除する
  #--------------------------------------------------------------------------
  def name(check_area = true, convert = true)
    if check_area
      for area in $data_areas.values
        next unless in_area?(area)
        break if /^\!/ =~ area.name
        return convert_text(area.name)
      end
    end
    return map_name(convert)
  end
  #--------------------------------------------------------------------------
  # ● マップ名を取得
  #--------------------------------------------------------------------------
  #     convert : 制御文字を削除する
  #--------------------------------------------------------------------------
  def map_name(convert = false)
    name = $data_mapinfos[$game_map.map_id].name
    return convert ? convert_text(name) : name
  end
  #--------------------------------------------------------------------------
  # ● エリア名を取得
  #--------------------------------------------------------------------------
  #     convert : 制御文字を削除する
  #--------------------------------------------------------------------------
  def area_name(convert = false)
    list = []
    for area in $data_areas.values
      list << area.name if in_area?(area)
    end
    return convert ? list.map {|t| convert_text(t)} : list
  end
  #--------------------------------------------------------------------------
  # ● エリア内判定
  #     area : エリアデータ (RPG::Area)
  #--------------------------------------------------------------------------
  def in_area?(area)
    x, y = $game_player.x, $game_player.y
    return false if area == nil
    return false if $game_map.map_id != area.map_id
    return false if x < area.rect.x
    return false if y < area.rect.y
    return false if x >= area.rect.x + area.rect.width
    return false if y >= area.rect.y + area.rect.height
    return true
  end
  #--------------------------------------------------------------------------
  # ● 制御文字の削除
  #--------------------------------------------------------------------------
  def convert_text(text)
    text = text.dup
    text.sub!(/^[!$&%*@]/, "") while (/^[!$&%*@]/ =~ text)
    text.gsub!(/<%.*?>/i, "")
    text.gsub!(/#\{.*?\}/i, "")
    text.gsub!(/#.*/i, "")
    text.strip!
    return text
  end
end

module Vocab
  #--------------------------------------------------------------------------
  # ● 経験値
  #--------------------------------------------------------------------------
  def self.exp
    return "経験値"
  end
  #--------------------------------------------------------------------------
  # ● 経験値の略称
  #--------------------------------------------------------------------------
  def self.exp_a
    return "Ｅ"
  end
end

class Game_Actor
  #--------------------------------------------------------------------------
  # ● レベルアップに必要な経験値の取得
  #--------------------------------------------------------------------------
  def level_up_exp
    return (@level < 99) ? (@exp_list[@level + 1] - @exp_list[@level]) : 0
  end
  #--------------------------------------------------------------------------
  # ● レベルアップに必要な残り経験値の取得
  #--------------------------------------------------------------------------
  def next_rest_exp
    return (@exp_list[@level + 1] > 0) ? (@exp_list[@level + 1] - @exp) : 0
  end
  #--------------------------------------------------------------------------
  # ● レベル単位の経験値の取得
  #--------------------------------------------------------------------------
  def level_exp
    return level_up_exp - next_rest_exp
  end
end

class Window_Base
  #--------------------------------------------------------------------------
  # ● EXP の文字色を取得
  #     actor : アクター
  #--------------------------------------------------------------------------
  def exp_color(actor)
    return power_up_color if actor.next_rest_exp < actor.level_up_exp / 4
    return normal_color
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
  # ● 経験値の描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_exp(actor, x, y, width = 120)
    draw_actor_exp_gauge(actor, x, y, width)
    self.contents.font.color = system_color
    text = (width < 170 ? Vocab.exp_a : Vocab.exp)
    self.contents.draw_text(x, y, 60, WLH, text)
    xr = x + width
    if width < 130
      self.contents.font.color = exp_color(actor)
      self.contents.draw_text(xr - 60, y, 60, WLH, actor.next_rest_exp, 2)
    else
      self.contents.font.color = exp_color(actor)
      self.contents.draw_text(xr - 110, y, 50, WLH, actor.level_exp, 2)
      self.contents.font.color = normal_color
      self.contents.draw_text(xr - 60, y, 10, WLH, "/", 1)
      self.contents.draw_text(xr - 50, y, 50, WLH, actor.level_up_exp, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● 経験値ゲージの描画
  #     actor : アクター
  #     x     : 描画先 X 座標
  #     y     : 描画先 Y 座標
  #     width : 幅
  #--------------------------------------------------------------------------
  def draw_actor_exp_gauge(actor, x, y, width = 120)
    gw = width * actor.level_exp / [actor.level_up_exp, 1].max
    gc1 = exp_gauge_color1
    gc2 = exp_gauge_color2
    self.contents.fill_rect(x, y + WLH - 8, width, 6, gauge_back_color)
    self.contents.gradient_fill_rect(x, y + WLH - 8, gw, 6, gc1, gc2)
  end
end
