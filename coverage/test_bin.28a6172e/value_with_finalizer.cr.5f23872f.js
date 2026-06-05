var data = {lines:[
{"lineNum":"    1","line":"# :nodoc:"},
{"lineNum":"    2","line":"class Crystal::ValueWithFinalizer(T)"},
{"lineNum":"    3","line":"  getter value : T"},
{"lineNum":"    4","line":""},
{"lineNum":"    5","line":"  def initialize(@value : T, @finalizer : T ->)","class":"lineCov","hits":"8","order":"7462","possible_hits":"8",},
{"lineNum":"    6","line":"  end"},
{"lineNum":"    7","line":""},
{"lineNum":"    8","line":"  def finalize","class":"lineNoCov","hits":"0","possible_hits":"4",},
{"lineNum":"    9","line":"    @finalizer.call(@value)","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   10","line":"  end"},
{"lineNum":"   11","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:36:36", "instrumented" : 3, "covered" : 1,};
var merged_data = [];
