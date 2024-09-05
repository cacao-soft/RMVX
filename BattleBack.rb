#=============================================================================
#  [RGSS2] 戦闘背景の変更 - v1.2.0
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

  戦闘背景の表示方法を変更します。

 -- 注意事項 ----------------------------------------------------------------

  ※ デフォルトの表示方法は使用できなくなります。
  ※ 一部の表示方法では、他に必要となるスクリプトがあります。
     MODE 4 : マップ名で判定する場合 "Cacao Base Script"
     MODE 5 : 地形(タイル)で判定する場合 KGCさんの "タイルセット拡張"

 -- 使用方法 ----------------------------------------------------------------

  ★ 一時的に戦闘背景を変更する
   change_battleback("ファイル名")
  ※ 空文字列の場合は、マップを背景とします。
  ※ マップイベントで使用した場合は、次の戦闘の背景となります。

=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module BattleBack
  #--------------------------------------------------------------------------
  # ◇ 背景の表示方法
  #--------------------------------------------------------------------------
  #     0 ... マップ画像
  #     1 ... 固定・マップで判定
  #     2 ... 遠景で判定
  #     3 ... 敵グループ名で判定
  #     4 ... マップ名で判定 (CBS必須)
  #     5 ... 地形で判定 (KGCさんのタイルセット拡張スクリプト必須)
  #     6 ... 地形 ＋ 敵グループ名で判定 (敵グループ名を優先)
  #--------------------------------------------------------------------------
    MODE = 6
  #--------------------------------------------------------------------------
  # ◇ 放射状のぼかし効果
  #--------------------------------------------------------------------------
    RADIAL_BLUR = false
  #--------------------------------------------------------------------------
  # ◇ 影を非表示
  #--------------------------------------------------------------------------
    NO_FLOOR = true
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの背景
  #--------------------------------------------------------------------------
  #   nil    .. ウィンドウの背景を描画しない
  #   String .. 指定されたファイル名の画像を描画する
  #   Color  .. 指定された Color オブジェクトで塗りつぶす
  #--------------------------------------------------------------------------
    IMG_WINDOW_BACK = nil
  #--------------------------------------------------------------------------
  # ◇ 背景マップのトーン
  #--------------------------------------------------------------------------
    BACK_MAP_TONE = Tone.new(-48, -48, -48, 128)
  #--------------------------------------------------------------------------
  # ◇ 画像設定
  #--------------------------------------------------------------------------
    IMG_BACK = {} # この行は消さないでください。
    
    # 固定画像 (ファイル名のみ変更可)
    IMG_BACK[0] = ""
    
    # ユーザー登録画像 (追加削除可)
    IMG_BACK[18] = "Mountains"
    
    IMG_BACK["海"] = "Ocean"
    IMG_BACK["山"] = "Mountains"
end
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::BattleBack
  #--------------------------------------------------------------------------
  # ● 正規表現
  #--------------------------------------------------------------------------
  REGEXP_BACKTYPE = /<BB:(.+?)>/
  #--------------------------------------------------------------------------
  # ● 画像設定のキーチェック
  #--------------------------------------------------------------------------
  def self.key_check(key)
    if CAO::BattleBack::IMG_BACK[key].nil?
      print "key : '#{key}' の画像が設定されていません"
    end
  end
end

module Cache
  #--------------------------------------------------------------------------
  # ● アニメーション グラフィックの取得
  #     filename : ファイル名
  #--------------------------------------------------------------------------
  def self.battleback(filename)
    return filename ? load_bitmap("Graphics/Battlebacks/", filename) : nil
  end
end

class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :battleback               # 戦闘背景のファイル名
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_battleback_initialize initialize
  def initialize
    @battleback = nil
    _cao_battleback_initialize
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 戦闘背景の変更
  #--------------------------------------------------------------------------
  def change_battleback(filename)
    $game_temp.battleback = filename
    return unless $game_temp.in_battle
    $scene.instance_variable_get(:@spriteset).refresh_battleback
  end
end

