  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;Agent-Based Modelling Scenarios for the Development of Regional Industrial Symbiosis
;;;
;;;Demonstrate the potential of an Industrial symbiosis initiative around
;;;the sugar/wheat agricultural production in the Champagne Region (France).
;;;
;;;Copyright 2013 by Najet BICHRAOUI. All rights reserved. 
;;;No part of this model may be reproduced or transmitted in any form or
;;;by any means, electronic, photocopying, recording, or otherwise, without
;;;prior written permission of the author.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


extensions [ gis nw ]
;extensions [nw]

globals  [nodes-gis InL OutL one-partner exchange partnered non-partnered factories flows_qty  nn partner-pioneer land_use symbiosis_plants_data parcels_data parcels_datatopo
          roads_data WTplants_data perimeter-dataset polyline linkwith-n2
          nodes_list paths_list exchanges-pioneer exchanges-follower partner co2_pertonne_mile mydistance_km 
          Comingto
          ComningFrom
          ]

breed [plants plant]
breed [nodes node]
breed [trucks truck]

undirected-link-breed [paths path]
undirected-link-breed [roads road]
paths-own [fid center dist iti]

directed-link-breed [partnerships partnership]
partnerships-own [
ownerFrom ownerTo
ownerFromTurt ownerToTurt
  In out 
  resource_type resource_capacity
  new-partner? route-list route-node-list mydistance dist 

   ]


trucks-own [ 
  move-list move-list2 move-index done? total_length
  to-node cur-link speed behaviour orginWho origin destinName destination
  drive routes OriLocation itinerary distances ]

nodes-own [id end? start? behaviour]

plants-own [ 
  Object_id name  plocation Industry_type trust doubt behaviour cooperation involvment
  my_potential_partners
  my_current_partner
  my_partner
  my_partnerName

  
  myresource_capacity
  plant_type Type_Capacity
  mat_received
  mat_qty_received
  mat_received_from
  mat_received_fromName
  mat_sent
  mat_qty_sent
  mat_sent_to
  mat_sent_toName
  Incount outcount Input_list Output_list Input_capacity_list Output_capacity_list Normalized_Input_list_capacity Normalized_Output_list_capacity
  out_partners_memory
  in_partners_memory
  Totalflows Input_with_qty Ouput_with_qty
  GHG_partnered GHG_nonpartnered behaviour0_tax behaviour1_tax
  MMT_Co2
  mydist_from
  mydist_to]

patches-own [Total_GHGemissions GHGemissions GHG_pioneer GHG_follower ]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ---------- startup/setup/go ----------
to startup
  read-gis-datasets
end

to read-gis-datasets
  set symbiosis_plants_data  gis:load-dataset "data/List_plants_symb_topoVF_V1.shp"
  set perimeter-dataset      gis:load-dataset "data/departments_limites_TOPOVF.shp"
 
end

to setup-world-envelope
  let world (gis:envelope-of perimeter-dataset) ;; [ minimum-x maximum-x minimum-y maximum-y ]
  if zoom != 1 [
    let x0 (item 0 world + item 1 world) / 2          let y0 (item 2 world + item 3 world) / 2
    let W0 zoom * (item 0 world - item 1 world) / 2   let H0 zoom * (item 2 world - item 3 world) / 2
    set world (list (x0 - W0) (x0 + W0) (y0 - H0) (y0 + H0))
  ]
  gis:set-world-envelope (world)
end

to setup
  clear-all-but-globals
  import-world "data/WorldMarch20th world.csv"
  read-gis-datasets
  setup-world-envelope
  set-default-shape plants "circle"
  set-default-shape trucks "truck"
  set co2_pertonne_mile 0.00010951      ;= (0.0094 gal diesel/tonne mile) * (25,630 lbs TFC CO2 emissions/ 1000 gal) * (1 tonne / 2200 lbs)
  import-plants
  reset-ticks  
end




