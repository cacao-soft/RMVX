#=============================================================================
#  [RGSS2] 解像度の変更 - v1.0.0
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

  解像度の変更を行い、マップと戦闘背景の位置を調整します。

 -- 注意事項 ----------------------------------------------------------------

  ※ エイリアスなしの再定義を行っています。VX_SP2 の下に導入してください。
  ※ ウィンドウの位置やサイズは変更されません。

=end


# 解像度の変更
Graphics.resize_screen(640, 480)


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


CustomizeError = Class.new(StandardError)

module Graphics
  #--------------------------------------------------------------------------
  # ● 画面に表示される横幅 (タイル数)
  #--------------------------------------------------------------------------
  def self.map_width
    return Graphics.width / 32
  end
  #--------------------------------------------------------------------------
  # ● 画面に表示される縦幅 (タイル数)
  #--------------------------------------------------------------------------
  def self.map_height
    return Graphics.height / 32
  end
end

class Sprite_Base < Sprite
  #--------------------------------------------------------------------------
  # ○ アニメーションの開始
  #--------------------------------------------------------------------------
  def start_animation(animation, mirror = false)
    dispose_animation
    @animation = animation
    return if @animation == nil
    @animation_mirror = mirror
    @animation_duration = @animation.frame_max * 4 + 1
    load_animation_bitmap
    @animation_sprites = []
    if @animation.position != 3 or not @@animations.include?(animation)
      if @use_sprite
        for i in 0..15
          sprite = ::Sprite.new(viewport)
          sprite.visible = false
          @animation_sprites.push(sprite)
        end
        unless @@animations.include?(animation)
          @@animations.push(animation)
        end
      end
    end
    if @animation.position == 3
      if viewport == nil
        @animation_ox = Graphics.width / 2
        @animation_oy = Graphics.height / 2
      else
        @animation_ox = viewport.rect.width / 2
        @animation_oy = viewport.rect.height / 2
      end
    else
      @animation_ox = x - ox + width / 2
      @animation_oy = y - oy + height / 2
      if @animation.position == 0
        @animation_oy -= height / 2
      elsif @animation.position == 2
        @animation_oy += height / 2
      end
    end
  end
end
class Sprite_Timer < Sprite
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     viewport : ビューポート
  #--------------------------------------------------------------------------
  def initialize(viewport)
    super(viewport)
    self.bitmap = Bitmap.new(88, 48)
    self.bitmap.font.name = "Arial"
    self.bitmap.font.size = 32
    self.x = Graphics.width - self.bitmap.width
    self.y = 0
    self.z = 200
    update
  end
end
class Spriteset_Map
  #--------------------------------------------------------------------------
  # ○ ビューポートの作成
  #--------------------------------------------------------------------------
  def create_viewports
    @viewport1 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport3 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport2.z = 50
    @viewport3.z = 100
  end
end


class Game_Map
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #     map_id : マップ ID
  #--------------------------------------------------------------------------
  def setup(map_id)
    @map_id = map_id
    @map = load_data(sprintf("Data/Map%03d.rvdata", @map_id))
    if @map.width < Graphics.map_width && @map.height < Graphics.map_height
      msg = "マップのサイズは #{Graphics.map_width} x #{Graphics.map_height}"\
            " 以上で設定してください。"
      raise CustomizeError, msg, __FILE__
    end
    @display_x = 0
    @display_y = 0
    @passages = $data_system.passages
    referesh_vehicles
    setup_events
    setup_scroll
    setup_parallax
    @need_refresh = false
  end
  #--------------------------------------------------------------------------
  # ○ スクロールのセットアップ
  #--------------------------------------------------------------------------
  def setup_scroll
    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
    # 画面非表示分の幅 / 2
    @margin_x = (width - Graphics.map_width) * 256 / 2
    @margin_y = (height - Graphics.map_height) * 256 / 2
  end
  #--------------------------------------------------------------------------
  # ○ 遠景表示 X 座標の計算
  #     bitmap : 遠景ビットマップ
  #--------------------------------------------------------------------------
  def calc_parallax_x(bitmap)
    if bitmap == nil
      return 0
    elsif @parallax_loop_x
      return @parallax_x / 16
    elsif loop_horizontal?
      return 0
    else
      w1 = bitmap.width - Graphics.width
      w2 = @map.width * 32 - Graphics.width
      if w1 <= 0 or w2 <= 0
        return 0
      else
        return @parallax_x * w1 / w2 / 8
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 遠景表示 Y 座標の計算
  #     bitmap : 遠景ビットマップ
  #--------------------------------------------------------------------------
  def calc_parallax_y(bitmap)
    if bitmap == nil
      return 0
    elsif @parallax_loop_y
      return @parallax_y / 16
    elsif loop_vertical?
      return 0
    else
      h1 = bitmap.height - Graphics.height
      h2 = @map.height * 32 - Graphics.height
      if h1 <= 0 or h2 <= 0
        return 0
      else
        return @parallax_y * h1 / h2 / 8
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 下にスクロール
  #     distance : スクロールする距離
  #--------------------------------------------------------------------------
  def scroll_down(distance)
    if loop_vertical?
      @display_y += distance
      @display_y %= @map.height * 256
      @parallax_y += distance
    else
      last_y = @display_y
      @display_y = [@display_y+distance, (height-Graphics.map_height)*256].min
      @parallax_y += @display_y - last_y
    end
  end
  #--------------------------------------------------------------------------
  # ○ 右にスクロール
  #     distance : スクロールする距離
  #--------------------------------------------------------------------------
  def scroll_right(distance)
    if loop_horizontal?
      @display_x += distance
      @display_x %= @map.width * 256
      @parallax_x += distance
    else
      last_x = @display_x
      @display_x = [@display_x+distance, (width-Graphics.map_width)*256].min
      @parallax_x += @display_x - last_x
    end
  end
