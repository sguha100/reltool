open Grammar_types
open Zone_stubs
open UDBM_utilities
open Clock_constraint_utilities
open ZVG_tree

open NRQueue
open PCQueue
open PCQueueElement

let split_zone_list_on_constraint_list
    clock_names
    location
    zone_list
    constraint_list =
  List.map
    (function dbm -> {zone_location2 = location; zone_constraint2 = dbm})
    (List.fold_left
       (split_raw_t_list_on_clock_constraint clock_names)
       (List.map
          (function zone -> zone.zone_constraint2)
          zone_list
       )
       (constraint_list)
    )

let split_zone_list_on_raw_t_list
    dim
    location
    zone_list
    dbm_list =
  List.map
    (function dbm -> {zone_location2 = location; zone_constraint2 = dbm})
    (List.fold_left
       (split_raw_t_list_on_raw_t dim)
       (List.map
          (function zone -> zone.zone_constraint2)
          zone_list
       )
       (dbm_list)
    )
    
let init_zone_list_array ta =
  let
      dim = 1 + ta.numclocks
  in
  (Array.init
     ta.numlocations
     (function i ->
       if
         (i = ta.numinit)
       then
         [{zone_location2 = i;
           zone_constraint2 =
             dbm_up (dbm_zero (dbm_init dim) dim) dim
          }]
       else
         []
     )
  )

let init_tree_array ta = 
  (Array.init
     ta.numlocations
     (function i -> init_tree ())
  )

let useful_predecessor_zones
    ta
    predecessor_zone_list
    edge_condition =
  let
      dim = 1 + ta.numclocks
  in
  List.filter
    (function zone ->
      match
        clock_constraint_to_raw_t_option
          ta.clock_names
          edge_condition
      with
      | None -> false
      | Some edge_condition -> 
        dbm_haveIntersection
          (dbm_up zone.zone_constraint2 dim)
          edge_condition
          dim
    )
    predecessor_zone_list

let maximum_constant_abstract_dbm ta raw_t_without_abstraction =
  let
      abstraction = ref false
  in
  let
      maxcon = maximum_constant ta
  in
  let
      dim = 1+ta.numclocks
  in
  let
      constraint_list_without_abstraction =
    dbm_toConstraintList raw_t_without_abstraction dim
  in
  let
      constraint_list_with_abstraction =
    List.concat 
      (List.map
         (function (i, j, strictness, bound) ->
           if
             (bound > maxcon)
           then
             (abstraction := true;
              Printf.printf "%s\n" "ABSTRACTION!";
              flush stdout;
              [])
           else
             if
               (bound < (-maxcon))
             then
               (abstraction := true;
                Printf.printf "%s\n" "ABSTRACTION!";
                flush stdout;
                [(i, j, true, -maxcon)])
             else
               [(i, j, strictness, bound)]
         )
         constraint_list_without_abstraction
      )
  in
  let
      raw_t_with_abstraction =
    match
      (constraint_list_to_raw_t_option dim constraint_list_with_abstraction)
    with
    | Some dbm -> dbm
    | None ->
      raise
        (Invalid_argument
           ("Abstraction failed, Constraint_list_without_abstraction = "
            ^ (constraint_list_to_string
                 ta.clock_names
                 constraint_list_without_abstraction
            ) ^ ", constraint_list_with_abstraction = " ^
              (constraint_list_to_string
                 ta.clock_names
                 constraint_list_with_abstraction
              )
           )
        )
  in
  (raw_t_with_abstraction, !abstraction)

