var data = {lines:[
{"lineNum":"    1","line":"# :nodoc:"},
{"lineNum":"    2","line":"module Crystal::System"},
{"lineNum":"    3","line":"  def self.retry_with_buffer(function_name, max_buffer, &)"},
{"lineNum":"    4","line":"    initial_buf = uninitialized UInt8[1024]"},
{"lineNum":"    5","line":"    buf = initial_buf.to_slice","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"    6","line":""},
{"lineNum":"    7","line":"    while (ret = yield buf) != 0","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"    8","line":"      case ret"},
{"lineNum":"    9","line":"      when LibC::ENOENT, LibC::ESRCH, LibC::EBADF, LibC::EPERM","class":"lineNoCov","hits":"0","possible_hits":"3",},
{"lineNum":"   10","line":"        return nil"},
{"lineNum":"   11","line":"      when LibC::ERANGE","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   12","line":"        raise RuntimeError.from_errno(function_name) if buf.size >= max_buffer","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   13","line":"        buf = Bytes.new(buf.size * 2)","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   14","line":"      else"},
{"lineNum":"   15","line":"        raise RuntimeError.from_errno(function_name)","class":"lineNoCov","hits":"0","possible_hits":"5",},
{"lineNum":"   16","line":"      end"},
{"lineNum":"   17","line":"    end"},
{"lineNum":"   18","line":"  end"},
{"lineNum":"   19","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:36:36", "instrumented" : 7, "covered" : 0,};
var merged_data = [];