to import-plants
  ask patches 
  [
    set GHGemissions [] 
  ]
  
  ask plants [die]
  foreach gis:feature-list-of symbiosis_plants_data  
  [
    let location gis:location-of (first (first (gis:vertex-lists-of ?)))  
    if not empty? location 
    [
      create-plants 1 
      [
        set xcor item 0 location
        set ycor item 1 location
        set size 0.5
        set name gis:property-value ? "Name" 
        set Object_id gis:property-value ? "OBJECTID"
       
        set trust random  5
        set doubt random-float precision (0.9 + 0.5)  4
        set involvment precision (trust * doubt)      4
        
        set plocation min-one-of nodes [distance myself]           
        set Type_Capacity gis:property-value ? "Type_C"
        set Input_list []
        set Output_list []
        set Input_capacity_list []
        set Output_capacity_list []
        set myresource_capacity []
        set mat_received []
        set mat_sent []
        set flows_qty []
        
        set Input_list lput gis:property-value ? "Input1" input_list
        set Input_list lput gis:property-value ? "Input2" input_list
        set Input_list lput gis:property-value ? "Input3" input_list
        set Input_list lput gis:property-value ? "Input4" input_list
        set Input_list lput gis:property-value ? "Input5" input_list
        set Input_list lput gis:property-value ? "Input6" input_list
        set Input_list lput gis:property-value ? "Input7" input_list
        set Input_list lput gis:property-value ? "Input8" input_list
        set Input_list remove "" Input_list
        
        set Input_capacity_list lput gis:property-value ? "Input1_c" Input_capacity_list
        set Input_capacity_list lput gis:property-value ? "Input2_c" Input_capacity_list
        set Input_capacity_list lput gis:property-value ? "Input3_c" Input_capacity_list
        set Input_capacity_list lput gis:property-value ? "Input4_c" Input_capacity_list
        set Input_capacity_list lput gis:property-value ? "Input5_c" Input_capacity_list
        set Input_capacity_list lput gis:property-value ? "Input6_c2" Input_capacity_list
        set Input_capacity_list lput gis:property-value ? "Input7_c2" Input_capacity_list
        set Input_capacity_list lput gis:property-value ? "Input8_c2" Input_capacity_list
        set Input_capacity_list remove nobody Input_capacity_list
        set Input_capacity_list remove 0 Input_capacity_list
        
        Set Normalized_Input_list_capacity map [ ? / 50 ]  Input_capacity_list
        
        set Output_list lput gis:property-value ? "Output1" Output_list
        set Output_list lput gis:property-value ? "Output2" Output_list
        set Output_list lput gis:property-value ? "Output3" Output_list
        set Output_list lput gis:property-value ? "Output4" Output_list
        set Output_list lput gis:property-value ? "Output5" Output_list
        set Output_list remove "" Output_list
        
        set Output_capacity_list lput gis:property-value ? "Output1_c" Output_capacity_list
        set Output_capacity_list lput gis:property-value ? "Output2_c" Output_capacity_list
        set Output_capacity_list lput gis:property-value ? "Output3_c" Output_capacity_list
        set Output_capacity_list lput gis:property-value ? "Output4_c" Output_capacity_list
        set Output_capacity_list lput gis:property-value ? "Output5_c" Output_capacity_list
        set Output_capacity_list remove nobody Output_capacity_list
        set Output_capacity_list remove 0 Output_capacity_list
        
        Set Normalized_Output_list_capacity map [ ? / 50 ]  Output_capacity_list ;;; amount produced for the week
        
        set Incount length Input_list
        set Outcount length Output_list
        set Industry_type gis:property-value ? "TypeID" 
        
        set Totalflows sentence (Input_list)(Output_list)
        
        set Input_with_qty (map [list ?1 ?2] Input_list Normalized_Input_list_capacity )
        set Ouput_with_qty (map [list ?1 ?2] Output_list Normalized_Output_list_capacity)
        
        set MMT_Co2 gis:property-value ? "MMT_Co2"
        ask patch-here 
        [ set GHGemissions lput gis:property-value ? "MMT_Co2" GHGemissions ]
        
      ]
    ]
  ]
  
  

  ;;; setup plants ;;;
  ask plants
    [  
      ifelse (involvment > involvement_threshold_index) 
        [
          set plant_type "pioneer"
          set behaviour 1
          set GHG_partnered MMT_Co2
        ]
        [
          set plant_type "follower" 
          set behaviour 0
          set GHG_nonpartnered MMT_Co2
        ]
      check-behaviour-now
      
      ifelse (random-float 1.0 < cultural_cooperation_prob)         ;; Make plants with a frequency of cooperators determined by Cultural-coopration-prob slider contolled by the user. the higher % of cooperation the higher is likehood to get partnered         
        [set cooperation TRUE] 
        [set cooperation FALSE]  ;; if a random plant out of 20 is inferior to the initial number of coop probality, set the cooperation true, if not, set coop false    
    ]
  set factories plants

;  export-data

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GO COMMANDS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  
  EXCHANGE_MAT
  TRANSPORT
  if learn? [learn]; 
  ask plants [ emit_GHG]
  ifelse carbon_tax? [carbon_tax] []
  if check_influence_policy? [check_influence_carbon-policy]
 ;log-turtles-tick
; file-print-csv-row
 export-data
;write_BSpace_output2
  tick 
  if ticks >= 100 [stop]
  
end 




;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;;;;==============================================================================================;;;


to EXCHANGE_MAT
  ask plants with [behaviour = 1]
  [
    if check_need self > 0
    [
      find_new_partner
    ]
  ]  
  find-path  ; for new partnerships
