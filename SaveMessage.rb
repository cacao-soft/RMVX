#=============================================================================
#  [RGSS2] セーブロードメッセージ - v1.0.0
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

  セーブ・ロード時に確認と完了のメッセージを表示します。

 -- 注意事項 ----------------------------------------------------------------

  ※ Scene_File#do_load は、エイリアスせず再定義

=end


module CAO
module CFM
  
  # メッセージウィンドウの横幅
  WINDOW_WIDTH = 320
  
  # 完了メッセージの表示時間 (0 でキー入力待ち)
  WAIT_RESULT = 40
  
  MSG_CFM_Y = "はい"
  MSG_CFM_N = "いいえ"
  
  MSG_SAVE_C = "セーブしますか？"
  MSG_LOAD_C = "ロードしますか？"
  
  MSG_SAVE_R = "セーブしました。"
  MSG_LOAD_R = "ロードしました。"
  
  # メッセージウィンドウの行幅 (24 以上)
  WLH = 32
  
end # module CFM
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_SaveConfirmation < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  WLH = CAO::CFM::WLH       # 行の高さ基準値 (Window Line Height)
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(saving)
    @saving = saving
    super(0, 0, CAO::CFM::WINDOW_WIDTH, WLH * 2 + 32)
    self.x = (Graphics.width - self.width) / 2
    self.y = (Graphics.height - self.height) / 2
    self.active = false
    self.openness = 0
    @item_max = 2
    @column_max = 2
    refresh
    self.index = 0
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = normal_color
    self.contents.draw_text(0, 0, self.contents.width, WLH,
      @saving ? CAO::CFM::MSG_SAVE_C : CAO::CFM::MSG_LOAD_C)
    self.contents.draw_text(item_rect(0), CAO::CFM::MSG_CFM_Y, 1)
    self.contents.draw_text(item_rect(1), CAO::CFM::MSG_CFM_N, 1)
  end
  #--------------------------------------------------------------------------
  # ○ 項目を描画する矩形の取得
  #     index : 項目番号
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new(0, WLH, 0, 0)
    rect.width = (self.contents.width + @spacing) / @column_max - @spacing
    rect.height = WLH
    rect.x = index % @column_max * (rect.width + @spacing)
    return rect
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウを開く
  #--------------------------------------------------------------------------
  def open
    self.index = 0
    while self.openness < 255
      self.openness += 48
      Graphics.update
    end
    self.active = true
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウを閉じる
  #--------------------------------------------------------------------------
  def close
    self.active = false
    while self.openness > 0
      self.openness -= 48
      Graphics.update
    end
  end
end

class Window_SaveResult < Window_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  WLH = CAO::CFM::WLH       # 行の高さ基準値 (Window Line Height)
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(saving)
    @saving = saving
    super(0, 0, CAO::CFM::WINDOW_WIDTH, WLH + 32)
    self.x = (Graphics.width - self.width) / 2
    self.y = (Graphics.height - self.height) / 2
    self.active = false
    self.openness = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = normal_color
    self.contents.draw_text(0, 0, self.contents.width, WLH,
      @saving ? CAO::CFM::MSG_SAVE_R : CAO::CFM::MSG_LOAD_R)
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウを開く
  #--------------------------------------------------------------------------
  def open
    while self.openness < 255
      self.openness += 48
      Graphics.update
    end
    self.active = true
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウを閉じる
  #--------------------------------------------------------------------------
  def close
    self.active = false
    while self.openness > 0
      self.openness -= 48
      Graphics.update
    end
  end
end

class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  alias _cao_savew_start start
  def start
    _cao_savew_start
    @cfm_window = Window_SaveConfirmation.new(@saving)
    @result_window = Window_SaveResult.new(@saving)
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  alias _cao_savew_terminate terminate
  def terminate
    _cao_savew_terminate
    @cfm_window.dispose
    @result_window.dispose
  end
  #--------------------------------------------------------------------------
  # ○ セーブファイルの決定
  #--------------------------------------------------------------------------
  alias _cao_savew_determine_savefile determine_savefile
  def determine_savefile
    return unless show_confirmation_window
    _cao_savew_determine_savefile
  end
  #--------------------------------------------------------------------------
  # ○ セーブの実行
  #--------------------------------------------------------------------------
  alias _cao_savew_do_save do_save
  def do_save
    _cao_savew_do_save
    show_result_window
  end
  #--------------------------------------------------------------------------
  # ○ ロードの実行
  #--------------------------------------------------------------------------
  def do_load
    file = File.open(@savefile_windows[@index].filename, "rb")
    read_save_data(file)
    file.close
    show_result_window      # 追加
    $scene = Scene_Map.new
    RPG::BGM.fade(1500)
    Graphics.fadeout(60)
    Graphics.wait(40)
    @last_bgm.play
    @last_bgs.play
  end
  #--------------------------------------------------------------------------
  # ● 確認
  #--------------------------------------------------------------------------
  def show_confirmation_window
    unless @saving || @savefile_windows[@index].file_exist
      Sound.play_buzzer
      return false
    end
    @cfm_window.open
    result = nil
    loop do
      Graphics.update
      Input.update
      @cfm_window.update
      if Input.trigger?(Input::B)
        Sound.play_cancel
        result =  false
      elsif Input.trigger?(Input::C)
        Sound.play_decision
        result =  @cfm_window.index == 0
      end
      break if result != nil
    end
    @cfm_window.close
    return result
  end
  #--------------------------------------------------------------------------
  # ● 結果
  #--------------------------------------------------------------------------
  def show_result_window
    @result_window.open
    if CAO::CFM::WAIT_RESULT > 0
      Graphics.wait(CAO::CFM::WAIT_RESULT)
    else
      Input.update
      until Input.trigger?(Input::B) || Input.trigger?(Input::C)
        Graphics.update
        Input.update
      end
      Input.update
      Sound.play_decision
    end
    @result_window.close
  end
end

# KAMESOFT『カーソルアニメーション』対策
if $imported && $imported["CursorAnimation"]
class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # ○ 確認
  #--------------------------------------------------------------------------
  def show_confirmation_window
    unless @saving || @savefile_windows[@index].file_exist
      Sound.play_buzzer
      return false
    end
    @cfm_window.open
    @savefile_windows[@index].active = false
    result = nil
    loop do
      Graphics.update
      Input.update
      @cfm_window.update
      if Input.trigger?(Input::B)
        Sound.play_cancel
        result = false
      elsif Input.trigger?(Input::C)
        Sound.play_decision
        result = @cfm_window.index == 0
      end
      break if result != nil
    end
    @savefile_windows[@index].active = true
    @cfm_window.close
    return result
  end
end
# KGC_CursorAnimation   ◇ Last update : 2009/02/15 ◇
class Cursor_Animation
  #--------------------------------------------------------------------------
  # ○ ウィンドウの可視・アクティブ状態判定
  #--------------------------------------------------------------------------
  def window_active?(window)
    return false if window == nil
    return false if window.disposed?
    return false unless window.visible

    if window.is_a?(Window_Selectable)
      return true if window.active
    elsif window.is_a?(Window_SaveFile)
      return true if window.active && window.selected
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ○ アクティブウィンドウを探す
  #--------------------------------------------------------------------------
  def search_active_window
    return @windows.find { |w|
      if !w.visible
        false
      elsif w.is_a?(Window_Selectable)
        w.active && w.index >= 0
      elsif w.is_a?(Window_SaveFile)
        w.active && w.selected
      else
        false
      end
    }
  end
end
end # if $imported && $imported["CursorAnimation"]