let rec maximum_constant_abstract_zone_list ta zone_list =
  let
      dim = 1 + ta.numclocks
  in
  let
      (abstracted_zones, unabstracted_zones) =
    List.fold_left
      (function (abstracted_zones, unabstracted_zones) ->
        function next_zone ->
          match
            maximum_constant_abstract_dbm ta next_zone.zone_constraint2
          with
          | (_, false) ->
            Printf.printf "The zone (%s, %s) did not get abstracted.\n"
              (string_of_int next_zone.zone_location2)
              (raw_t_to_string ta.clock_names next_zone.zone_constraint2);
            (abstracted_zones, next_zone::unabstracted_zones)
          | (abstracted_raw_t, true) ->
            Printf.printf "The zone (%s, %s) got abstracted to (%s, %s)\n"
              (string_of_int next_zone.zone_location2)
              (raw_t_to_string ta.clock_names next_zone.zone_constraint2)
              (string_of_int next_zone.zone_location2)
              (raw_t_to_string ta.clock_names abstracted_raw_t)
            ;
            ({zone_location2 = next_zone.zone_location2;
              zone_constraint2 = abstracted_raw_t}::abstracted_zones,
             unabstracted_zones
            )
      )
      ([], [])
      zone_list
  in
  let
      new_zone_list =
    List.fold_left
      (function old_zone_list ->
        function abstracted_zone ->
          let
              abstracted_zone_after_split = 
            (List.filter
               (function zone1 ->
                 List.for_all
                   (function zone2 ->
                     not
                       (dbm_haveIntersection
                          zone1.zone_constraint2
                          zone2.zone_constraint2
                          dim
                       )
                   )
                   old_zone_list
               )
               (split_zone_list_on_raw_t_list
                  dim
                  abstracted_zone.zone_location2
                  [abstracted_zone]
                  (List.map
                     (function zone -> zone.zone_constraint2)
                     old_zone_list
                  )
               )
            )
          in
          Printf.printf
            "The abstracted zone (%s, %s) got split into [%s]\n"
            (string_of_int abstracted_zone.zone_location2)
            (raw_t_to_string
               ta.clock_names
               abstracted_zone.zone_constraint2)
            (String.concat
               "; "
               (List.map
                  (function zone ->
                    "(" ^
                      (string_of_int zone.zone_location2)
                    ^ ", " ^
                      (raw_t_to_string ta.clock_names zone.zone_constraint2)
                    ^ ")"
                  )
                  abstracted_zone_after_split
               )
            )
          ;
          abstracted_zone_after_split @ old_zone_list
      )
      unabstracted_zones
      abstracted_zones
  in
  new_zone_list
    
let successor_zones_from_predecessor
    ta
    predecessor_zone_list
    edge =
  let dim = 1 + ta.numclocks in
  let maxcon = maximum_constant ta in
  match
    clock_constraint_to_raw_t_option
      ta.clock_names
      edge.condition
  with
  | None -> []
  | Some edge_condition ->
    List.map
      (function zone ->
        {zone_location2 = edge.next_location;
         zone_constraint2 =
            let
                raw_t_without_abstraction =
              dbm_up
                (raw_t_after_clock_resets
                   ta.clock_names
                   edge.clock_resets
                   (dbm_intersection
                      edge_condition
                      (dbm_up zone.zone_constraint2 dim)
                      dim
                   )
                )
                dim
            in
            raw_t_without_abstraction
        }
      )
      (useful_predecessor_zones
         ta
         predecessor_zone_list
         edge.condition
      )
      
let new_successor_zones
    ta
    predecessor
    predecessor_zone_list
    edge
    successor
    successor_zone_list =
  let dim = 1 + ta.numclocks in
  List.fold_left
    (function successor_zone_list -> function z1 ->
      (List.filter
         (function z1 ->
           List.for_all
             (function z2 -> not
               (dbm_haveIntersection
                  z1.zone_constraint2
                  z2.zone_constraint2
                  dim
               )
             )
             successor_zone_list
         )
         (split_zone_list_on_raw_t_list
            dim
            successor
            [z1]
            (List.map
               (function z2 -> z2.zone_constraint2)
               successor_zone_list
            )
         )
      )
      @
        (split_zone_list_on_raw_t_list
           dim
           successor
           successor_zone_list
           [z1.zone_constraint2]
        )
    )
    successor_zone_list
    (successor_zones_from_predecessor
       ta
       predecessor_zone_list
       edge
    )