end




;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;                                          find partner                                             ;



to-report check_need [plant_a]
  let x 0
  foreach needed_resources_list plant_a
  [
    set x (x + ?)
  ]
  report x
end

to-report needed_resources_list [plant_a]
  let d []
  ask plant_a
  [
    let a Input_list
    
    let b Normalized_Input_list_capacity  ;; full list of resources (capacity) needed
    let c current-input self   ;; full list of resources (capacity) got from somewhere
    
    let temp 0
    while [temp < length a]
    [
      set d lput 0 d
      set temp temp + 1
    ]
    
    set temp 0
    while [temp < length a]
    [
      let f item temp b        ;; one-of resource (capacity) need
      let g item temp c        ;; one-of received resources (capacity)
      let h (f - g)     
      set d replace-item temp d h       ;;  = index list value , replace the 0 with the number of capacity needed
      
      set temp temp + 1
    ]
  ]
  report d                     ;; report a full list about how many capacity still need to be found, full list means the length should be same as the input list.
end

to-report needed_name_list [plant_a]
  let new_need_list []
  ask plant_a
  [
    let a Input_list                   ;; full list
    let b needed_resources_list self   ;; full list
    
    let temp 0
    while [temp < length a]            ;; run a while loop with full list (length of full list)
    [
      if (item temp b > 0)
      [
        set new_need_list lput (item temp a) new_need_list
      ]
      set temp temp + 1
    ]
  ]
  report new_need_list                 ;; report a short list that all things in the list are still needed to be exchange
end

  
to-report left_resource_list [plant_a]
  let d []
  ask plant_a
  [
    let a Output_list                  ;; full list of output
    
    let b Normalized_Output_list_capacity         ;; full list of output capacity
    let c current-Output self          ;; full list of resource that were scheduled to be sent out
    
    let temp 0
    while [temp < length a]
    [
      set d lput 0 d                   ;; create a full list with the number 0
      set temp temp + 1
    ]
    
    set temp 0
    while [temp < length a]
    [
      let f item temp b                 ;; could supply
      let g item temp c                 ;; supply value that have been sent away
      let h (f - g)
      set d replace-item temp d h       ;;  = index list value , replace the 0 with the number of resource left
      
      set temp temp + 1
    ]
  ]
  report d                              ;; report a full list with the resources left, including 0 if all the resource already have been used
end

to-report left_name_list [plant_a]
  let new_left_list []
  ask plant_a
  [
    let a Output_list                                        ;; a full list
    let b left_resource_list self                            ;; a full list
    
    let temp 0
    while [temp < length a]                                  ;; while loop with full list
    [
      if (item temp b > 0)                                   ;; check if the output still not finished yet
      [
        set new_left_list lput (item temp a) new_left_list
      ]
      set temp temp + 1
    ]
  ]
  
  report new_left_list                                       ;; report a short list that all things in the list are left (still avaiable for exchange)
end

to-report current-input [plant_b]
  ; the resources that are already received (scheduled to be received)
  
  let c []
  ask plant_b
  [
    let a Input_list
    let b Input_capacity_list
    
    let temp 0
    while [temp < length a]
    [
      set c lput 0 c
      set temp temp + 1
    ]
    
    foreach sort my-in-partnerships
    [
      let d [resource_type] of ?
      let f [resource_capacity] of ?
      let g position d a             ;; index 
      let h item g c                 ;; current input capacity
      set h (h + f)
      set c replace-item g c h       ;; g c h = index list value
    ]
  ]
  report c                           ;; report a full list with how many of each resource have been scheduled to be received.
 ; set myresource_capacity resource_capacity
end

to-report current-output [plant_b]
  ; the resources that are already sent out (scheduled to be sent out)
  
  let c []
  ask plant_b
  [
    let a Output_list
    let b Normalized_Output_list_capacity
    
    let temp 0
    while [temp < length a]
    [
      set c lput 0 c
      set temp temp + 1
    ]
    
    foreach sort my-out-partnerships
    [
      let d [resource_type] of ?
      let f [resource_capacity] of ?
      let g position d a             ;; index 
      let h item g c                 ;; current output capacity list
      set h (h + f)
      set c replace-item g c h       ;; g c h = index list value
    ]
  ]
  report c                           ;; report a full list with how many of each resource have been scheduled to be sent.
  
  
end

