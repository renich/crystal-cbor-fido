var data = {lines:[
{"lineNum":"    1","line":"module Sync"},
{"lineNum":"    2","line":"  enum Type"},
{"lineNum":"    3","line":"    # The lock doesn\'t do any checks. Trying to relock will cause a deadlock,"},
{"lineNum":"    4","line":"    # unlocking from any fiber is undefined behavior."},
{"lineNum":"    5","line":"    Unchecked","class":"lineCov","hits":"2","order":"7059","possible_hits":"2",},
{"lineNum":"    6","line":""},
{"lineNum":"    7","line":"    # The lock checks whether the current fiber owns the lock. Trying to"},
{"lineNum":"    8","line":"    # relock will raise a `Error::Deadlock` exception, unlocking when unlocked"},
{"lineNum":"    9","line":"    # or while another fiber holds the lock will raise an `Error`."},
{"lineNum":"   10","line":"    Checked"},
{"lineNum":"   11","line":""},
{"lineNum":"   12","line":"    # Same as `Checked` with the difference that the lock allows the same"},
{"lineNum":"   13","line":"    # fiber to re-lock as many times as needed, then must be unlocked as many"},
{"lineNum":"   14","line":"    # times as it was re-locked."},
{"lineNum":"   15","line":"    Reentrant","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"   16","line":"  end"},
{"lineNum":"   17","line":"end"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test_bin", "date" : "2026-06-05 05:36:10", "instrumented" : 2, "covered" : 1,};
var merged_data = [];
