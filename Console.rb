#=============================================================================
#  [RGSS2] デバッグコンソール - v1.0.2
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

  コンソールウィンドウに文字を出力する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ ゲームが異常終了すると、コンソールが閉じられなくなることがあります。
     そのコンソールは消せませんので、パソコンを再起動してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ Console.out(string)
   文字列(数値)をそのまま出力します。

  ★ Console.outl(string)
   改行付きで文字列(数値)を出力します。

  ★ Console.outp(*string)
   オブジェクトを人が読める形式に変換した文字列を出力します。

  ★ Console.outi(*string)
   Alt キーを押している間だけ文字列を出力します。

  ★ Console.outw(*string)
   設定された秒数に一度だけ文字列を出力します。

  ★ Console.wait = second
   Console.outw の待ち時間を設定します。デフォルト値は 0.6 秒です。

  ★ Console.line(string = "=")
   string(半角文字)を 60 並べた文字列を出力します。

  ※ 出力メソッドの戻り値は、出力した文字数です。

  ★ Console.measure(num = 1) { ... }
   式(...)の num 回実行に要する時間を計測し、その平均時間を出力します。
   戻り値は、出力した平均時間と同じもの(数値)です。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   このスクリプトには設定項目はありません。                  #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO
module Debug
  
  # 文字出力キー
  KEY_OUTPUT = Input::ALT

end
end # module CAO

module Console
  def self.wait=(second);             end   # 待ち時間の設定
  def self.out(text);                 end   # コンソール出力
  def self.outl(text);                end   # コンソール出力 (最後に改行)
  def self.outp(*texts);              end   # コンソール出力 (デバッグ出力)
  def self.outi(*texts);              end   # コンソール出力 (キー押し待ち)
  def self.outw(*texts);              end   # コンソール出力 (ウェイト)
  def self.line(text = "=");          end   # コンソール出力 (ライン)
  def self.measure(num = 1);          end   # コンソール出力 (処理速度)
end
def cp(*texts); Console.outp(*texts); end   # outp の別名