to-report potential_partners [a_plant]
  
  ;; deal with trust transitive
  let potential_partner []
  
  ask a_plant
  [
    ifelse ((count my-in-partnerships + count my-out-partnerships) > 0)
    [

      set my_current_partner (turtle-set in-partnership-neighbors out-partnership-neighbors)
      let in_neighbors    ( [in-partnership-neighbors] of my_current_partner   with [behaviour = 1])
      let out_neighbors   ( [out-partnership-neighbors] of my_current_partner  with [behaviour = 1])
      
      ;set mat_received_from in_neighbors 
     ; set mat_received_fromName [name] of in_neighbors 
     ; set mat_sent_to out_neighbors
    ;  set mat_sent_toName [name] of out_neighbors 
      
      
      
      set out_partners_memory [name] of out-partnership-neighbors
      set in_partners_memory [name] of in-partnership-neighbors
      
      let pp_check_list1  (turtle-set my_current_partner in_neighbors out_neighbors)
      
      let pp_check_list []
      foreach sort pp_check_list1
      [
        set pp_check_list lput ? pp_check_list
      ]
      set pp_check_list   remove-duplicates pp_check_list ;; potential_partner
      set pp_check_list   remove self pp_check_list ;; potential_partner
      
      
      ifelse (not empty? pp_check_list)
      [
        set potential_partner (list_out_potential_partner pp_check_list self)
        
        if not empty? potential_partner [show "trust transitive: partner"]
        
        if empty? potential_partner
        [
          let all_other_list (list other plants with [behaviour = 1])
          set potential_partner (list_out_potential_partner all_other_list self)
          show "trust transitive: i have frd and frd of frd, they don't have what I needed"
        ]
      ]
      [
        let all_other_list (list other plants with [behaviour = 1])
        set potential_partner (list_out_potential_partner all_other_list self)
        show "trust transitive: i have no frd yet"
      ]
    ]
    [
      let all_other_list (list other plants with [behaviour = 1])
      set potential_partner (list_out_potential_partner all_other_list self)
      show "trust transitive: i have no frd yet"
    ]
  ]
  
  report potential_partner
  set my_potential_partners [name] of potential_partner
end


to-report list_out_potential_partner [a_list plant_need]
  let a_list2 turtle-set a_list
  
  let pp_list []
  let wanted_list needed_name_list plant_need
  
  foreach sort a_list2
  [
    let i_have_list left_name_list ?
    
    let x_list filter [member? ? wanted_list] i_have_list
    if not empty? x_list
    [
      set pp_list lput ? pp_list
    ]
  ] 
  
  report pp_list
  ;;
end

to-report resource_flow [plant_origin plant_destination]
  let thing ""
  let flow  0
  let thing_left left_name_list   plant_origin
  let thing_need needed_name_list plant_destination
  let capacity_left remove 0 (left_resource_list    plant_origin)
  let capacity_need remove 0 (needed_resources_list plant_destination)
 
  
  let thing_in_both_list []
  let temp 0
  while [temp < length thing_need]
  [
    let a (item temp thing_need)
    if member? a thing_left
    [
      let b item temp capacity_need
      let p position a thing_left
      let c item p capacity_left
      let f min (list b c)
      let d (list a f)                                ;;; thing (type), flow
      set thing_in_both_list lput d thing_in_both_list
    ]
    set temp temp + 1
  ]
  
  let flow_list []  
  
  foreach thing_in_both_list
  [
    let x item 1 ?
    set flow_list lput x flow_list
  ]
  
  let max_flow_possible max flow_list
  let target_thing position max_flow_possible flow_list
  
  let z item target_thing thing_in_both_list
  show z
  report z    ;;; thing (type), flow
end

to find_new_partner
  
  if (cooperation)
  [
    let pp potential_partners self      ;; a list
    let p2 turtle-set pp                ;; transform a list into an agentset
    
    ifelse (count p2 > 0) 
      [
        set one-partner one-of p2
        
        let rf resource_flow one-partner self  ;; origin --> destination
 
        create-partnership-from one-partner
        [
          if hide-part? [set hidden? true]
          set new-partner? true
          set resource_type     item 0 rf
          set resource_capacity item 1 rf
          
          set ownerFrom [name] of end1
          set ownerTo [name] of end2
           
          set ownerFromTurt end1
          set ownerToTurt end2
         
          set Comingto end2
          set ComningFrom end1
        ]            
         set my_partner one-partner
         set my_partnerName [name] of one-partner
 
         set mat_received  item 0 rf
         set mat_qty_received item 1 rf
        
         set mat_received_from my_partner
         set mat_received_fromName [name] of my_partner
         
         set flows_qty lput partnerships flows_qty
        
         ask my_partner [ 
          set mat_sent item 0 rf     
          set mat_qty_sent item 1 rf
          set mat_sent_to Comingto
          set mat_sent_toName [name] of  Comingto
                       ]
  
  ]
      [
        find_no_partner
      ]
  ]
  
end



to find_no_partner
  
  ask plants with [behaviour = 1]
  [
    if (count my-in-partnerships + count my-out-partnerships) = 0
    [
      set behaviour 0
      set color brown
    ]
  ]
  
end


