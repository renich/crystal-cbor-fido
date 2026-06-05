var data = {lines:[
{"lineNum":"    1","line":"require \"crystal/pointer_linked_list\""},
{"lineNum":"    2","line":""},
{"lineNum":"    3","line":"class Fiber"},
{"lineNum":"    4","line":"  # :nodoc:"},
{"lineNum":"    5","line":"  struct PointerLinkedListNode"},
{"lineNum":"    6","line":"    include Crystal::PointerLinkedList::Node","class":"lineNoCov","hits":"0","possible_hits":"5",},
{"lineNum":"    7","line":""},
{"lineNum":"    8","line":"    def initialize(@fiber : Fiber)","class":"lineNoCov","hits":"0","possible_hits":"4",},
{"lineNum":"    9","line":"    end","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   10","line":""},
{"lineNum":"   11","line":"    def enqueue : Nil","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   12","line":"      @fiber.enqueue","class":"lineNoCov","hits":"0","possible_hits":"1",},
{"lineNum":"   13","line":"    end"},
{"lineNum":"   14","line":"  end"},
{"lineNum":"   15","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:36:10", "instrumented" : 5, "covered" : 0,};
var merged_data = [];
