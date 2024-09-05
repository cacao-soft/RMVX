#=============================================================================
#  [RGSS2] 商品準備 - v1.0.0
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

  ショップに表示するアイテムを分けて設定する機能を追加します。

 -- 使用方法 ----------------------------------------------------------------

  ★ ショップ商品の設定
   イベントコマンド「ラベル」に ショップ準備開始 と記入してください。
   その後、「ショップの処理」で指定されたアイテムが追加されます。

  ★ ショップの起動
   イベントコマンド「ラベル」に ショップ準備完了 と記入してください。
   ショップ画面が表示されます。
  ※ 購入のみの設定は、最後に設定されたものが適用されます。

  ★ 商品設定のキャンセル
   イベントコマンド「ラベル」に ショップ準備中止 と記入してください。
   以降、「ショップの処理」は通常通り処理されます。


=end


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module PS
  #--------------------------------------------------------------------------
  # ◇ データベースの順番に並び替える
  #--------------------------------------------------------------------------
  SORT_GOODS = true
end
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :shop_preparation         # ショップ 準備中フラグ
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_prepshop_initialize initialize
  def initialize
    _cao_prepshop_initialize
    @shop_preparation = false
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias _cao_prepshop_command_118 command_118
  def command_118
    case @params[0]
    when /^(Ｓ|ショップ)準備開始$/
      $game_temp.shop_preparation = true
      $game_temp.shop_goods = []
      $game_temp.shop_purchase_only = false
      return true
    when /^(Ｓ|ショップ)準備完了$/
      print "商品リストが空です。" if $game_temp.shop_goods.empty?
      $game_temp.shop_preparation = false
      $game_temp.shop_goods.map! {|a| a[0,2] }.uniq!
      $game_temp.shop_goods.sort! if CAO::PS::SORT_GOODS
      $game_temp.next_scene = "shop"
      return true
    when /^(Ｓ|ショップ)準備中止$/
      $game_temp.shop_preparation = false
      $game_temp.shop_goods = []
      $game_temp.shop_purchase_only = false
      return true
    end
    _cao_prepshop_command_118
  end
  #--------------------------------------------------------------------------
  # ○ ショップの処理
  #--------------------------------------------------------------------------
  alias _cao_prepshop_command_302 command_302
  def command_302
    if $game_temp.shop_preparation
      $game_temp.shop_goods << @params
      $game_temp.shop_purchase_only = @params[2]
      loop do
        @index += 1
        if @list[@index].code == 605          # ショップ 2 行目以降
          $game_temp.shop_goods.push(@list[@index].parameters)
        else
          return false
        end
      end
    else
      _cao_prepshop_command_302
    end
  end
end