;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;                                           find path                                               ;



to find-path
  nw:set-snapshot nodes paths
  ask partnerships with [new-partner? = true]
  [
    let a []
    let b []
    
    let junction1 [plocation] of end1
    let junction2 [plocation] of end2
    
    let d junction2
    ask junction1
    [
      
      set a   nw:path-to            d
      set b   nw:turtles-on-path-to d
    ]
  
    set route-list      a
    set route-node-list b
  ]
  
  
  ask partnerships with [new-partner? = true]
  [
    foreach route-list
    [ask ? [set color yellow
        set dist link-length
         ]
    set mydistance sum [dist] of paths
    show mydistance
    set mydistance_km mydistance * 3
    
    ]
        ]
  
  hatch-truck
end


;;; Path length computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to hatch-truck
  
  ask partnerships with [new-partner? = true]
  [    
    let m-list route-node-list
    
    ask end1
    [
      hatch-trucks 1
      [
        set size (truck-meters * 4000) / meters-per-patch
        set color green
        set move-list  m-list
        
        set done? false
        set move-index 0
        
        if hide-truck? [set hidden? true]
      ]
    ]
    
    set new-partner? false
  ]
end

to TRANSPORT
  
  moving
  
  if go-back? = true
  [ goback_command ]
end

to moving
  while [any? trucks with [done? = false]]
  [
    ask trucks with [done? = false]
    [
      ifelse (move-index) >= (length move-list)
      [
        set done? true
      ]
      [
        move-truck
      ]
    ]
  ]
  
  if all? trucks [done? = true]
    [
      ask trucks
      [
        set move-index 0
        set done? false
      ]
      show (word "plant 1 count: " count plants with [behaviour = 1])
      show (word "trucks count: "count trucks)
      show (word "partnerships count: "count partnerships)
    ]
end



to goback_command  
  ask trucks
    [
      set move-list reverse move-list
    ]
    
  moving  
  ask trucks
    [
      set move-list reverse move-list
    ]
end


to move-truck
  let x (item move-index move-list)
  face x
  fd (distance x)
  set move-index (move-index + 1)
end


;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;                                         behaviour change                                          ;

to learn                                                    ;;;;;imitate most frequent behavior with turtles in radius 5
  if learn? 
  [
    ask plants with [behaviour = 0]
    [
      let a count other plants in-radius influence_radius with [behaviour = 1]
      let b count other plants in-radius influence_radius with [behaviour = 0]
      if (a + b) > 0
      [
        if (random-float ( a / (a + b) )) > (random-float b / (a + b))  ;; count a > count b
        [
          set behaviour 1
        ]
      ]
    ]
  ]
  
  check-behaviour-now
end

to check-behaviour-now
  
  ask plants
  [
    if behaviour = 1
    [set color blue]
    
    if behaviour = 0
    [set color brown]
  ]
end




;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;                                          GHG calculation                                          ;

to emit_GHG
  ask plants [
    set GHG_partnered MMT_Co2 * 1.01
    set GHG_nonpartnered MMT_Co2 * 1.8
  ]
    
end



to carbon_tax ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;the contribution of C02 in GHG is considered to be 99%. water vapor is ignored. therefore GHG=Co2 
  ask plants [
    set behaviour0_tax GHG_partnered + 0 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; amount of carbon tax non-partnered plants have to pay
    set behaviour1_tax GHG_nonpartnered + 0 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; amount of carbon tax partnered plants have to pay
    ifelse (behaviour = 0) 
    [set behaviour0_tax (behaviour0_tax * carbon_tax_price)] 
    [set behaviour1_tax (behaviour1_tax * carbon_tax_price)]
  ]
end


to check_influence_carbon-policy           ;;;;;;;;;;;;;;;;;;;;;;;;;;plants managers can also change their behaviour from non-partnered to partnered through the incentive (influence) 
  ask plants [                           ;;;;;;;;;;;;;;;;;;;;;;;;; of the carbon tax. if the plant is non-partnerd and has a majority of neighboring plants that are partnered and
                                         ;;;;;;;;;;;;;;;;;;;;;;;;;; pay a certain percentage less (influence_threshold) tax, then imitate their behaviour and become partnered.
    if count plants with [behaviour1_tax = [behaviour1_tax * Influence_threshold] of myself] in-radius influence_radius > count factories with [behaviour = 0]
      [set behaviour 1]
  ]
end




;;;;;;;;;;;REPORTERS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to clear-all-but-globals ct cp cd clear-links clear-all-plots clear-output end

to-report meters-per-patch ;; maybe should be in gis: extension?
  let world gis:world-envelope ; [ minimum-x maximum-x minimum-y maximum-y ]
  let x-meters-per-patch (item 1 world - item 0 world) / (max-pxcor - min-pxcor) * 2.59
  let y-meters-per-patch (item 3 world - item 2 world) / (max-pycor - min-pycor) * 2.59
  report mean list x-meters-per-patch y-meters-per-patch