if $TEST
module Console
  #--------------------------------------------------------------------------
  # ● Win32API
  #--------------------------------------------------------------------------
  @@FindWindow =
    Win32API.new('user32', 'FindWindow', 'pp', 'l')
  @@SetForegroundWindow =
    Win32API.new('user32', 'SetForegroundWindow', 'l', 'i')
    
  @@AllocConsole =
    Win32API.new('kernel32', 'AllocConsole', 'v', 'i')
  @@FreeConsole =
    Win32API.new('kernel32', 'FreeConsole', 'v', 'i')
  @@GetStdHandle =
    Win32API.new('kernel32', 'GetStdHandle', 'l', 'l')
  @@WriteConsole =
    Win32API.new('kernel32', 'WriteConsole', 'lplpp', 'l')
  
  @@SetConsoleTitle =
    Win32API.new('kernel32', 'SetConsoleTitle', 'p', 'l')
  @@SetConsoleCursorPosition =
    Win32API.new('kernel32', 'SetConsoleCursorPosition', 'lp', 'l')
  
  #--------------------------------------------------------------------------
  # ● ゲームのタイトルとハンドルの取得
  #--------------------------------------------------------------------------
  unless $!
    GAME_TITLE  = NKF.nkf("-sxm0",load_data("Data/System.rvdata").game_title)
    GAME_HANDLE = @@FindWindow.call("RGSS Player", GAME_TITLE)
  end
  #--------------------------------------------------------------------------
  # ● コンソールウィンドウの表示
  #--------------------------------------------------------------------------
  @@AllocConsole.call
  @@SetConsoleTitle.call("#{GAME_TITLE} - #{sprintf("%08d", GAME_HANDLE)}")
  @@SetForegroundWindow.call(GAME_HANDLE)
  #--------------------------------------------------------------------------
  # ● カウント変数の初期化
  #--------------------------------------------------------------------------
  CONOUT   = @@GetStdHandle.call(0xFFFFFFF5)  # 標準出力ハンドル
  CONIN    = @@GetStdHandle.call(0xFFFFFFF6)  # 標準入力ハンドル
  CONERROR = @@GetStdHandle.call(0xFFFFFFF4)  # 標準エラーハンドル
  #--------------------------------------------------------------------------
  # ● カウント変数の初期化
  #--------------------------------------------------------------------------
  @@last_time = Time.now  # 最後に出力した時間
  @@wait_time = 0.6       # 待ち時間 (s)
  
  #--------------------------------------------------------------------------
  # ● 待ち時間の設定
  #--------------------------------------------------------------------------
  def self.wait=(second)
    @@wait_time = second
  end
  #--------------------------------------------------------------------------
  # ● コンソール出力
  #--------------------------------------------------------------------------
  #   text   : 出力する文字
  #   戻り値 : 出力した文字数
  #--------------------------------------------------------------------------
  def self.out(text)
    text = text.to_s unless String === text
    text = NKF.nkf('-s -x -m0', text)
    @@WriteConsole.call(CONOUT, text, text.size, sz = [0].pack("L"), nil)
    return sz.unpack("L")[0]
  end
  #--------------------------------------------------------------------------
  # ● コンソール出力 (最後に改行)
  #--------------------------------------------------------------------------
  #   text   : 出力する文字
  #   戻り値 : 出力した文字数
  #--------------------------------------------------------------------------
  def self.outl(text)
    text = text.to_s unless String === text
    text = NKF.nkf('-s -x -m0', "#{text}\n")
    @@WriteConsole.call(CONOUT, text, text.size, sz = [0].pack("L"), nil)
    return sz.unpack("L")[0]
  end
  #--------------------------------------------------------------------------
  # ● コンソール出力 (デバッグ出力)
  #--------------------------------------------------------------------------
  #   texts  : 出力する文字
  #   戻り値 : 出力した文字数
  #--------------------------------------------------------------------------
  def self.outp(*texts)
    if texts.empty?
      msg = "wrong number of arguments (#{texts.size} for 1)"
      raise ArgumentError, msg, caller 
    end
    sz = [0].pack("L")
    for text in texts
      output = NKF.nkf('-s -x -m0', "#{text.inspect}\n")
      @@WriteConsole.call(CONOUT, output, output.size, sz, nil)
    end
    return sz.unpack("L")[0]
  end
  #--------------------------------------------------------------------------
  # ● コンソール出力 (キー押し待ち)
  #--------------------------------------------------------------------------
  #   texts  : 出力する文字
  #   戻り値 : 出力した文字数
  #--------------------------------------------------------------------------
  def self.outi(*texts)
   if texts.empty?
      msg = "wrong number of arguments (#{texts.size} for 1)"
      raise ArgumentError, msg, caller 
    end
    return (Input.press?(CAO::Debug::KEY_OUTPUT) ? outp(*texts) : 0)
  end
  #--------------------------------------------------------------------------
  # ● コンソール出力 (ウェイト)
  #--------------------------------------------------------------------------
  #   texts  : 出力する文字
  #   戻り値 : 出力した文字数
  #--------------------------------------------------------------------------
  def self.outw(*texts)
    if texts.empty?
      msg = "wrong number of arguments (#{texts.size} for 1)"
      raise ArgumentError, msg, caller 
    end
    sz = 0
    unless Time.now - @@last_time < @@wait_time
      @@last_time = Time.now
      sz = outp(*texts)
    end
    return sz
  end
  #--------------------------------------------------------------------------
  # ● コンソール出力 (ライン)
  #--------------------------------------------------------------------------
  #   texts  : 出力する文字
  #   戻り値 : 出力した文字数
  #--------------------------------------------------------------------------
  def self.line(text = "=")
    text = "=" if text.size != text.split(//).size
    return outl(text * (60 / text.size))
  end
  #--------------------------------------------------------------------------
  # ● コンソール出力 (処理速度)
  #--------------------------------------------------------------------------
  #   num    : 計測する回数
  #   戻り値 : 平均時間
  #--------------------------------------------------------------------------
  def self.measure(num = 1)
    times = []
    num.times {
      time = Time.now
      yield
      times << Time.now - time
    }
    total = 0.0
    times.each { |i| total += i }
    average = total / times.size
    outl(sprintf("Time : %6.4f s ", average))
    return average
  end
end
end # if $TEST