let self_split ta location zone_list =
  let
      constraint_list =
    (ta.locations.(location).invariant
     ::
       (List.concat
          (List.map
             (function departure ->
               [departure.condition
               ;
                (clock_constraint_without_reset_clocks
                   ta.locations.(departure.next_location).invariant
                   departure.clock_resets
                )
               ]
             )
             (Array.to_list ta.locations.(location).departures)
          )
       )
    )
  in
  (Printf.printf
     "Self-splitting location %s, constraint_list length = %s\n"
     (string_of_int location)
     (string_of_int (List.length constraint_list))
  );
  flush stdout;
  (split_zone_list_on_constraint_list
     ta.clock_names
     location
     zone_list
     constraint_list
  )

let rec empty_queue2 ta (queue, zone_list_array) =
  try
    (match
        dequeue queue
     with
     | (e, new_queue1) ->
       (Printf.printf "new_queue1 = [%s]\n"
          (String.concat
             "; "
             (List.map
                (function e -> string_of_int e.child)
                new_queue1
             )
          )
       );
       let
           changed_zone_list1 =
         match
           (e.parent, e.edge)
         with
         | (None, None) ->
           Printf.printf "%s\n" "No parent!";
           zone_list_array.(e.child)
         | (Some parent, Some edge) ->
           Printf.printf "parent: %s\n" (string_of_int parent);
           Printf.printf "parent zones: [%s]\n"
             (String.concat
                "; "
                (List.map
                   (function zone -> raw_t_to_string ta.clock_names zone.zone_constraint2)
                   zone_list_array.(parent)
                )
             )
           ;
           (new_successor_zones
              ta
              parent
              zone_list_array.(parent)
              edge
              e.child
              zone_list_array.(e.child)
           )
       in
       let
           changed_zone_list2 =
         self_split ta e.child changed_zone_list1
       in
       let
           changed_zone_list3 =
         maximum_constant_abstract_zone_list ta changed_zone_list2
       in
       let
           new_queue2 =
         Printf.printf "changed_zone_list2 length = %s, changed_zone_list1 length = %s, earlier %s \n"
           (string_of_int (List.length changed_zone_list2))
           (string_of_int (List.length changed_zone_list1))
           (string_of_int (List.length zone_list_array.(e.child)))
         ;
         if
           ((List.length changed_zone_list3) > (List.length zone_list_array.(e.child))
            || e.parent = None
           (*When the parent is None, the zone is new anyway,
             so the successors should be enqueued.*)
           )
         then
           (
            (* Printf.printf *)
            (*   "changed_zone_list2 = [%s]\n" *)
            (*   (String.concat *)
            (*      "; " *)
            (*      (List.map *)
            (*         (function zone -> *)
            (*           "(" ^ (string_of_int zone.zone_location2) ^ ", " ^ *)
            (*             (raw_t_to_string ta.clock_names zone.zone_constraint2) ^ ")" *)
            (*         ) *)
            (*         changed_zone_list2 *)
            (*      ) *)
            (*   ) *)
            (* ; *)
            (* Printf.printf *)
            (*   "changed_zone_list3 = [%s]\n" *)
            (*   (String.concat *)
            (*      "; " *)
            (*      (List.map *)
            (*         (function zone -> *)
            (*           "(" ^ (string_of_int zone.zone_location2) ^ ", " ^ *)
            (*             (raw_t_to_string ta.clock_names zone.zone_constraint2) ^ ")" *)
            (*         ) *)
            (*         changed_zone_list3 *)
            (*      ) *)
            (*   ) *)
            (* ; *)
            zone_list_array.(e.child) <- changed_zone_list3;
            List.fold_left
              (function new_queue1 -> function departure ->
                enqueue
                  new_queue1
                  {child = departure.next_location;
                   parent = Some e.child;
                   edge = Some departure
                  }
              )
              new_queue1
              (Array.to_list ta.locations.(e.child).departures)
           )
         else
           new_queue1
       in
       (Printf.printf "new_queue2 = [%s]\n"
          (String.concat
             "; "
             (List.map
                (function e -> string_of_int e.child)
                new_queue2
             )
          )
       );
       empty_queue2 ta (new_queue2, zone_list_array)
    )
  with
  | Empty_queue ->
    Printf.printf "%s\n" "Empty_queue caught!";
    (queue, zone_list_array)

