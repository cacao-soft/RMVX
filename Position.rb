#=============================================================================
#  [RGSS2] パーティの並び変更 - v1.0.1
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

  パーティのメンバーの並びを変更する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ 追加機能は、すべてスクリプトで提供されます。

 -- 使用方法 ----------------------------------------------------------------

  ★ アクターの位置の入れ替え
   $game_party.swap_member(pos1, pos2)
     pos1 と pos2 のアクターの位置を入れ替えます。
     例）$game_party.swap_member(0, 2)

  ★ アクターの位置の移動
   $game_party.move_member(src_pos, dest_pos)
     src_pos のアクターを dest_pos へ移動します。
     例）$game_party.move_member(0, 2)

  ★ アクターの位置を前にずらす
   $game_party.shift_member(actor_id)
     actor_id のアクターの位置を１つ前へ移動します。
     例）$game_party.shift_member(1)

  ★ アクターの位置を後ろにずらす
   $game_party.unshift_member(actor_id)
     actor_id のアクターの位置を１つ後ろへ移動します。
     例）$game_party.unshift_member(1)

  ★ アクターの位置を前にローテーション
   $game_party.rotate_member
     アクターの並びを１つ前にずらして、先頭のアクターは最後に移動します。

  ★ アクターの位置を後ろにローテーション
   $game_party.back_rotate_member
     アクターの並びを１つ後ろにずらして、最後のアクターは先頭に移動します。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Party
  #--------------------------------------------------------------------------
  # ● アクターの入れ替え
  #     pos1   : 入れ替えるアクターの位置 Ａ
  #     pos2   : 入れ替えるアクターの位置 Ｂ
  #     return : メンバーの配列
  #--------------------------------------------------------------------------
  def swap_member(pos1, pos2)
    tmp = @actors[pos1]
    @actors[pos1] = @actors[pos2]
    @actors[pos2] = tmp
    @actors.compact!
    $game_player.refresh
    return self.members
  end
  #--------------------------------------------------------------------------
  # ● アクターの移動
  #     src_pos  : 移動するアクターの位置
  #     dest_pos : 移動先の位置
  #     return   : メンバーの配列
  #--------------------------------------------------------------------------
  def move_member(src_pos, dest_pos)
    @actors.insert(dest_pos, @actors.delete_at(src_pos))
    @actors.compact!
    $game_player.refresh
    return self.members
  end
  #--------------------------------------------------------------------------
  # ● アクターの位置を１つ前に移動
  #     actor_id : 移動するアクターのID
  #     return   : メンバーの配列 (指定されたアクターがいない場合は nil)
  #--------------------------------------------------------------------------
  def shift_member(actor_id)
    pos = @actors.index(actor_id)
    return nil if pos == nil
    move_member(pos, (pos == 0 ? @actors.size - 1 : pos - 1))
    return self.members
  end
  #--------------------------------------------------------------------------
  # ● アクターの位置を１つ後ろに移動
  #     actor_id : 移動するアクターのID
  #     return   : メンバーの配列 (指定されたアクターがいない場合は nil)
  #--------------------------------------------------------------------------
  def unshift_member(actor_id)
    pos = @actors.index(actor_id)
    return nil if pos == nil
    move_member(pos, (pos + 1) % @actors.size)
    return self.members
  end
  #--------------------------------------------------------------------------
  # ● アクターの位置を前にローテーション
  #     return : 移動したアクター
  #--------------------------------------------------------------------------
  def rotate_member
    @actors.push(@actors.shift)
    $game_player.refresh
    return $game_actors[@actors.last]
  end
  #--------------------------------------------------------------------------
  # ● アクターの位置を後ろにローテーション
  #     return : 移動したアクター
  #--------------------------------------------------------------------------
  def back_rotate_member
    @actors.unshift(@actors.pop)
    $game_player.refresh
    return $game_actors[@actors.first]
  end
end
