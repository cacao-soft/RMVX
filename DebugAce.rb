#******************************************************************************
#
#    �� �f�o�b�O�G�[�X
#
#  --------------------------------------------------------------------------
#    �o�[�W���� �F 1.0.0
#    ��      �� �F RPG�c�N�[��XP & RPG�c�N�[��VX
#    ��  ��  �� �F �b�`�b�`�n
#    �z  �z  �� �F http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == �T    �v ==
#
#    �F RPG�c�N�[��VXAce �Œǉ����ꂽ�g�ݍ��݊֐���ǉ����܂��B
#       (rgss_main, rgss_stop, msgbox, msgbox_p)
#    �F �R���\�[���E�B���h�E�ɕ������o�͂���@�\��ǉ����܂��B
#
#  --------------------------------------------------------------------------
#   == ���ӎ��� ==
#
#    �� �Q�[�����ُ�I������ƁA�R���\�[���������Ȃ��Ȃ邱�Ƃ�����܂��B
#       ���̃R���\�[���͏����܂���̂ŁA�p�\�R�����ċN�����Ă��������B
#
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                   ���̃X�N���v�g�ɂ͐ݒ荀�ڂ͂���܂���B                  #
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
    msgbox("�t�@�C�� #{filename} ��������܂���B")
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
  # �� Win32API
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
  # �� UTF-8 �� Shift_JIS �֕ϊ�
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
  # �� Shift_JIS �� UTF-8 �֕ϊ�
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
  # �� �Q�[���̃^�C�g���̎擾
  #--------------------------------------------------------------------------
  def self.GetGameTitle(fn, section, key)
    buffer = [""].pack('Z256')
    @@GetPrivateProfileString.call(section, key, '', buffer, buffer.size, fn)
    return buffer.unpack('Z256').first
  end
  
  #--------------------------------------------------------------------------
  # �� �Q�[���̃^�C�g���ƃn���h���̎擾
  #--------------------------------------------------------------------------
  unless $!
    GAME_TITLE  = GetGameTitle('.\Game.ini', 'Game', 'Title')
    GAME_HANDLE = @@FindWindow.call("RGSS Player", GAME_TITLE)
  end
  #--------------------------------------------------------------------------
  # �� �R���\�[���E�B���h�E�̕\��
  #--------------------------------------------------------------------------
  @@AllocConsole.call
  @@SetConsoleTitle.call("#{GAME_TITLE} - #{sprintf("%08d", GAME_HANDLE)}")
  @@SetForegroundWindow.call(GAME_HANDLE)
  #--------------------------------------------------------------------------
  # �� �J�E���g�ϐ��̏�����
  #--------------------------------------------------------------------------
  CONOUT   = @@GetStdHandle.call(0xFFFFFFF5)  # �W���o�̓n���h��
  CONIN    = @@GetStdHandle.call(0xFFFFFFF6)  # �W�����̓n���h��
  CONERROR = @@GetStdHandle.call(0xFFFFFFF4)  # �W���G���[�n���h��
  
  #--------------------------------------------------------------------------
  # �� �R���\�[���o��
  #--------------------------------------------------------------------------
  #   text   : �o�͂��镶��
  #   �߂�l : �o�͂���������
  #--------------------------------------------------------------------------
  def self.write(text)
    text = conv_sjis(text.to_s)
    sz = [0].pack("L")
    @@WriteConsole.call(CONOUT, text, text.size, sz, nil)
    return sz.unpack("L")[0]
  end
end

end # if $DEBUG || $TEST || $BTEST