end

to-report new-node-at [x y] ; returns a node at x,y creating one if there isn't one there.
  let n nodes with [xcor = x and ycor = y]
  ifelse any? n 
  [set n one-of n] 
  [
    create-nodes 1 
    [
      setxy x y 
      set size 0.01 
      set n self]
  ]
  report n
end

to-report total_Partnered
 report count plants with [behaviour = 1]
end

to-report total_NonPartnered
 report count plants with [behaviour = 0]
end



to-report total_qty_receiced
  report sum [mat_qty_received] of plants
end 

to-report total_qty_sent
  report sum [mat_qty_sent] of plants
end 


to-report total_qty
  report precision (total_qty_receiced + total_qty_sent) 0
end 
  
to-report Mean_trust
  report mean [trust] of plants
end

to-report Mean_doubt
  report mean [doubt] of plants
end

to-report Mean_Involvment
  report mean [involvment] of plants
end


to-report GHG_savings
  report sum [Total_GHG_nonpartnered - Total_GHG_partnered] of patches
end


to-report Tax_savings
  report sum [behaviour0_tax - behaviour1_tax] of patches
end


to-report Total_behaviour1_tax
 report sum [behaviour1_tax] of plants
end 

to-report Total_behaviour0_tax
report sum [behaviour0_tax] of plants
end 

to-report Mean_behaviour1_tax
report mean [behaviour1_tax] of plants
end 

to-report Mean_behaviour0_tax
report mean [behaviour0_tax] of plants
end 



to-report co2_transport
  report precision (co2_pertonne_mile + (total_qty * co2_pertonne_mile * mydistance_km)) 0
end

to-report Co2_transportOutside
  report precision (co2_pertonne_mile + (total_qty  * co2_pertonne_mile * (mydistance_km * random 4))) 0
  end

to-report Co2_Trans_savings
  report precision (Co2_transportOutside - co2_transport) 0
end

to-report Total_GHG_partnered
 report sum [GHG_partnered] of plants with [behaviour = 1]
end 

to-report Total_GHG_nonpartnered
report  sum [GHG_nonpartnered] of plants with [behaviour = 0]
end 


;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;;;;==============================================================================================;;;
;                                         Turtles log for individual analysis with output file                                      ;


to export-data
 set-current-directory "Q:\\CSS\\css-shared\\Najet\\BSsymbiosis"
;; create the column headings once
if ticks = 0 [create-files]
export-files
end

to create-files
;; create the file and give the first row column headings
let spacer ","
file-open "Sample OutputBS5.csv"
file-print  (list 
  "BSRunNumber" spacer
  "ticks" spacer 
  "who" spacer 
  "Object_id" spacer
  "plocation" spacer 
  "name" spacer 
  
  "plant_type" spacer 
  "Type_Capacity" spacer

  "trust" spacer
  "doubt" spacer 
  "involvment" spacer 
  "cooperation" spacer 
  "behaviour"  spacer 
  
  
   "my_potential_partners"spacer

  "my_current_partner"spacer
  "my_partner"spacer
  "myresource_capacity"spacer

  
   "mat_received" spacer
   "mat_qty_received" spacer
   "mat_received_from" spacer
   "mat_received_fromName" spacer

   "mat_sent" spacer      
   "mat_qty_sent" spacer
    "mat_sent_to" spacer
    "mat_sent_toName" spacer
  
   "in_partners_memory" spacer 
  "out_partners_memory" spacer 
  
  
   "GHG_partnered" spacer 
   "GHG_nonpartnered" spacer 
   "behaviour0_tax" spacer 
   "behaviour1_tax" spacer)
 
file-close
end

to export-files
;; write the information to the file
let spacer ","
file-open "Sample OutputBS5.csv"
ask plants [file-print
  
 (list behaviorspace-run-number spacer
  ticks spacer 
 who spacer 
  Object_id spacer
  plocation spacer 
  name spacer 
  
  plant_type spacer 
  Type_Capacity spacer

  trust spacer
  doubt spacer 
  involvment spacer 
  cooperation spacer 
  behaviour  spacer 
  
  
   my_potential_partners spacer

  my_current_partner spacer
  my_partner spacer
  myresource_capacity spacer

  
   mat_received spacer
   mat_qty_received spacer
   mat_received_from spacer
   mat_received_fromName spacer

   mat_sent spacer      
   mat_qty_sent spacer
   mat_sent_to  spacer
   mat_sent_toName spacer
  
   in_partners_memory spacer 
  out_partners_memory spacer 
  
  
   GHG_partnered spacer 
   GHG_nonpartnered spacer 
   behaviour0_tax spacer 
   behaviour1_tax spacer)
   
   
   ] 
