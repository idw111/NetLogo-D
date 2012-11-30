
globals
[
  ; is-finish
  curr-change
  prev-change
  equilibrium-count
  
  ; find-cluster
  clusters
  number-of-clusters
  number-of-current-cluster
  number-of-largest-cluster
  number-of-isolations
  
  best-link-so-far
  best-clustering-coeff
  best-count
  
  hhi-list
  
  max-bound
]

links-own
[
  level
]

turtles-own
[
  context           ; "online" or "offline"
  opinion           ; [0, 1]
  uncertainty-level ; opinion in [x - u, x + u] get adjusted
  adjusting-coefficient
  parent

  level             ; 1, 2, ..., depth (current depth on which the agent is located)
  lbound            ; lbound and ubound is used to give stronger power to upper levels (probability)
  ubound
  
  ; find-cluster
  cluster
  temp  
]

to go-for-evolution
  repeat 100 [ step-for-evolution ]
  
  if best-count >= 999 [
    create-evoutionary-link
  ]
  tick
end

to create-evoutionary-link
  if length best-link-so-far = 2 [
    let src item 0 best-link-so-far 
    let dst item 1 best-link-so-far 
    ask src [ 
      create-link-with dst [
        set level 1 + max [level] of links 
        set color 8
      ]
    ]
  ]
  set best-link-so-far (list)
  set best-count 0
end

to step-for-evolution
  ; 1. create a random link
  ask turtles [ set temp 0 ]
  let src one-of turtles
  let dst nobody
  ask src [
    set temp 1
    ask link-neighbors [ set temp 1 ]
    set dst one-of turtles with [temp = 0]
    create-link-with dst [ 
      set level 1 + max [level] of links 
      set color 8
    ]
  ]
  let clustering-coeff network_culstering_coefficient
  if clustering-coeff > best-clustering-coeff
  [
    set best-link-so-far sentence src dst
    set best-clustering-coeff clustering-coeff
    show best-clustering-coeff
  ]
  ask links with [level = max [level] of links] [ die ]
  ;show best-count
  set best-count best-count + 1
end

to go
  repeat 1000 [ interact ]
  tick
  if plot-opinions 
  [ 
    update-plot
  ]

  if (is-finish) 
  [
    stop
  ]
end

to step
  interact
end

to-report geometricSeries [subordinates depth]
  let value 0
  let i 0
  while [i < depth] [
    set value value + subordinates ^ i
    set i i + 1
  ]
  report value
end

to setup-tree-network [subordinates depth]
  clear-turtles
  set hhi-list (list)
  set max-bound 0
  set population (geometricSeries subordinates depth)
  set-default-shape turtles "circle"
  
  crt population [
    set opinion (random-float 1.0)
    set level depth
    set cluster 0
    set uncertainty-level initial_uncertainty_level
    set adjusting-coefficient initial_adjusting_coeff
    ;setxy (min-pxcor + world-width / 2) (min-pycor + opinion * world-height)
    setxy (min-pxcor + random world-width) min-pycor + 1
    
    set context "online"
    set color number_of_depth * 10 + 5
    set size 0.5
  ]
  
  ;show turtles with [count link-neighbors = 0]
  
  let i 1
  let seed n-of 1 turtles
  ask seed [ set parent self ]
  while [i < depth] [
    ;show seed
    ask seed [
      if count seed > 1 [
        create-links-with other seed with [parent = [parent] of myself]
      ]
      create-links-with n-of subordinates (other turtles with [count link-neighbors = 0])
      set level i
      set color level * 10 + 5
      ;setxy (min-pxcor + opinion * world-width) (13 - (level - 1) * 5)
      setxy (min-pxcor + opinion * world-width) max-pycor - 1 - ((world-height - 3) / (number_of_depth - 1)) * (level - 1)
    ]
    set seed turtles with [count link-neighbors = 1]
    ask seed [ set parent one-of link-neighbors ]
    
    ;show seed
    set i i + 1
  ]
  set seed turtles with [count link-neighbors = 1]
  ask seed [ set parent one-of link-neighbors ]
  ask seed [ create-links-with other seed with [parent = [parent] of myself] ]
  ;repeat 30 [ layout-spring turtles links 0.2 5 1 ]
  
  set max-bound 0
  ask turtles
  [
    set lbound max-bound
    set max-bound (max-bound + subordinates ^ (depth - level))
    set ubound max-bound
  ]
  
  ask links [ 
    set level 0 
    set color 2
  ]

  ;inspect one-of turtles with [level = 1]  
