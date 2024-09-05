#=============================================================================
#  [RGSS2] 装備可能クラス表示 - v1.1.1
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

  選択中のアイテムを装備できるクラスを表示します。
  非表示にするクラスを設定できます。

 -- 注意事項 ----------------------------------------------------------------

  ※ 表示されるクラスが８０を超えると、画面からはみ出ます。
  ※ 「ショップコメント」のスクリプトとは併用できません。

 -- 使用方法 ----------------------------------------------------------------

  ★ 装備できるクラスを表示
   Ａボタン（Shift キー）で表示切替します。

  ★ 指定したクラスを表示する
   「ラベル」に Ｓクラス追加：クラスID と記述
   「ラベル」に Ｓクラス追加："クラス名" と記述

  ★ 指定したクラスを非表示にする
   「ラベル」に Ｓクラス削除：クラスID と記述
   「ラベル」に Ｓクラス削除："クラス名" と記述

  ★ 全クラス表示する
   「ラベル」に <Ｓクラス全表示> と記述

  ★ 全クラス非表示にする
   「ラベル」に <Ｓクラス全非表示> と記述

  ★ 表示状態を初期化する
   「ラベル」に <Ｓクラス初期化> と記述


=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
module ExSS_Class
  
  #--------------------------------------------------------------------------
  # ◇ 最初からすべてのクラスを表示する
  #--------------------------------------------------------------------------
  INITIALIZE_ALL_CLASS = true
  
    #------------------------------------------------------------------------
    # ◇ 初期化時に追加しないクラス
    #------------------------------------------------------------------------
    INITIALIZE_CUT_CLASS = []
  
  #--------------------------------------------------------------------------
  # ◇ 使用(表示)しないクラス
  #--------------------------------------------------------------------------
  EXCEPT_CLASS = []
  
  #--------------------------------------------------------------------------
  # ◇ スライド速度
  #--------------------------------------------------------------------------
  SLIDE_SPEED = 16
  
  #--------------------------------------------------------------------------
  # ◇ 表示・非表示を切り替えるボタン
  #--------------------------------------------------------------------------
  #   Input:: の後に使用するボタンを記述
  #     Ａボタン：A, Ｘボタン：X, Ｙボタン：Y, Ｚボタン：Z
  #--------------------------------------------------------------------------
  BTN_SLIDE = Input::A
  
  #--------------------------------------------------------------------------
  # ◇ アイテムでもクラスを表示する
  #--------------------------------------------------------------------------
  DISPLAY_ITEM = true
  
end
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::ExSS_Class
  #--------------------------------------------------------------------------
  # ● 職業名からＩＤへ変換
  #--------------------------------------------------------------------------
  def self.convert_class_id(name)
    for obj in $data_classes
      return obj.id if obj != nil && obj.name == name
    end
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_command_118_exssc command_118
  def command_118
    case @params[0]
    when /^<Ｓクラス初期化>/
      $game_party.initialize_shop_class
    when /^<Ｓクラス全表示>/
      $game_party.shop_classes = (1...$data_classes.size).to_a
      $game_party.sort_shop_class
    when /^<Ｓクラス全非表示>/
      $game_party.shop_classes.clear
    when /^Ｓクラス追加：\s?(\d+)/
      $game_party.gain_shop_class($1.to_i)
    when /^Ｓクラス削除：\s?(\d+)/
      $game_party.gain_shop_class(-$1.to_i)
    when /^Ｓクラス追加：\s?\"(.+)\"/
      $game_party.gain_shop_class(CAO::ExSS_Class.convert_class_id($1))
    when /^Ｓクラス削除：\s?\"(.+)\"/
      $game_party.gain_shop_class(-CAO::ExSS_Class.convert_class_id($1))
    else
      return _cao_command_118_exssc
    end
    return true
  end
