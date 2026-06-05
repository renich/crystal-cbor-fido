var data = {lines:[
{"lineNum":"    1","line":"module Spec"},
{"lineNum":"    2","line":"  # :nodoc:"},
{"lineNum":"    3","line":"  def self.lines_cache","class":"lineCov","hits":"1","order":"9569","possible_hits":"1",},
{"lineNum":"    4","line":"    @@lines_cache ||= {} of String => Array(String)","class":"lineCov","hits":"1","order":"9570","possible_hits":"1",},
{"lineNum":"    5","line":"  end"},
{"lineNum":"    6","line":""},
{"lineNum":"    7","line":"  # :nodoc:"},
{"lineNum":"    8","line":"  def self.read_line(file, line)","class":"lineCov","hits":"1","order":"9556","possible_hits":"1",},
{"lineNum":"    9","line":"    return nil unless File.file?(file)","class":"lineCov","hits":"1","order":"9557","possible_hits":"1",},
{"lineNum":"   10","line":""},
{"lineNum":"   11","line":"    lines = lines_cache.put_if_absent(file) { File.read_lines(file) }","class":"lineCov","hits":"3","order":"9568","possible_hits":"3",},
{"lineNum":"   12","line":"    lines[line - 1]?","class":"linePartCov","hits":"1","order":"9709","possible_hits":"2",},
{"lineNum":"   13","line":"  end"},
{"lineNum":"   14","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:36:36", "instrumented" : 6, "covered" : 6,};
var merged_data = [];