end

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  
  setup-tree-network span_of_control number_of_depth
end

to-report is-finish
  report (ticks > 1000)
end

to-report is-finish1
  let change curr-change - prev-change
  ifelse (change <= 0) 
  [
    set equilibrium-count equilibrium-count + 1
    show equilibrium-count 
  ]
  [
    set equilibrium-count 0
  ]
  set prev-change curr-change
  
  report (equilibrium-count >= 10 or ticks >= 1000)
end

;--------------------------------------------------------------------------
;
;  define initial context
;
;--------------------------------------------------------------------------

to setup-initial-value
  set equilibrium-count 0
  set curr-change 0
  set prev-change 0
  
  set-default-shape turtles "circle"
  crt population [
    set opinion (random-float 1.0)
    set cluster 0
    set uncertainty-level initial_uncertainty_level
    set adjusting-coefficient initial_adjusting_coeff
    setxy (min-pxcor + world-width / 2) (min-pycor + opinion * world-height)
    
    set context "offline"
    set color 55
    set size 0.24
  ]
  
  if (connectedness > 0) 
  [
    ask n-of floor(connectedness * population) turtles 
    [
      set context "online"
      set color 14
    ]
  ]
end

;--------------------------------------------------------------------------
;
;  find cluster
;
;--------------------------------------------------------------------------

to find-clusters
  set clusters (list)
  set number-of-clusters 0
  set number-of-current-cluster 0
  set number-of-largest-cluster 0
  set number-of-isolations 0
  ask turtles [ set cluster nobody ]
  
  let seed min-one-of (turtles with [cluster = nobody]) [level]
  
  while [seed != nobody] [
    ask seed [
      set cluster self
      set number-of-clusters number-of-clusters + 1
      set number-of-current-cluster 1
      infect-cluster
    ]
    if number-of-current-cluster > number-of-largest-cluster [ set number-of-largest-cluster number-of-current-cluster ]
    if number-of-current-cluster = 1 [ set number-of-isolations number-of-isolations + 1 ]
    set clusters fput (sentence number-of-current-cluster (mean [opinion] of turtles with [cluster = [cluster] of seed])) clusters
    set seed min-one-of (turtles with [cluster = nobody]) [level]
  ]
  
  set clusters sort-by [item 0 ?1 > item 0 ?2] clusters
  show clusters
end

to infect-cluster
  ;ask turtles with [cluster = nobody and ((parent = [parent] of myself) or (parent = myself)) and (opinion-distance self myself) < uncertainty-level]
  ask link-neighbors with [cluster = nobody and (opinion-distance self myself) < uncertainty-level]
  [
    if cluster = nobody
    [
      set number-of-current-cluster number-of-current-cluster + 1
      set cluster [cluster] of myself
      infect-cluster
    ]
  ]
end

;--------------------------------------------------------------------------
;
;  interaction between communicator and communicatee
;
;--------------------------------------------------------------------------

to interact
  let src one-of turtles
  
  if network_structure = "hierachy"
  [
    ifelse ([level] of src > 1)
    [
      ifelse random-float ((count [link-neighbors] of src - 1) * peer_communication + 1) < 1
      [
        ask src [ influence-offline self parent ]
      ]
      [
        ask src [ influence-offline self one-of link-neighbors with [level >= [level] of myself] ]
      ]
    ]
    [
      ask src [ influence-offline self one-of link-neighbors ]
    ]
  ]
  
  if network_structure = "complete"
  [
    ask src [ influence-offline self one-of other turtles ]
  ]
end

; one way multiple influence
; agents with online context can interact online
; exclude agents without onlnie access

