var data = {lines:[
{"lineNum":"    1","line":"require \"c/stdlib\""},
{"lineNum":"    2","line":""},
{"lineNum":"    3","line":"# Prefer explicit exit over returning the status, so we are free to resume the"},
{"lineNum":"    4","line":"# main thread\'s fiber on any thread, without occurring a weird behavior where"},
{"lineNum":"    5","line":"# another thread returns from main when the caller might expect the main thread"},
{"lineNum":"    6","line":"# to be the one returning."},
{"lineNum":"    7","line":""},
{"lineNum":"    8","line":"fun main(argc : Int32, argv : UInt8**) : Int32","class":"lineCov","hits":"1","order":"13","possible_hits":"1",},
{"lineNum":"    9","line":"  status = Crystal.main(argc, argv)","class":"lineCov","hits":"1","order":"14","possible_hits":"1",},
{"lineNum":"   10","line":"  LibC.exit(status)","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   11","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:36:10", "instrumented" : 3, "covered" : 2,};
var merged_data = [];
