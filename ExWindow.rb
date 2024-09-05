#=============================================================================
#  [RGSS2] ＜拡張＞ ウィンドウベース - v1.0.0
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

  ウィンドウの背景画像とスライド開閉の機能を追加します。

 -- 使用方法 ----------------------------------------------------------------

  ★ 背景画像
   include CAO::Background
   self.background = "ファイル名"

  ★ スライド開閉
   include CAO::Slide
   self.slide_type = 閉じる方向
   self.slide_speed = 速度

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO; end
  
module CAO::Background
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(*args)
    @background = Window.new
    super
    self.x = self.x
    self.y = self.y
    self.opacity = 0
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    @background.update
  end
  #--------------------------------------------------------------------------
  # ● 背景画像の設定
  #--------------------------------------------------------------------------
  def background=(filename)
    @background.contents = Cache.system(filename)
    @background.width = @background.contents.width + 32
    @background.height = @background.contents.height + 32
    @background.update
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    @background.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● x 座標の変更
  #--------------------------------------------------------------------------
  def x=(value)
    super
    @background.x = self.x - 16
    @background.update
  end
  #--------------------------------------------------------------------------
  # ● y 座標の変更
  #--------------------------------------------------------------------------
  def y=(value)
    super
    @background.y = self.y - 16
    @background.update
  end
  #--------------------------------------------------------------------------
  # ● z 座標の変更
  #--------------------------------------------------------------------------
  def z=(value)
    super
    @background.z = self.z
    @background.update
  end
  #--------------------------------------------------------------------------
  # ● ビューポートの変更
  #--------------------------------------------------------------------------
  def viewport=(value)
    super
    @background.viewport = self.viewport
    @background.update
  end
  #--------------------------------------------------------------------------
  # ● 可視状態の変更
  #--------------------------------------------------------------------------
  def visible=(value)
    super
    @background.visible = self.visible
    @background.update
  end
end

module CAO::Slide
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    if self.moving?
      if @showing
        @xx += @vx * (@sx <=> @cx)
        @yy += @vy * (@sy <=> @cy)
        @xx = @sx if (@sx < @cx) ? @xx < @sx : @xx > @sx
        @yy = @sy if (@sy < @cy) ? @yy < @sy : @yy > @sy
        @showing = nil if (self.x == @sx) && (self.y == @sy)
      else
        @xx -= @vx * (@sx <=> @cx)
        @yy -= @vy * (@sy <=> @cy)
        @xx = @cx if (@cx < @sx) ? @xx < @cx : @xx > @cx
        @yy = @cy if (@cy < @sy) ? @yy < @cy : @yy > @cy
        @showing = nil if (self.x == @cx) && (self.y == @cy)
      end

      self.x = @xx
      self.y = @yy

      if @showing == nil
        @xx, @yy = self.x, self.y
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● スライド方向の設定
  #--------------------------------------------------------------------------
  def slide_type=(type)
    @slide_type = type
    @sx, @sy = self.x, self.y
    case @slide_type
    when 8
      @cx, @cy = self.x, -self.height
      @dx, @dy = 0, self.y + self.height
    when 2
      @cx, @cy = self.x, Graphics.height
      @dx, @dy = 0, Graphics.height - self.y
    when 4
      @cx, @cy = -self.width, self.y
      @dx, @dy = self.x + self.width, 0
    when 6
      @cx, @cy = Graphics.width, self.y
      @dx, @dy = Graphics.width - self.x, 0
    when 7
      @cx, @cy = -self.width, -self.height
      @dx, @dy = self.x + self.width, self.y + self.height
    when 9
      @cx, @cy = Graphics.width, -self.height
      @dx, @dy = Graphics.width - self.x, self.y + self.height
    when 1
      @cx, @cy = -self.width, Graphics.height
      @dx, @dy = self.x + self.width, Graphics.height - self.y
    when 3
      @cx, @cy = Graphics.width, Graphics.height
      @dx, @dy = Graphics.width - self.x, Graphics.height - self.y
    else
      @cx, @cy, @dx, @dy = 0, 0, 0, 0
    end
    @xx, @yy = self.x, self.y
  end
  #--------------------------------------------------------------------------
  # ● スライド速度の設定
  #--------------------------------------------------------------------------
  def slide_speed=(speed)
    freame = (speed == 0) ? 1 : [1.0, Graphics.frame_rate / speed.to_f].max
    @vx, @vy = @dx / freame, @dy / freame
  end
  #--------------------------------------------------------------------------
  # ● 移動中判定
  #--------------------------------------------------------------------------
  def moving?
    return @showing != nil
  end
  #--------------------------------------------------------------------------
  # ● 閉じている？
  #--------------------------------------------------------------------------
  def closed?
    return self.x == @cx && self.y == @cy && !@showing
  end
  #--------------------------------------------------------------------------
  # ● 開閉切り替え
  #--------------------------------------------------------------------------
  def switch
    @showing = self.moving? ? !@showing : self.closed?
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウを開く
  #--------------------------------------------------------------------------
  def open
    @showing = true
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウを閉じる
  #--------------------------------------------------------------------------
  def close
    @showing = false
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウを表示
  #--------------------------------------------------------------------------
  def show
    @showing = nil
    self.x, self.y = @sx, @sy
    @xx, @yy = self.x, self.y
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウを非表示
  #--------------------------------------------------------------------------
  def hide
    @showing = nil
    self.x, self.y = @cx, @cy
    @xx, @yy = self.x, self.y
  end
end