to influence-online [src dst] 
  if ([context] of dst = "offline") 
  [
    stop
  ]
  
  let src-opinion [opinion] of src
  let dst-opinion [opinion] of dst
  ;let opinion-distance abs (src-opinion - dst-opinion)
  let d (opinion-distance src dst)
  
  if (d <= 0.0001) 
  [
    stop
  ]
  
  ask dst [
    if (d < uncertainty-level) [
      set curr-change curr-change + 1
      set opinion (dst-opinion + (src-opinion - dst-opinion) * adjusting-coefficient)
    ]
  ]
end

; two way influence
; all agents can interact offline

to influence-offline [src dst]
  let src-opinion [opinion] of src
  let dst-opinion [opinion] of dst
  let d (opinion-distance src dst)
  
  ; if power > 0, src is subordinate of dst
  ; if power < 0, src is supervisor of dst
  ; if power = 0, they are peers
  let power [level] of src - [level] of dst 
    
  ask src [
    if (d < uncertainty-level) [
      ;set curr-change curr-change + 1
      
      set opinion src-opinion + (dst-opinion - src-opinion) * adjusting-coefficient * (ifelse-value (power > 0) [ influential_power_of_supervisor ] [ 1 ])
    ]
  ]
  
  ask dst [
    if (d < uncertainty-level) [
      ;set curr-change curr-change + 1
      set opinion dst-opinion + (src-opinion - dst-opinion) * adjusting-coefficient * (ifelse-value (power < 0) [ influential_power_of_supervisor ] [ 1 ])
    ]
  ]
end

to-report opinion-distance [src dst]
  report abs ([opinion] of src - [opinion] of dst)
end

;--------------------------------------------------------------------------
;
;  reporter
;
;--------------------------------------------------------------------------

to-report final_clusters
  find-clusters
  report clusters
end

to-report number_of_isolations
  report number-of-isolations
end

to-report number_of_clusters
  report length clusters
end

to-report number_of_largest_cluster
  report item 0 (item 0 clusters)
end

to-report number_of_second_largest_cluster
  ifelse length clusters <= 1
  [
    report 0
  ]
  [
    report item 0 (item 1 clusters)
  ]
end

to-report misaligned_with_top
  let value 0
  let top one-of turtles with [level = 1]
  ask turtles [
    if level > 1
    [
      ;let top-opinion [opinion] of top
      ;let opinion-distance abs (opinion - top-opinion)    
      let d (opinion-distance self top)
      
      if (d > uncertainty-level) [
        set value value  + 1
      ]
    ]
  ]
  report value / population
end

to-report misaligned_with_super
  let value 0
  ask turtles with [level > 1] 
  [
    let super one-of link-neighbors with [level = ([level] of myself - 1)]
    ;let super-opinion [opinion] of super
    ;let opinion-distance abs (opinion - super-opinion)    
    let d (opinion-distance self super)
    
    if (d > uncertainty-level) [
      set value value  + 1
    ]
  ]
  report value / population
end

to-report misaligned_with_top_and_super
  let value 0
  let top one-of turtles with [level = 1]
  let top-opinion [opinion] of top
  ask turtles with [level > 1] 
  [
    let super one-of link-neighbors with [level = ([level] of myself - 1)]
    ;let super-opinion [opinion] of super
    ;let super-opinion-distance abs (opinion - super-opinion)    
    ;let top-opinion-distance abs (opinion - top-opinion)    
    let super-opinion-distance (opinion-distance self super)
    let top-opinion-distance (opinion-distance self top)
    
    if (super-opinion-distance > uncertainty-level and top-opinion-distance > uncertainty-level) [
      set value value  + 1
    ]
  ]
  report value / population
end

to-report misaligned_with_top_or_super
  let value 0
  let top one-of turtles with [level = 1]
  let top-opinion [opinion] of top
  ask turtles with [level > 1] 
  [
    let super one-of link-neighbors with [level = ([level] of myself - 1)]
    ;let super-opinion [opinion] of super
    ;let super-opinion-distance abs (opinion - super-opinion)    
    ;let top-opinion-distance abs (opinion - top-opinion)    
    let super-opinion-distance (opinion-distance self super)
    let top-opinion-distance (opinion-distance self top)
    
    if (super-opinion-distance > uncertainty-level or top-opinion-distance > uncertainty-level) [
      set value value  + 1
    ]
  ]
  report value / population
