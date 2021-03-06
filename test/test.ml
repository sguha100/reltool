open Grammar_types
open Clock_constraint_utilities.Test
open Zone_stubs
open Zone_stubs_test
open UDBM_utilities.Test
open PCQueue_test
open Graph_functions2.Test
open Grammar_types.Test
open Parse_timed_automaton.Test
open ZVG_modules.Test

open Graph_functions2
open UDBM_utilities
let test107 () =
  "test107: [" ^
    (String.concat
       "; "
       (List.map
          (function zone -> dbm_to_string [|"X"; "Y"|] zone.zone_constraint2)
          (split_zone_list_on_dbm_list
             3
	     [|"X"; "Y"|]
             {Grammar_types.location_index = 1}
             (List.map
                (function constraint_list ->
                  match
                    (constraint_list_to_dbm_option
                       3
                       constraint_list
                    )
                  with
                  | Some dbm ->
                    {Grammar_types.zone_location2 =
                        {Grammar_types.location_index = 1};
                     Grammar_types.zone_constraint2 = dbm}
                )
                [
                  [(2, 1, false, 0); (2, 0, true, 8);
                   (1, 2, false, 6)]
                ]
             )
             (List.map
                (function zone ->
                  dbm_down
                    zone.zone_constraint2
                )
                (List.map
                   (function constraint_list ->
                     match
                       (constraint_list_to_dbm_option
                          3
                        constraint_list
                       )
                     with
                     | Some dbm ->
                       {Grammar_types.zone_location2 =
                           {Grammar_types.location_index = 1};
                        Grammar_types.zone_constraint2 = dbm}
                   )
                   [
                     [(2, 1, false, -2); (1, 2, false, 2);
                      (1, 0, false, 10); (0, 1, false, -2)] (*why
                                                              should
                                                              such a
                                                              DBM
                                                              exist?*)
                   ]
                )
             )
          )
       )
    ) ^ "]"

let execute =
  print_string test17;
  print_newline ();
  print_string test18;
  print_newline ();
  print_string test19;
  print_newline ();
  print_string test41;
  print_newline ();
  print_string test42;
  print_newline ();
  print_string test43;
  print_newline ();
  print_string test44;
  print_newline ();
  print_string test45;
  print_newline ();
  print_string test46;
  print_newline ();
  print_string test47;
  print_newline ();
  print_string test48;
  print_newline ();
  print_string test49;
  print_newline ();
  print_string test50;
  print_newline ();
  print_string test51;
  print_newline ();
  print_string test52;
  print_newline ();
  print_string test53;
  print_newline ();
  print_string test54;
  print_newline ();
  print_string test55;
  print_newline ();
  print_string test56;
  print_newline ();
  print_string test57;
  print_newline ();
  print_string test58;
  print_newline ();
  print_string test59;
  print_newline ();
  print_string test60;
  print_newline ();
  print_string test61;
  print_newline ();
  print_string test62;
  print_newline ();
  (* print_string test63; *)
  (* print_newline (); *)
  (* print_string test64; *)
  (* print_newline (); *)
  print_string test65;
  print_newline ();
  print_string test66;
  print_newline ();
  print_string test67;
  print_newline ();
  print_string test68;
  print_newline ();
  print_string test69;
  print_newline ();
  print_string test70;
  print_newline ();
  print_string test71;
  print_newline ();
  print_string test72;
  print_newline ();
  print_string test73;
  print_newline ();
  print_string test74;
  print_newline ();
  print_string test75;
  print_newline ();
  print_string test76;
  print_newline ();
  print_string test77;
  print_newline ();
  print_string test78;
  print_newline ();
  print_string test79;
  print_newline ();
  print_string test80;
  print_newline ();
  print_string test81;
  print_newline ();
  print_string test82;
  print_newline ();
  print_string test83;
  print_newline ();
  print_string test84;
  print_newline ();
  print_string test85;
  print_newline ();
  print_string test86;
  print_newline ();
  print_string test87;
  print_newline ();
  print_string test88;
  print_newline ();
  print_string test89;
  print_newline ();
  print_string test90;
  print_newline ();
  print_string test91;
  print_newline ();
  print_string test92;
  print_newline ();
  print_string test93;
  print_newline ();
  print_string test94;
  print_newline ();
  print_string test95;
  print_newline ();
  print_string test96;
  print_newline ();
  print_string test97;
  print_newline ();
  print_string test98;
  print_newline ();
  print_string test99;
  print_newline ();
  print_string test100;
  print_newline ();
  print_string test101;
  print_newline ();
  print_string test102;
  print_newline ();
  print_string test103;
  print_newline ();
  print_string test104;
  print_newline ();
  print_string (test105 ());
  print_newline ();
  print_string (test106 ());
  print_newline ();
  print_string (test106 ());
  print_newline ();
  print_string (test107 ());
  print_newline ();
  print_string (test151 ());
  print_newline ();
  exit 0
