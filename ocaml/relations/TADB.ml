open ZVG_modules

let nodes_to_other_nodes
    l1
    l2
    z1
    z2
    = 
  (
    List.concat
      (List.map
         (function a ->
           let
               lz4 = out_adjacency_with_delay_earlier l2 z2 a
           in
           List.map
             (function z3 -> (z3, lz4))
             (out_adjacency l1 z1 a)
         )
         (ZVGQuotient2.actions l1)
      )
      ,
    List.concat
      (List.map
         (function a ->
           let
               lz3 = out_adjacency_with_delay_earlier l1 z1 a
           in
           List.map
             (function z4 -> (lz3, z4))
             (out_adjacency l2 z2 a)
         )
         (ZVGQuotient2.actions l2)
      )
  )
