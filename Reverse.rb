#=============================================================================
#  [RGSS2] ピクチャの反転 - v1.0.1
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

  ピクチャを反転する機能を追加します。

 -- 使用方法 ----------------------------------------------------------------

  ★ ピクチャを反転する。
   ラベルに "Ｐ反転[n]" と記述
   § screen.pictures[n].mirror ^= true

  ★ ピクチャを元の向きにする。
   ラベルに "Ｐ正向[n]" と記述
   § screen.pictures[n].mirror = true

  ★ ピクチャを反対の向きする。
   ラベルに "Ｐ反向[n]" と記述
   § screen.pictures[n].mirror = false

  ※ n ： ピクチャの番号

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Picture
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :mirror
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_picture initialize
  def initialize(number)
    _cao_initialize_picture(number)
    @mirror = false
  end
  #--------------------------------------------------------------------------
  # ○ ピクチャの表示
  #     name         : ファイル名
  #     origin       : 原点
  #     x            : X 座標
  #     y            : Y 座標
  #     zoom_x       : X 方向拡大率
  #     zoom_y       : Y 方向拡大率
  #     opacity      : 不透明度
  #     blend_type   : ブレンド方法
  #--------------------------------------------------------------------------
  alias _cao_show_picture show
  def show(name, origin, x, y, zoom_x, zoom_y, opacity, blend_type)
    _cao_show_picture(name, origin, x, y, zoom_x, zoom_y, opacity, blend_type)
    @mirror = false
  end
end

class Sprite_Picture < Sprite
  alias _cao_update_picture update
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    _cao_update_picture
    self.mirror = @picture.mirror if @picture_name != ""
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_picture command_118
  def command_118
    case @params[0]
    when /^Ｐ反転\[(\d+)\]/
      screen.pictures[$1.to_i].mirror ^= true
    when /^Ｐ正向\[(\d+)\]/
      screen.pictures[$1.to_i].mirror = true
    when /^Ｐ反向\[(\d+)\]/
      screen.pictures[$1.to_i].mirror = false
    end
    _cao_command_118_picture
  end
end
