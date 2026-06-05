var data = {lines:[
{"lineNum":"    1","line":"module Spec"},
{"lineNum":"    2","line":"  class ExampleGroup < Context"},
{"lineNum":"    3","line":"    # Wraps an `ExampleGroup` and a `Proc` that will eventually execute the"},
{"lineNum":"    4","line":"    # group."},
{"lineNum":"    5","line":"    struct Procsy"},
{"lineNum":"    6","line":"      # The group that will eventually run when calling `run`."},
{"lineNum":"    7","line":"      getter example_group : ExampleGroup"},
{"lineNum":"    8","line":""},
{"lineNum":"    9","line":"      # :nodoc:"},
{"lineNum":"   10","line":"      def initialize(@example_group : ExampleGroup, &@proc : ->)","class":"lineCov","hits":"4","order":"8064","possible_hits":"4",},
{"lineNum":"   11","line":"      end"},
{"lineNum":"   12","line":""},
{"lineNum":"   13","line":"      # Executes the wrapped example group, possibly executing other"},
{"lineNum":"   14","line":"      # `around_all` hooks before that."},
{"lineNum":"   15","line":"      def run"},
{"lineNum":"   16","line":"        @proc.call"},
{"lineNum":"   17","line":"      end"},
{"lineNum":"   18","line":"    end"},
{"lineNum":"   19","line":"  end"},
{"lineNum":"   20","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:36:10", "instrumented" : 1, "covered" : 1,};
var merged_data = [];