file-close
end 







;;;####################################
@#$#@#$#@
GRAPHICS-WINDOW
213
10
652
470
16
16
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
-2
10
106
43
zoom
zoom
0.1
1
1
0.01
1
NIL
HORIZONTAL

BUTTON
26
73
92
107
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
-3
187
213
220
involvement_threshold_index
involvement_threshold_index
0
5
1
1
1
NIL
HORIZONTAL

SLIDER
-5
155
213
188
cultural_cooperation_prob
cultural_cooperation_prob
0
1
0.8
.1
1
NIL
HORIZONTAL

MONITOR
981
279
1176
324
NIL
count partnerships
17
1
11

PLOT
651
229
976
446
Exchanges
ticks
exch
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"B1" 1.0 0 -16777216 true "" "plot count factories with [behaviour = 1]"
"B0" 1.0 0 -7500403 true "" "plot count factories with [behaviour = 0]"

PLOT
654
10
971
224
GHG Emissions Evolution
ticks
GHG tons
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"GHG1" 1.0 0 -13210332 true "" "plot sum [GHG_partnered] of factories with [behaviour = 1]"
"GHG0" 1.0 0 -3844592 true "" "plot sum [GHG_partnered] of factories with [behaviour = 0]"
"Co2_transp" 1.0 0 -7500403 true "" "plot Co2_transport"
"Co2_transpOut" 1.0 0 -14350824 true "" "plot Co2_transportOutside"

MONITOR
981
231
1175
276
NIL
count factories
0
1
11

SWITCH
107
10
197
43
Learn?
Learn?
0
1
-1000

SLIDER
-4
254
211
287
influence_radius
influence_radius
0
4
4
1
1
NIL
HORIZONTAL

SWITCH
-2
220
110
253
carbon_tax?
carbon_tax?
0
1
-1000

SLIDER
32
436
213
469
carbon_tax_price
carbon_tax_price
20
150
50
10
1
Euros
HORIZONTAL

SLIDER
137
469
309
502
Influence_threshold
Influence_threshold
0.1
1
0.2
0.1
1
NIL
HORIZONTAL

PLOT
972
10
1285
224
Carbon tax
ticks
Euros
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Partnered" 1.0 0 -11783835 true "" "plot sum [behaviour1_tax] of plants"
"Non partnered" 1.0 0 -7500403 true "" "plot sum [behaviour0_tax] of plants"

BUTTON
25
42
92
75
NIL
SETUP
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
109
220
211
253
check_influence_policy?
check_influence_policy?
0
1
-1000

MONITOR
1191
233
1272
278
NIL
count nodes
0
1
11

SLIDER
652
446
824
479
max-speed-km/h
max-speed-km/h
5
80
5
80
1
NIL
HORIZONTAL

MONITOR
1189
280
1272
325
Meters/patch
precision meters-per-patch 2
0
1
11

SLIDER
823
445
995
478
speed-variation
speed-variation
0
1
0.2
.1
1
NIL
HORIZONTAL

SLIDER
995
444
1167
477
truck-meters
truck-meters
3
10
4
1
1
NIL
HORIZONTAL

SWITCH
93
340
214
373
hide-part?
hide-part?
1
1
-1000

SWITCH
93
371
213
404
hide-truck?
hide-truck?
1
1
-1000

SWITCH
93
403
212
436
hide-path?
hide-path?
1
1
-1000

SWITCH
32
469
138
502
Go-back?
Go-back?
0
1
-1000

MONITOR
980
326
1271
371
NIL
sum [co2_transport] of partnerships
17
1
11

MONITOR
980
372
1271
417
NIL
sum [co2_transportOutside] of partnerships
17
1
11

