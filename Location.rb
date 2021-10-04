#=============================================================================
#  [RGSS2] マップ名表示機能 - v2.3.5
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

  マップを移動するたびに画面にマップ名/エリア名を表示します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、Cacao Base Script が必要です。

 -- 画像規格 ----------------------------------------------------------------

  ★ 背景画像
   "LocationWindow" という画像を "Graphics/System" に用意してください。
   サイズは、180 x 32 以上になるようにしてください。

 -- 使用方法 ----------------------------------------------------------------

  ★ 現在地名を非表示にする（自動）
   マップ名/エリア名の先頭に"@"と記述すると非表示になります。

  ★ エリア名を非表示にする（自動）
   エリア名の先頭に"!"と記述すると代わりにマップ名を現在地名とします。

  ★ 任意の文字で再表示する
   イベントコマンド「ラベル」に表示する文章を記入します。
   さらに、その下(直後)に再表示スイッチをＯＮにすることで、
   ラベルの文章を現在地名として再表示します。
   ラベル内で以下の制御文字が使用できます。
     <マップ> ... 現在のマップ名を表示
     <エリア> ... 現在のエリア名を表示

  ★ マップ名/エリア名にコメントを書き込む
   "#"以降の文字はコメントとし現在地名には表示しません。
   "#"の直前にある空白は削除されます。(複数)
   "#{...}"に囲まれた文字をコメントとし現在地名には表示しません。

  ★ マップ名/エリア名を取得する（スクリプト）
   "$game_map.name" で取得できます。
   引数に false を入れると、エリア名は取得せずマップ名を取得します。
   "$game_map.area_name(true)" でエリア名のみを取得できます。
   複数のエリアが重なっている可能性があるため、エリア名は配列で返ります。

  ※ 表示する現在地名は、マップの設定で設定したマップ名です。
     ただし、エリアが存在する場合は、そちらを優先します。
     エリア名を使用したくない場合は、エリア名の先頭に"!"を入れてください。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO::LOCATION
  #--------------------------------------------------------------------------
  # ◇ 非表示フラグ
  #--------------------------------------------------------------------------
  #     この番号のスイッチがＯＮのとき現在地名が表示されません。
  #--------------------------------------------------------------------------
    SWITCHE_NEMBER_HIDE = 3
  #--------------------------------------------------------------------------
  # ◇ 再表示フラグ
  #--------------------------------------------------------------------------
  #     この番号のスイッチをＯＮにすると現在地名が再表示されます。
  #  ※ 非表示の場合でも強制的に表示します。
  #  ※ 再表示した際に自動でＯＦＦになります。
  #--------------------------------------------------------------------------
    SWITCHE_NEMBER_RESTART = 4
  #--------------------------------------------------------------------------
  # ◇ 背景のタイプ
  #--------------------------------------------------------------------------
  #   nil ... 背景画像を使用する
  #     0 ... 右へグラデーション
  #     1 ... 左右へグラデーション
  #     2 ... 単色
  #--------------------------------------------------------------------------
    BACK_IMAGE_TYPE = 1
    #--------------------------------------------------------------------------
    # ◇ 背景画像を使用しない場合の設定
    #--------------------------------------------------------------------------
      # 背景色
      BACK_COLOR = Color.new(0, 0, 0, 128)      # 単色カラー
      BACK_COLOR_G1 = Color.new(0, 0, 0, 240)   # 右・中央のカラー
      BACK_COLOR_G2 = Color.new(0, 0, 0, 0)     # 左・左右のカラー
      # 背景色の横幅
      EX_WIDTH = 200
      # 背景色を下へずらす
      BACK_BOTTOM = true
  #--------------------------------------------------------------------------
  # ◇ マップ名を取得する際にエリア名も含める (エリア名を表示する)
  #--------------------------------------------------------------------------
    CHECK_AREA_NAME = true
    #--------------------------------------------------------------------------
    # ◇ エリアが変わる度に再表示する
    #--------------------------------------------------------------------------
      CHECK_CHANGE_AREA = true
    #--------------------------------------------------------------------------
    # ◇ エリアの変更を厳密に判定する
    #--------------------------------------------------------------------------
    #     非表示の場所に移動してもエリアを移動したと判断します。
    #     表示エリアと非表示エリアを行き来すると表示エリアのみ再表示されます。
    #--------------------------------------------------------------------------
      CHECK_HIDE_NAME = false
  #--------------------------------------------------------------------------
  # ◇ テキストの文字設定
  #--------------------------------------------------------------------------
    # フォント
    TEXT_FONT = ["UmePlus Gothic", "ＭＳ ゴシック", "Courier New"]
    # サイズ
    TEXT_SIZE = 16
    # カラー
    TEXT_COLOR = Color.new(255, 255, 255)
    # 横位置（0：左寄せ, 1：中央寄せ, 2：右寄せ）
    TEXT_ALIGN = 1
    # 影の有無
    TEXT_SHADOW = true
  #--------------------------------------------------------------------------
  # ◇ テキストの余白（上、右、下、左）
  #--------------------------------------------------------------------------
    TEXT_PADDING = [0, 0, 0, 0]
  #--------------------------------------------------------------------------
  # ◇ 画像の余白（右, 上）
  #--------------------------------------------------------------------------
    IMG_MARGIN = [16, 16]
  #--------------------------------------------------------------------------
  # ◇ スライドの速さ
  #--------------------------------------------------------------------------
    SLIDE_SPEED = 5
  #--------------------------------------------------------------------------
  # ◇ 消去時にスライドさせる
  #--------------------------------------------------------------------------
    IMG_SLIDE_END = false
  #--------------------------------------------------------------------------
  # ◇ 現在地名の消去の早さ（スライドさせない場合は薄くなります）
  #--------------------------------------------------------------------------
    FADE_SPEED = 4
  #--------------------------------------------------------------------------
  # ◇ 現在地名を表示している時間（フレーム数）
  #--------------------------------------------------------------------------
    LOCATION_WAIT = 60
  #--------------------------------------------------------------------------
  # ◇ ゲームロード時の現在地名表示設定
  #--------------------------------------------------------------------------
  #     0 ... 表示しない
  #     1 ... 非表示スイッチで判断
  #     2 ... マップ名で判断
  #     3 ... スイッチとマップ名の両方で判断
  #     4 ... いかなる場合でも強制表示する
  #--------------------------------------------------------------------------
    LOAD_VIEW = 3
  #--------------------------------------------------------------------------
  # ◇ 現在地名から除外する文字
  #--------------------------------------------------------------------------
  #     " ... " : 位置する文字列を除外
  #     ['',''] : ２つの要素で構成　この２つの文字に挟まれた文字列を除外
  #--------------------------------------------------------------------------
  #  ※ 正規表現で直接参照されます。メタ文字に注意してください。
  #     CAO::Commands.get_location_name で、
  #     　こちらで設定した文字列を削除したマップ名を取得できます。
  #     CAO::LOCATION.convert_string(string) で、
  #     　こちらで設定した文字列を削除した文字列を取得できます。
  #--------------------------------------------------------------------------
    DELETE_STRING = [
#~       "除外文字", ['\[','\]']
    ]
  #--------------------------------------------------------------------------
  # ◇ ラベル命令の設定
  #--------------------------------------------------------------------------
  #     正規表現のわからない方は変更しないでください。
  #--------------------------------------------------------------------------
    REGEXP_MAP = /^<マップ>/
    REGEXP_AREA = /^<エリア>/


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  LN_DISPLAY     =  0                     # 現在地名 表示
  LN_NODISPLAY   = -1                     # 現在地名 非表示
  LN_INITDISPLAY = -2                     # 現在地名解放時、0 で初期化
  #--------------------------------------------------------------------------
  # ● 除外文字を削除
  #--------------------------------------------------------------------------
  def self.convert_string(name)
    name = name.dup
    for str in DELETE_STRING
      case str
      when String
        name.gsub!(/#{str}/, "")
      when Array
        name.gsub!(/#{str[0]}.*?#{str[1]}/, "")
      else
        msg = "除外文字は文字列もしくは、配列で設定してください。"
        raise CustomizeError, msg, __FILE__
      end
    end
    return name
  end
end

module CAO::Commands
  #--------------------------------------------------------------------------
  # ● 現在地名を取得
  #--------------------------------------------------------------------------
  def self.get_location_name
    name = $game_map.name(CAO::LOCATION::CHECK_AREA_NAME)
    return CAO::LOCATION.convert_string(name)
  end
  #--------------------------------------------------------------------------
  # ● 現在地名の消去
  #--------------------------------------------------------------------------
  def self.close_location
    Sprite_LocationName.close
  end
  #--------------------------------------------------------------------------
  # ● 現在地名の非表示判定
  #--------------------------------------------------------------------------
  def self.hidden_location?
    return $game_map.name(CAO::LOCATION::CHECK_AREA_NAME, false).match(/^[@]/)
  end
end

class Game_System
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :elapsed_time             # 経過時間 -1:非表示 0:表示 1~停止
  attr_accessor :location_name            # 現在地名 直接指定
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_location initialize
  def initialize
    _cao_initialize_location
    @elapsed_time = -1
    @location_name = ""
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_location command_118
  def command_118
    # 実行内容のリストの最後ではなく、次のコマンドがスイッチ操作なら
    if !(@index >= @list.size - 1) && @list[@index + 1].code == 121
      next_p = @list[@index + 1].parameters # 次のコマンド
      # 再表示フラグがＯＮなら
      if next_p[0] == CAO::LOCATION::SWITCHE_NEMBER_RESTART && next_p[2] == 0
        # ラベルの文章を現在地名に設定
        case @params[0]
        when CAO::LOCATION::REGEXP_MAP
          $game_system.location_name = $game_map.name(false)
        when CAO::LOCATION::REGEXP_AREA
          $game_system.location_name = $game_map.area_name(true)[0] || ""
        else
          $game_system.location_name = @params[0]
        end
        return true
      end
    end
    return _cao_command_118_location
  end
end

class Sprite_LocationName
  include CAO::LOCATION
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  EX_HEIGHT = TEXT_SIZE + 8               # 
  IMAGE_BACKGROUND = "LocationWindow"     # 背景画像のファイル名
  #--------------------------------------------------------------------------
  # ● クラス変数
  #--------------------------------------------------------------------------
  @@close = false                         # 現在地名の消去フラグ
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @@close = false
    @location_sprite = Sprite.new
    @location_sprite.visible = !$game_switches[SWITCHE_NEMBER_HIDE]
    set_location_name
    @location_sprite.visible = false if CAO::Commands.hidden_location?
    create_background
    initialize_pattern
    initialize_position
    refresh
  end
  #--------------------------------------------------------------------------
  # ● パターンを初期化
  #--------------------------------------------------------------------------
  def initialize_pattern
    @location_sprite.bitmap.font.name = TEXT_FONT
    @location_sprite.bitmap.font.size = TEXT_SIZE
    @location_sprite.bitmap.font.shadow = TEXT_SHADOW
    @location_sprite.bitmap.font.color = TEXT_COLOR
  end
  #--------------------------------------------------------------------------
  # ● 表示位置を初期化
  #--------------------------------------------------------------------------
  def initialize_position
    @location_sprite.x = Graphics.width
    @location_sprite.y = IMG_MARGIN[1]
    @location_sprite.z = 150
  end
  #--------------------------------------------------------------------------
  # ● 現在地名の背景を作成
  #--------------------------------------------------------------------------
  def create_background
    if BACK_IMAGE_TYPE
      if Cache.bitmap?(IMAGE_BACKGROUND)
        bitmap = Cache.bitmap(IMAGE_BACKGROUND)
      else
        bitmap = Bitmap.new(EX_WIDTH, EX_HEIGHT)
        g1, g2 = BACK_COLOR_G1, BACK_COLOR_G2
        # 背景の表示位置
        if BACK_BOTTOM
          rect = Rect.new(0, TEXT_SIZE / 2 + 4, EX_WIDTH, TEXT_SIZE / 2 + 4)
        else
          rect = Rect.new(0, 0, EX_WIDTH, EX_HEIGHT)
        end
        # 背景色の描画方法
        case BACK_IMAGE_TYPE
        when 0
          bitmap.gradient_fill_rect(rect, g1, g2)
        when 1
          rect.width /= 2
          bitmap.gradient_fill_rect(rect, g2, g1)
          rect.x = rect.width
          bitmap.gradient_fill_rect(rect, g1, g2)
        when 2
          bitmap.fill_rect(rect, BACK_COLOR)
        end
        bitmap.to_cache(IMAGE_BACKGROUND)
      end
      @location_sprite.bitmap = bitmap.clone
    else
      @location_sprite.bitmap = Cache.system(IMAGE_BACKGROUND).clone
    end
    @img_width = @location_sprite.bitmap.width + IMG_MARGIN[0]
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    rect = @location_sprite.bitmap.rect
    rect.x += TEXT_PADDING[3]
    rect.y += TEXT_PADDING[0]
    rect.width -= TEXT_PADDING[1]
    rect.height -= TEXT_PADDING[2]
    @location_sprite.bitmap.draw_text(rect, @location_name, TEXT_ALIGN)
  end
  #--------------------------------------------------------------------------
  # ● 解放
  #--------------------------------------------------------------------------
  def dispose
    if $game_system.elapsed_time == LN_INITDISPLAY
      $game_system.elapsed_time = LN_DISPLAY
    else
      $game_system.elapsed_time = LN_NODISPLAY
    end
    @location_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ● フレームの更新
  #--------------------------------------------------------------------------
  def update
    # 消去フラグがＯＮ
    if @@close
      @@close = false
      @location_sprite.visible = false
    end
    # 再表示フラグがＯＮ
    if $game_switches[SWITCHE_NEMBER_RESTART]
      @location_sprite.visible = true
      restart_location_name
    # エリア名ごとに表示で、なおかつ非表示フラグがＯＦＦ
    elsif CHECK_CHANGE_AREA && !$game_switches[SWITCHE_NEMBER_HIDE]
      if get_location_name != @location_name
        set_location_name if CHECK_HIDE_NAME
        unless CAO::Commands.hidden_location?
          @location_sprite.visible = true
          restart_location_name
        end
      end
    end
    return unless @location_sprite.visible
    return if $game_system.elapsed_time < 0
    return unless Graphics.brightness == 255
    if $game_system.elapsed_time == 0
      @location_sprite.ox += SLIDE_SPEED
      if @location_sprite.ox >= @img_width
        @location_sprite.ox = @img_width 
        $game_system.elapsed_time = 1
      end
    elsif $game_system.elapsed_time <= LOCATION_WAIT
      $game_system.elapsed_time += 1
    else
      if IMG_SLIDE_END
        @location_sprite.ox -= SLIDE_SPEED
      else
        @location_sprite.opacity -= FADE_SPEED
      end
      if @location_sprite.ox <= 0 || @location_sprite.opacity == 0
        @location_sprite.visible = false
        $game_system.elapsed_time = -1
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 現在地名の再表示
  #--------------------------------------------------------------------------
  def restart_location_name
    $game_switches[SWITCHE_NEMBER_RESTART] = false
    $game_system.elapsed_time = 0
    @location_sprite.ox = 0
    @location_sprite.opacity = 255
    create_background
    initialize_pattern
    initialize_position
    set_location_name(true)
    refresh
    set_location_name
  end
  #--------------------------------------------------------------------------
  # ● 現在地名の設定
  #--------------------------------------------------------------------------
  #     label : ラベル命令で設定したマップ名を考慮するか
  #--------------------------------------------------------------------------
  def set_location_name(label = false)
    if label && $game_system.location_name != ""
      @location_name = CAO::LOCATION.convert_string($game_system.location_name)
      $game_system.location_name = ""
    else
      @location_name = get_location_name
    end
  end
  #--------------------------------------------------------------------------
  # ● 現在地名の取得
  #--------------------------------------------------------------------------
  def get_location_name
    return CAO::Commands.get_location_name
  end
  #--------------------------------------------------------------------------
  # ● 現在地名の消去
  #--------------------------------------------------------------------------
  def self.close
    if Scene_Map === $scene
      @@close = true
      $scene.instance_variable_get(:@spriteset).update
    end
  end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_location initialize
  def initialize
    @location_sprite = Sprite_LocationName.new
    _cao_initialize_location
  end
  #--------------------------------------------------------------------------
  # ○ 解放
  #--------------------------------------------------------------------------
  alias _cao_dispose_location dispose
  def dispose
    _cao_dispose_location
    @location_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_update_location update
  def update
    @location_sprite.update
    _cao_update_location
  end
end

unless CAO::LOCATION::LOAD_VIEW.zero?
class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # ○ ロードの実行
  #--------------------------------------------------------------------------
  alias _cao_do_load_location do_load
  def do_load
    _cao_do_load_location
    swit = !$game_switches[CAO::LOCATION::SWITCHE_NEMBER_HIDE]
    mapn = !CAO::Commands.hidden_location?
    case CAO::LOCATION::LOAD_VIEW
    when 1
      $game_switches[CAO::LOCATION::SWITCHE_NEMBER_RESTART] = swit
    when 2
      $game_switches[CAO::LOCATION::SWITCHE_NEMBER_RESTART] = mapn
    when 3
      $game_switches[CAO::LOCATION::SWITCHE_NEMBER_RESTART] = swit & mapn
    when 4
      $game_switches[CAO::LOCATION::SWITCHE_NEMBER_RESTART] = true
    end
  end
end
end # unless CAO::LOCATION::LOAD_VIEW.zero?

class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 場所移動の予約
  #     map_id    : マップ ID
  #     x         : X 座標
  #     y         : Y 座標
  #     direction : 移動後の向き
  #--------------------------------------------------------------------------
  alias _cao_reserve_transfer_location reserve_transfer
  def reserve_transfer(map_id, x, y, direction)
    _cao_reserve_transfer_location(map_id, x, y, direction)
    if $game_switches[CAO::LOCATION::SWITCHE_NEMBER_HIDE]
      $game_system.elapsed_time = CAO::LOCATION::LN_NODISPLAY
    else
      $game_system.elapsed_time = CAO::LOCATION::LN_INITDISPLAY
    end
  end
end
