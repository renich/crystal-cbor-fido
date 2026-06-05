var data = {lines:[
{"lineNum":"    1","line":"require \"./user\""},
{"lineNum":"    2","line":""},
{"lineNum":"    3","line":"module Crystal::System::Path"},
{"lineNum":"    4","line":"  def self.home : String","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"    5","line":"    if home_path = ENV[\"HOME\"]?.presence","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"    6","line":"      home_path"},
{"lineNum":"    7","line":"    else"},
{"lineNum":"    8","line":"      id = LibC.getuid","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"    9","line":""},
{"lineNum":"   10","line":"      pwd = uninitialized LibC::Passwd"},
{"lineNum":"   11","line":"      pwd_pointer = Pointer(LibC::Passwd).null","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   12","line":"      ret = LibC::Int.new(0)","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   13","line":"      System.retry_with_buffer(\"getpwuid_r\", User::GETPW_R_SIZE_MAX) do |buf|","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   14","line":"        ret = LibC.getpwuid_r(id, pointerof(pwd), buf, buf.size, pointerof(pwd_pointer)).tap do","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   15","line":"          # It\'s not necessary to check success with `ret == 0` because `pwd_pointer` will be NULL on failure"},
{"lineNum":"   16","line":"          return String.new(pwd.pw_dir) if pwd_pointer","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   17","line":"        end"},
{"lineNum":"   18","line":"      end"},
{"lineNum":"   19","line":""},
{"lineNum":"   20","line":"      raise RuntimeError.from_os_error(\"getpwuid_r\", Errno.new(ret))","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   21","line":"    end"},
{"lineNum":"   22","line":"  end"},
{"lineNum":"   23","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:37:16", "instrumented" : 9, "covered" : 0,};
var merged_data = [];