end

to-report hhi
  let value 0
  foreach clusters 
  [
    set value value + (item 0 ? / population) ^ 2
  ]
  report value
end

;to-report entropy
;end

to-report network_density
  report 2 * count links / (population * (population - 1))
end

to-report nework_average_degree
  let value 0
  ask turtles [
    set value value + count link-neighbors
  ]
  report value / population
end

to-report network_culstering_coefficient
  ifelse all? turtles [count link-neighbors <= 1]
  [
    report 0
  ]
  [
    let total 0
    ask turtles with [ count link-neighbors <= 1 ]
    [ 
      set temp "undefined" 
    ]
    ask turtles with [ count link-neighbors > 1 ]
    [
      let hood link-neighbors
      set temp (2 * count links with [ in-neighborhood? hood ] / ((count hood) * (count hood - 1)))
      ;; find the sum for the value at turtles
      set total total + temp
    ]
    report total / count turtles with [count link-neighbors > 1]
  ]
end

to-report in-neighborhood? [ agents ]
  report (member? end1 agents and member? end2 agents)
end

to network_characteristics
  show sentence "density" network_density
  show sentence "average degree" nework_average_degree
  show sentence "clustering coeff" network_culstering_coefficient
end

;--------------------------------------------------------------------------
;
;  plot
;
;--------------------------------------------------------------------------

to update-plot
  set-current-plot "opinions"
  set-current-plot-pen "opinion"
  ask turtles with [context = "offline"]
  [
    set-current-plot-pen context
    plotxy ticks opinion
    ;setxy (min-pxcor + world-width / 2) (min-pycor + opinion * world-height)
    setxy (min-pxcor + opinion * world-width) ycor
  ]
  ask turtles with [context = "online"]
  [
    set-current-plot-pen context
    plotxy ticks opinion
    ;setxy (min-pxcor + world-width / 2) (min-pycor + opinion * world-height)
    setxy (min-pxcor + opinion * world-width) ycor
  ]
end


; Copyright 2008 Uri Wilensky. All rights reserved.
; The full copyright notice is in the Information tab.
@#$#@#$#@
GRAPHICS-WINDOW
256
10
767
542
16
16
15.2
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
9
10
127
43
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
135
10
253
43
go
go-for-evolution
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
8
368
253
401
population
population
10
10000
127
10
1
NIL
HORIZONTAL

PLOT
770
10
1243
542
opinions
NIL
NIL
0.0
1000.0
0.0
1.0
true
false
"" ""
PENS
"opinion" 1.0 2 -16777216 true "" ""
"online" 1.0 2 -2674135 true "" ""
"offline" 1.0 2 -10899396 true "" ""

SLIDER
9
89
253
122
initial_uncertainty_level
initial_uncertainty_level
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
9
124
253
157
initial_adjusting_coeff
initial_adjusting_coeff
0
0.5
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
9
159
253
192
connectedness
connectedness
0
1
0
0.05
1
NIL
HORIZONTAL

SWITCH
9
45
253
78
plot-opinions
plot-opinions
0
1
-1000

SLIDER
8
298
253
331
span_of_control
span_of_control
2
10
2
1
1
NIL
HORIZONTAL

SLIDER
8
333
253
366
number_of_depth
number_of_depth
2
10
7
1
1
NIL
HORIZONTAL

SLIDER
8
211
253
244
peer_communication
peer_communication
0
10
1
0.5
1
NIL
HORIZONTAL

SLIDER
8
246
253
279
influential_power_of_supervisor
influential_power_of_supervisor
0
10
1
0.5
1
NIL
HORIZONTAL

CHOOSER
12
421
151
466
network_structure
network_structure
"hierachy" "complete"
0

BUTTON
132
516
195
549
go
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

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="connectedness">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_uncertainty_level">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="communication_style">
      <value value="&quot;bottom-up&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_subordinates">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot-opinions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_adjusting_coeff">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_depth">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="127"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