let generate_zone_valuation_graph ta =
  Printf.printf "%s\n" "generate_zone_valuation_graph called!";
  let dim = 1 + ta.numclocks in
  let zone_list_array = 
    match
      Printf.printf "%s\n" "Calling empty_queue2!";
    (empty_queue2
       ta
       (enqueue empty {parent = None; edge = None; child = ta.numinit},
        (init_zone_list_array ta)
       )
    )
    with
      (_, zone_list_array) -> zone_list_array
  in
  let rec
      backward_propagate () =
    let
        new_zone = ref false
    in
    Array.iter
      (function l1 ->
        Array.iter
          (function departure ->
            let
                (splittable, unsplittable) =
              List.partition
                (function zone ->
                  match
                    (clock_constraint_to_raw_t_option
                       ta.clock_names
                       departure.condition
                    )
                  with
                  | None -> false
                  | Some departure_condition_raw_t -> 
                    dbm_haveIntersection
                      (zone.zone_constraint2)
                      (departure_condition_raw_t)
                      dim
                )
                zone_list_array.(l1.location_index)
            in
            let
                changed_zone_list =
              split_zone_list_on_raw_t_list
                dim
                l1.location_index
                splittable
                (List.map
                   (function zone ->
                     (raw_t_without_reset_clocks
                        ta.clock_names
                        departure.clock_resets
                        zone.zone_constraint2
                     )
                   )
                   zone_list_array.(departure.next_location)
                )
            in
            (if
                (List.length changed_zone_list >
                   List.length splittable
                )
             then
                (new_zone := true;
                 zone_list_array.(l1.location_index) <-
                   changed_zone_list @ unsplittable
                )
             else
                ()
            )
            ;
          )
          l1.departures
      )
      (ta.locations)
    ;
    if
      !new_zone
    then
      backward_propagate ()
    else
      ()
  in
  backward_propagate ();
  let
      graph = 
    Array.map
      (function zone_list ->
        List.map
          (function zone ->
            (zone,
             let
                 departures =
               {action = -1;
                condition = [True];
                clock_resets = [||];
                next_location = zone.zone_location2
               } (*This one is a time transition.*)
               ::
                 (List.filter
                    (function departure ->
                      match
                        clock_constraint_to_raw_t_option
                          ta.clock_names
                          departure.condition
                      with
                      | None -> false
                      | Some departure_condition ->
                        dbm_haveIntersection
                          zone.zone_constraint2
                          departure_condition
                          dim
                    )
                    (Array.to_list
                       ta.locations.(zone.zone_location2).departures)
                 )
             in
             List.map
               (function departure ->
                 (departure,
                  if (departure.action >= 0) then (*action transition*)
                    (List.filter
                       (function arrival_zone ->
                         dbm_haveIntersection
                           (raw_t_after_clock_resets
                              ta.clock_names
                              departure.clock_resets
                              zone.zone_constraint2
                           )
                           arrival_zone.zone_constraint2
                           dim
                       )
                       zone_list_array.(departure.next_location)
                    )
                  else (*time transition*)
                    (List.filter
                       (function arrival_zone ->
                         (* clock_constraint_haveIntersection *)
                         (*   ta.clock_names *)
                         (*   zone.zone_constraint2 (\*TODO: make this upward unbounded!*\) *)
                         (*   arrival_zone.zone_constraint2 *)
                         (dbm_haveIntersection
                            (dbm_up zone.zone_constraint2 dim)
                            arrival_zone.zone_constraint2
                            dim)
                        )
                         zone_list_array.(departure.next_location)
                       )
                    )
                 )
                   departures
               )
            )
              zone_list
          )
          zone_list_array
       in
      graph