MONITOR
97
58
210
103
NIL
total_qty
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment0" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count plants</metric>
    <metric>count partnerships</metric>
    <metric>count plants with  [GHG_partnered]</metric>
    <metric>count plants with  [GHG_nonpartnered]</metric>
    <metric>count plants with [behaviour0_tax]</metric>
    <metric>count plants with [behaviour1_tax]</metric>
    <metric>total_qty</metric>
    <metric>co2_transport</metric>
    <metric>Co2_transportOutside</metric>
    <metric>count plants with [behaviour = 0]</metric>
    <metric>count plants with [behaviour = 1]</metric>
    <enumeratedValueSet variable="carbon_tax_price">
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural_cooperation_prob">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Influence_threshold">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check_influence_policy?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carbon_tax?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Learn?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="involvement_threshold_index">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence_radius">
      <value value="1"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment1testbs" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count plants</metric>
    <metric>total_Partnered</metric>
    <metric>total_NonPartnered</metric>
    <metric>Mean_trust</metric>
    <metric>Mean_doubt</metric>
    <metric>Mean_Involvment</metric>
    <metric>count partnerships</metric>
    <metric>total_qty</metric>
    <metric>Total_behaviour1_tax</metric>
    <metric>Total_behaviour0_tax</metric>
    <metric>Mean_behaviour1_tax</metric>
    <metric>Mean_behaviour0_tax</metric>
    <metric>Total_GHG_partnered</metric>
    <metric>Total_GHG_nonpartnered</metric>
    <metric>GHG_savings</metric>
    <metric>co2_transport</metric>
    <metric>Co2_transportOutside</metric>
    <metric>Co2_Trans_savings</metric>
    <enumeratedValueSet variable="carbon_tax_price">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural_cooperation_prob">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Influence_threshold">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check_influence_policy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carbon_tax?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Learn?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="involvement_threshold_index">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence_radius">
      <value value="1"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count plants</metric>
    <metric>count partnerships</metric>
    <metric>count plants with  [GHG_partnered]</metric>
    <metric>count plants with  [GHG_nonpartnered]</metric>
    <metric>count plants with [behaviour0_tax]</metric>
    <metric>count plants with [behaviour1_tax]</metric>
    <metric>total_qty</metric>
    <metric>co2_transport</metric>
    <metric>Co2_transportOutside</metric>
    <metric>count plants with [behaviour = 0]</metric>
    <metric>count plants with [behaviour = 1]</metric>
    <enumeratedValueSet variable="carbon_tax_price">
      <value value="50"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural_cooperation_prob">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Influence_threshold">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check_influence_policy?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carbon_tax?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Learn?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="involvement_threshold_index">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence_radius">
      <value value="1"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2-10runs" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count plants</metric>
    <metric>total_Partnered</metric>
    <metric>total_NonPartnered</metric>
    <metric>Mean_trust</metric>
    <metric>Mean_doubt</metric>
    <metric>Mean_Involvment</metric>
    <metric>count partnerships</metric>
    <metric>total_qty</metric>
    <metric>Total_behaviour1_tax</metric>
    <metric>Total_behaviour0_tax</metric>
    <metric>Mean_behaviour1_tax</metric>
    <metric>Mean_behaviour0_tax</metric>
    <metric>Total_GHG_partnered</metric>
    <metric>Total_GHG_nonpartnered</metric>
    <metric>GHG_savings</metric>
    <metric>co2_transport</metric>
    <metric>Co2_transportOutside</metric>
    <metric>Co2_Trans_savings</metric>
    <enumeratedValueSet variable="carbon_tax_price">
      <value value="50"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural_cooperation_prob">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Influence_threshold">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check_influence_policy?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carbon_tax?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Learn?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="involvement_threshold_index">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence_radius">
      <value value="1"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment3" repetitions="2" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count plants</metric>
    <metric>count partnerships</metric>
    <metric>count plants with  [GHG_partnered]</metric>
    <metric>count plants with  [GHG_nonpartnered]</metric>
    <metric>count plants with [behaviour0_tax]</metric>
    <metric>count plants with [behaviour1_tax]</metric>
    <metric>total_qty</metric>
    <metric>co2_transport</metric>
    <metric>Co2_transportOutside</metric>
    <metric>count plants with [behaviour = 0]</metric>
    <metric>count plants with [behaviour = 1]</metric>
    <enumeratedValueSet variable="carbon_tax_price">
      <value value="50"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural_cooperation_prob">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Influence_threshold">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check_influence_policy?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carbon_tax?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Learn?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="involvement_threshold_index">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence_radius">
      <value value="1"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment1testbs2" repetitions="2" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count plants</metric>
    <metric>total_Partnered</metric>
    <metric>total_NonPartnered</metric>
    <metric>Mean_trust</metric>
    <metric>Mean_doubt</metric>
    <metric>Mean_Involvment</metric>
    <metric>count partnerships</metric>
    <metric>total_qty</metric>
    <metric>Total_behaviour1_tax</metric>
    <metric>Total_behaviour0_tax</metric>
    <metric>Mean_behaviour1_tax</metric>
    <metric>Mean_behaviour0_tax</metric>
    <metric>Total_GHG_partnered</metric>
    <metric>Total_GHG_nonpartnered</metric>
    <metric>GHG_savings</metric>
    <metric>co2_transport</metric>
    <metric>Co2_transportOutside</metric>
    <metric>Co2_Trans_savings</metric>
    <enumeratedValueSet variable="carbon_tax_price">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cultural_cooperation_prob">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Influence_threshold">
      <value value="0.2"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="check_influence_policy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carbon_tax?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Learn?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="involvement_threshold_index">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence_radius">
      <value value="1"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