end

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :shop_classes             # ショップで表示するクラスIDの配列
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_exssc initialize
  def initialize
    _cao_initialize_exssc
    initialize_shop_class
  end
  #--------------------------------------------------------------------------
  # ◎ ショップで表示するクラスの初期化
  #--------------------------------------------------------------------------
  def initialize_shop_class
    @shop_classes = []    # ショップ画面で表示するクラスの配列
    if CAO::ExSS_Class::INITIALIZE_ALL_CLASS
      cut_class = CAO::ExSS_Class::INITIALIZE_CUT_CLASS
      for id in 1...$data_classes.size
        next if cut_class.include?(id)
        next if cut_class.include?($data_classes[id].name)
        @shop_classes << id
      end
      sort_shop_class
    end
  end
  #--------------------------------------------------------------------------
  # ◎ ショップで表示するクラスを増減
  #--------------------------------------------------------------------------
  def gain_shop_class(*array)
    for class_id in array
      if class_id < 0
        @shop_classes -= [class_id.abs]
      else
        @shop_classes << class_id.abs
      end
    end
    sort_shop_class
  end
  #--------------------------------------------------------------------------
  # ◎ ショップで表示するクラスを整える（変更時に必ず実行）
  #--------------------------------------------------------------------------
  def sort_shop_class
    # 除外するクラスの配列を作成
    except = [0]
    for class_id in CAO::ExSS_Class::EXCEPT_CLASS
      if String === class_id  # クラス名をＩＤに直す
        for obj in $data_classes
          if obj != nil && class_id == obj.name
            except << obj.id
            break
          end
        end
      else  # ＩＤならそのまま追加
        except << class_id
      end
    end
    @shop_classes -= except   # 除外クラスを取り除く
    @shop_classes.uniq!       # 重複クラスを取り除く
    @shop_classes.sort!       # IDの若い順に並び替える
    # 定義されていないクラスを取り除く
    @shop_classes.reject! {|id| $data_classes.size <= id }
  end
end

class Window_ShopStatus < Window_Base
  #--------------------------------------------------------------------------
  # ◎ 定数
  #--------------------------------------------------------------------------
  BACK_COLOR = Color.new(0, 0, 0, 128)    # 背景の色
  FONT_COLOR = Color.new(255, 255, 255)   # クラス名の色
  #--------------------------------------------------------------------------
  # ◎ 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :slide_class              # 職業の表示状態 (true:表示中)
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #     x : ウィンドウの X 座標
  #     y : ウィンドウの Y 座標
  #--------------------------------------------------------------------------
  alias _cao_initialize_exssc initialize
  def initialize(x, y)
    _cao_initialize_exssc(x, y)
    height = WLH * ($game_party.shop_classes.size / 5) + 12
    height += WLH unless $game_party.shop_classes.size % 5 == 0
    @class_sprite = Sprite.new
    @class_sprite.bitmap = Bitmap.new(536, height)
    @class_sprite.x = 4
    @class_sprite.y = 412 - height
    @class_sprite.z = self.z
    @class_sprite.oy = -(height + 4)
    @slide_class = false
  end
  #--------------------------------------------------------------------------
  # 〇 リフレッシュ
  #--------------------------------------------------------------------------
  alias _cao_refresh_exssc refresh
  def refresh
    _cao_refresh_exssc
    refresh_class if @item != nil
  end
  #--------------------------------------------------------------------------
  # 〇 クラス表示のリフレッシュ
  #--------------------------------------------------------------------------
  def refresh_class
    @class_sprite.bitmap.clear
    @class_sprite.bitmap.fill_rect(@class_sprite.bitmap.rect, BACK_COLOR)
    return if RPG::Item === @item && !CAO::ExSS_Class::DISPLAY_ITEM
    for i in 0...$game_party.shop_classes.size
      id = $game_party.shop_classes[i]
      case @item
      when RPG::Item
        equip = true
      when RPG::Weapon
        equip = $data_classes[id].weapon_set.include?(@item.id)
      when RPG::Armor
        equip = $data_classes[id].armor_set.include?(@item.id)
      end
      @class_sprite.bitmap.font.color = FONT_COLOR
      @class_sprite.bitmap.font.color.alpha = equip ? 255 : 128
      x = i % 5 * 104 + 6
      y = i / 5 * WLH + 6
      @class_sprite.bitmap.draw_text(x, y, 100, WLH, $data_classes[id].name, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 解放
  #--------------------------------------------------------------------------
  alias _cao_dispose_exssc dispose unless $!
  def dispose
    @class_sprite.bitmap.dispose
    @class_sprite.dispose
    _cao_dispose_exssc
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_update_exssc update unless $!
  def update
    _cao_update_exssc
    if @slide_class
      if @class_sprite.oy < 0
        @class_sprite.oy += CAO::ExSS_Class::SLIDE_SPEED
        if @class_sprite.oy > 0
          @class_sprite.oy = 0
        end
      end
    else
      height = -(@class_sprite.bitmap.height + 8)
      if @class_sprite.oy > height
        @class_sprite.oy -= CAO::ExSS_Class::SLIDE_SPEED
        if @class_sprite.oy < height
          @class_sprite.oy = height
        end
      end
    end
  end
end

class Scene_Shop < Scene_Base
  #--------------------------------------------------------------------------
  # 〇 フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_update_exssc update
  def update
    _cao_update_exssc
    if @buy_window.active
      if Input.trigger?(CAO::ExSS_Class::BTN_SLIDE) && !@number_window.active
        Sound.play_cancel
        @status_window.slide_class ^= true
      end
    else
      @status_window.slide_class = false
    end
  end
end
