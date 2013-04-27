open ZVG_modules
open Grammar_types
open Parse_timed_automaton

let _ =
  let first = ref "" in
  let second = ref "" in
  let
      speclist =
    [("-first", Arg.Set_string first, "first TA");
     ("-second", Arg.Set_string second, "second TA")]
  in
  let anon_fun = (function _ -> raise (Arg.Bad "illegal anonymous argument")) in
  let usage_msg = "usage: -first and -second are required." in
  Arg.parse speclist anon_fun usage_msg;
  let in1 = open_in !first in
  let in2 = open_in !second in
  let ta1 = parse_timed_automaton in1 in
  let ta2 = parse_timed_automaton in2 in
  let l1 = lts_of_zone_valuation_graph ta1 in
  let l2 = lts_of_zone_valuation_graph ta2 in
  let pi1 = ZVGLTS2.fernandez l1 in
  let pi2 = ZVGLTS2.fernandez l2 in
  let q1 = ZVGLTS2.quotient_lts l1 pi1 in
  let q2 = ZVGLTS2.quotient_lts l2 pi2 in
  Printf.printf
    "STAB: %s\n"
    (if STABChecker.check_relation_on_timed_automata ta1 ta2 q1 q2
     then "true"
     else "false");
  Printf.printf
    "TADB: %s\n"
    (if TADBChecker.check_relation_on_timed_automata ta1 ta2 q1 q2
     then "true"
     else "false");
  Printf.printf
    "TAOB: %s\n"
    (if TAOBChecker.check_relation_on_timed_automata ta1 ta2 q1 q2
     then "true"
     else "false");
  close_in in1;
  close_in in2;
  exit 0
