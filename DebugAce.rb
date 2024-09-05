#******************************************************************************
#
#    ＊ デバッグエース
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールXP & RPGツクールVX
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： RPGツクールVXAce で追加された組み込み関数を追加します。
#       (rgss_main, rgss_stop, msgbox, msgbox_p)
#    ： コンソールウィンドウに文字を出力する機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ ゲームが異常終了すると、コンソールが閉じられなくなることがあります。
#       そのコンソールは消せませんので、パソコンを再起動してください。
#
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   このスクリプトには設定項目はありません。                  #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


alias msgbox   print          # 
alias msgbox_p p              # 
def print(*args); end         # 
def p(*args); end             # 

class Reset < Exception; end
def rgss_main
  begin
    yield
  rescue Errno::ENOENT
    filename = $!.message.sub("No such file or directory - ", "")
    msgbox("ファイル #{filename} が見つかりません。")
  rescue Reset
    $scene = nil
    GC.start
    retry
  end
end
def rgss_stop
  loop { Graphics.update }
end

if $DEBUG || $TEST || $BTEST

def print(*texts)
  texts.each {|text| Console.write("#{text.to_s}") }
end
def puts(*texts)
  texts.each {|text| Console.write("#{text.to_s}\n") }
end
def p(*texts)
  texts.each {|text| Console.write("#{text.inspect}\n") }
end

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
  
  @@GetPrivateProfileString = 
    Win32API.new('kernel32','GetPrivateProfileStringA','pppplp','l')
  
  @@MultiByteToWideChar =
    Win32API.new('kernel32', 'MultiByteToWideChar', 'ilpipi', 'i')
  @@WideCharToMultiByte =
    Win32API.new('kernel32', 'WideCharToMultiByte', 'ilpipipp', 'i')
  
  CP_ACP  = 0x0000
  CP_UTF8 = 0xFDE9
  
  #--------------------------------------------------------------------------
  # ● UTF-8 を Shift_JIS へ変換
  #--------------------------------------------------------------------------
  def self.conv_sjis(str)
    len = @@MultiByteToWideChar.call(CP_UTF8, 0, str, -1, nil, 0) * 2 - 2
    buf1 = [""].pack("Z#{len}")
    @@MultiByteToWideChar.call(CP_UTF8, 0, str, -1, buf1, len)
    
    len = @@WideCharToMultiByte.call(CP_ACP, 0, buf1, -1, nil, 0, nil, nil) - 1
    buf2 = [""].pack("Z#{len}")
    @@WideCharToMultiByte.call(CP_ACP, 0, buf1, -1, buf2, len, nil, nil)
    
    return buf2
  end
  #--------------------------------------------------------------------------
  # ● Shift_JIS を UTF-8 へ変換
  #--------------------------------------------------------------------------
  def self.conv_utf8(str)
    len = @@MultiByteToWideChar.call(CP_ACP, 0, str, -1, nil, 0) * 2 - 2
    buf1 = [""].pack("Z#{len}")
    @@MultiByteToWideChar.call(CP_ACP, 0, str, -1, buf1, len)
    
    len = @@WideCharToMultiByte.call(CP_UTF8, 0, buf1, -1, nil, 0, nil, nil) - 1
    buf2 = [""].pack("Z#{len}")
    @@WideCharToMultiByte.call(CP_UTF8, 0, buf1, -1, buf2, len, nil, nil)
    
    return buf2
  end
  #--------------------------------------------------------------------------
  # ● ゲームのタイトルの取得
  #--------------------------------------------------------------------------
  def self.GetGameTitle(fn, section, key)
    buffer = [""].pack('Z256')
    @@GetPrivateProfileString.call(section, key, '', buffer, buffer.size, fn)
    return buffer.unpack('Z256').first
  end
  
  #--------------------------------------------------------------------------
  # ● ゲームのタイトルとハンドルの取得
  #--------------------------------------------------------------------------
  unless $!
    GAME_TITLE  = GetGameTitle('.\Game.ini', 'Game', 'Title')
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
  # ● コンソール出力
  #--------------------------------------------------------------------------
  #   text   : 出力する文字
  #   戻り値 : 出力した文字数
  #--------------------------------------------------------------------------
  def self.write(text)
    text = conv_sjis(text.to_s)
    sz = [0].pack("L")
    @@WriteConsole.call(CONOUT, text, text.size, sz, nil)
    return sz.unpack("L")[0]
  end
end

end # if $DEBUG || $TEST || $BTEST
