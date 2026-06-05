var data = {lines:[
{"lineNum":"    1","line":"module Spec"},
{"lineNum":"    2","line":"  class Example"},
{"lineNum":"    3","line":"    # Wraps an `Example` and a `Proc` that will eventually execute the"},
{"lineNum":"    4","line":"    # example."},
{"lineNum":"    5","line":"    struct Procsy"},
{"lineNum":"    6","line":"      # The example that will eventually run when calling `run`."},
{"lineNum":"    7","line":"      getter example : Example"},
{"lineNum":"    8","line":""},
{"lineNum":"    9","line":"      # :nodoc:"},
{"lineNum":"   10","line":"      def initialize(@example : Example, &@proc : ->)","class":"lineCov","hits":"4","order":"7991","possible_hits":"4",},
{"lineNum":"   11","line":"      end"},
{"lineNum":"   12","line":""},
{"lineNum":"   13","line":"      # Executes the wrapped example, possibly executing other"},
{"lineNum":"   14","line":"      # `around_each` hooks before that."},
{"lineNum":"   15","line":"      def run","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   16","line":"        @proc.call","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   17","line":"      end"},
{"lineNum":"   18","line":"    end"},
{"lineNum":"   19","line":"  end"},
{"lineNum":"   20","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:35:11", "instrumented" : 3, "covered" : 1,};
var merged_data = [];
