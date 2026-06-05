var data = {lines:[
{"lineNum":"    1","line":"require \"c/unistd\""},
{"lineNum":"    2","line":""},
{"lineNum":"    3","line":"module Crystal::System"},
{"lineNum":"    4","line":"  def self.hostname","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"    5","line":"    String.new(255) do |buffer|","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"    6","line":"      unless LibC.gethostname(buffer, LibC::SizeT.new(255)) == 0","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"    7","line":"        raise RuntimeError.from_errno(\"Could not get hostname\")","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"    8","line":"      end"},
{"lineNum":"    9","line":"      len = LibC.strlen(buffer)","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   10","line":"      {len, len}"},
{"lineNum":"   11","line":"    end"},
{"lineNum":"   12","line":"  end"},
{"lineNum":"   13","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:37:16", "instrumented" : 5, "covered" : 0,};
var merged_data = [];