end

class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ○ 定数
  #--------------------------------------------------------------------------
  CENTER_X = (Graphics.width / 2 - 16) * 8     # 画面中央の X 座標 * 8
  CENTER_Y = (Graphics.height / 2 - 16) * 8    # 画面中央の Y 座標 * 8
  #--------------------------------------------------------------------------
  # ○ 画面中央に来るようにマップの表示位置を設定
  #     x : X 座標
  #     y : Y 座標
  #--------------------------------------------------------------------------
  def center(x, y)
    display_x = x * 256 - CENTER_X                    # 座標を計算
    unless $game_map.loop_horizontal?                 # 横にループしない？
      max_x = ($game_map.width - Graphics.map_width) * 256
      display_x = [0, [display_x, max_x].min].max     # 座標を修正
    end
    display_y = y * 256 - CENTER_Y                    # 座標を計算
    unless $game_map.loop_vertical?                   # 縦にループしない？
      max_y = ($game_map.height - Graphics.map_height) * 256
      display_y = [0, [display_y, max_y].min].max     # 座標を修正
    end
    $game_map.set_display_pos(display_x, display_y)   # 表示位置変更
  end
end


class Game_Troop < Game_Unit
  #--------------------------------------------------------------------------
  # ○ セットアップ
  #     troop_id : 敵グループ ID
  #--------------------------------------------------------------------------
  def setup(troop_id)
    clear
    @troop_id = troop_id
    @enemies = []
    for member in troop.members
      next if $data_enemies[member.enemy_id] == nil
      enemy = Game_Enemy.new(@enemies.size, member.enemy_id)
      enemy.hidden = member.hidden
      enemy.immortal = member.immortal
      enemy.screen_x = member.x + (Graphics.width - 544) / 2
      enemy.screen_y = member.y + (Graphics.height - 416) / 2
      @enemies.push(enemy)
    end
    make_unique_names
  end
end

class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ○ ビューポートの作成
  #--------------------------------------------------------------------------
  def create_viewports
    @viewport1 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport3 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport2.z = 50
    @viewport3.z = 100
  end
  #--------------------------------------------------------------------------
  # ○ バトルバックスプライトの作成
  #--------------------------------------------------------------------------
  def create_battleback
    source = $game_temp.background_bitmap
    bitmap = Bitmap.new(Graphics.width + 96, Graphics.height + 64)
    bitmap.stretch_blt(bitmap.rect, source, source.rect)
    bitmap.radial_blur(90, 12)
    @battleback_sprite = Sprite.new(@viewport1)
    @battleback_sprite.bitmap = bitmap
    @battleback_sprite.ox = bitmap.width / 2
    @battleback_sprite.oy = bitmap.height / 2
    @battleback_sprite.x = Graphics.width / 2
    @battleback_sprite.y = Graphics.height / 2
    @battleback_sprite.wave_amp = 8
    @battleback_sprite.wave_length = 240
    @battleback_sprite.wave_speed = 120
  end
end