class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  BATTLEBACK_W = 720                    # 戦闘背景の横幅
  BATTLEBACK_H = Graphics.height        # 戦闘背景の縦幅
  #--------------------------------------------------------------------------
  # ○ バトルフロアスプライトの作成
  #--------------------------------------------------------------------------
  alias _cao_battleback_create_battlefloor create_battlefloor
  def create_battlefloor
    _cao_battleback_create_battlefloor
    # モンスター下の影画像の可視状態
    @battlefloor_sprite.opacity = 0 if CAO::BattleBack::NO_FLOOR
  end
  #--------------------------------------------------------------------------
  # ○ バトルバックスプライトの作成
  #--------------------------------------------------------------------------
  def create_battleback
    @battleback_sprite = Sprite.new(@viewport1)
    @battleback_sprite.ox = BATTLEBACK_W / 2
    @battleback_sprite.x = Graphics.width / 2
    refresh_battleback
  end
  #--------------------------------------------------------------------------
  # ● 戦闘背景のリフレッシュ
  #--------------------------------------------------------------------------
  def refresh_battleback
    @battleback_sprite.bitmap ||= Bitmap.new(BATTLEBACK_W, BATTLEBACK_H)
    @battleback_sprite.bitmap.clear
    @battleback_sprite.tone.set(0, 0, 0, 0)
    # 戦闘背景を描画
    battleback = @battleback_sprite.bitmap    # 実際に表示される背景画像
    source = self.battleback                  # 元となる背景画像
    if CAO::BattleBack::RADIAL_BLUR
      battleback.stretch_blt(battleback.rect, source, source.rect)
      battleback.radial_blur(90, 12)
    else
      battleback.blt((BATTLEBACK_W - source.width) / 2, 0, source, source.rect)
    end
    # ウィンドウ背景を描画
    draw_windowback
  end
  #--------------------------------------------------------------------------
  # ● 背景画像のタイプを取得
  #--------------------------------------------------------------------------
  def battleback_type
    # 一時背景が空文字列の場合は、マップ画像
    return 0 if $game_temp.battleback == ""
    # 戦闘テストの場合は[初期背景]もしくは[黒] (トループ名で判定以外)
    return nil if $BTEST && CAO::BattleBack::MODE != 3
    # 一時背景が設定されていない場合は、設定通り
    return CAO::BattleBack::MODE if $game_temp.battleback == nil
    # 一時背景を適用
    return 9
  end
  #--------------------------------------------------------------------------
  # ● 戦闘背景画像の取得
  #--------------------------------------------------------------------------
  def battleback
    result = nil                            # [戻り値] Bitmap オブジェクト
    background = CAO::BattleBack::IMG_BACK  # 画像設定
    # 戦闘背景の表示モード分岐
    case battleback_type
    when 0  # マップ画像
      bitmap = $game_temp.background_bitmap
      @battleback_sprite.tone = CAO::BattleBack::BACK_MAP_TONE
    when 1  # 固定・マップ判定
      if background.has_key?($game_map.map_id)
        result = Cache.battleback(background[$game_map.map_id])
      end
    when 2  # 遠景判定
      if $game_map.parallax_name != ""
        result = Cache.parallax($game_map.parallax_name)
      end
    when 3  # 敵グループ名判定
      if CAO::BattleBack::REGEXP_BACKTYPE =~ $game_troop.troop.name
        CAO::BattleBack.key_check($1)
        result = Cache.battleback(background[$1])
      end
    when 4  # マップ名判定
      for name in $game_map.area_name
        next unless CAO::BattleBack::REGEXP_BACKTYPE === name
        CAO::BattleBack.key_check($1)
        result = Cache.battleback(background[$1])
        break
      end
      if result || CAO::BattleBack::REGEXP_BACKTYPE === $game_map.map_name
        CAO::BattleBack.key_check($1)
        result = Cache.battleback(background[$1])
      end
    when 5  # 地形判定 (KGC)
      tag = $game_map.terrain_tag($game_player.x, $game_player.y)
      if background.has_key?(tag) && background[tag] != ""
        result = Cache.battleback(background[tag])
      end
    when 6  # 地形 ＋ 敵グループ名
      # グループ名
      if CAO::BattleBack::REGEXP_BACKTYPE =~ $game_troop.troop.name
        CAO::BattleBack.key_check($1)
        result = Cache.battleback(background[$1])
      end
      # 地形
      for i in [1, 0]
        break if result != nil
        tile_id = $game_map.data[$game_player.x, $game_player.y, i]
        next if tile_id == 0
        if tile_id < 2048
          result = Cache.battleback(background[tile_id - 1536 + 128])
        else
          result = Cache.battleback(background[(tile_id - 2048) / 48])
        end
      end
    when 9
      result = Cache.battleback($game_temp.battleback)
      $game_temp.battleback = nil   # 一度の表示で無効 (戦闘単位ではない)
    end
    # 戦闘背景が確定していない場合
    unless result
      # 固定画像のファイル名が設定されていない場合
      if background[0] == nil || background[0] == ""
        # マップ画像を背景
        result = $game_temp.background_bitmap
        @battleback_sprite.tone = CAO::BattleBack::BACK_MAP_TONE
      else
        result = Cache.battleback(background[0])
      end
    end
    return result
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ背景の描画
  #--------------------------------------------------------------------------
  def draw_windowback
    back_type = CAO::BattleBack::IMG_WINDOW_BACK
    case back_type
    when String
      img_wb = Cache.system(back_type)
      x = (BATTLEBACK_W - img_wb.width) / 2
      y = BATTLEBACK_H - img_wb.height
      @battleback_sprite.bitmap.blt(x, y, img_wb, img_wb.rect)
    when Color
      x = 0
      y = BATTLEBACK_H - 128
      @battleback_sprite.bitmap.fill_rect(x, y, BATTLEBACK_W, 128, back_type)
    end
  end
end
