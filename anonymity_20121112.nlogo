globals
[
  proportion-of-change-in-belief
  temp-number-of-change-in-belief

  prev-n-of-change-in-belief
  prev-n-of-change-to-conviction
  prev-n-of-change-to-inconviction

  total-number-of-links
  total-number-of-opinion
  equilibrium-count
  equilibrium-ticks

  this-cluster
  max-cluster
  num-cluster
  num-single-cluster
  num-large-cluster

  total-number-of-agents
  total-number-of-information
]

turtles-own
[
  anonymous?

  lbound
  ubound

  opinion; subjective knowledge (convinced/unconvinced) + objective knowledge (true/false) = 0 1 2 3

  number-of-change-in-belief
  number-of-change-to-conviction ; unconvinced -> convinced
  number-of-change-to-inconviction ; convinced -> unconvinced

  cluster
]

to-report is-equilibrium?
  if ticks = 1000 [ report true ]

  let curr-n-of-change-in-belief total-number-of-change-in-belief
  let curr-n-of-change-to-conviction total-number-of-change-to-conviction
  let curr-n-of-change-to-inconviction total-number-of-change-to-inconviction
  let threshold 0.005
  let reset? true

  set temp-number-of-change-in-belief curr-n-of-change-in-belief - prev-n-of-change-in-belief
  ;set proportion-of-change-in-belief temp-number-of-change-in-belief / total-number-of-information
  set proportion-of-change-in-belief temp-number-of-change-in-belief / 1000

  if proportion-of-change-in-belief <= threshold [
    set equilibrium-count equilibrium-count + 1
    set reset? false
    show word "equilibrium-count " equilibrium-count
    if equilibrium-count >= 10 [ report true ]
  ]

  show curr-n-of-change-in-belief - prev-n-of-change-in-belief

  set prev-n-of-change-in-belief curr-n-of-change-in-belief
  set prev-n-of-change-to-conviction curr-n-of-change-to-conviction
  set prev-n-of-change-to-inconviction curr-n-of-change-to-inconviction

  if reset? [ set equilibrium-count 0 ]
  report false
end

to go
  repeat 1000 [ step ]

  if is-equilibrium? [
    set equilibrium-ticks ticks
    update-link-color
    find-clusters
    stop
  ]

  tick

  update-link-color
  update-node-color
  update-plot
end

to step
  interact
end

;to-report total-number-of-information
;  report sum [length opinion] of turtles
;end
;
;to-report total-number-of-agents
;  report count turtles
;end

to-report number-of-clusters
  report num-cluster
end

to-report number-of-single-clusters
  report num-single-cluster
end

to-report number-of-large-clusters
  report num-large-cluster
end

to-report number-of-max-cluster
  report max-cluster
end

to find-clusters
  set this-cluster 0
  set max-cluster 0
  set num-cluster 0
  set num-single-cluster 0
  set num-large-cluster 0

  ask turtles [ set cluster nobody ]

  let threshold-of-large-cluster 3
  let seed one-of turtles with [ cluster = nobody ]

  while [ seed != nobody ]
  [
    ask seed [
      set cluster self
      set this-cluster 1
      set num-cluster num-cluster + 1
      grow-cluster
    ]
    if this-cluster > max-cluster [ set max-cluster this-cluster ]
    if this-cluster >= threshold-of-large-cluster [ set num-large-cluster num-large-cluster + 1 ]
    if this-cluster = 1 [ set num-single-cluster num-single-cluster + 1 ]
    set seed one-of turtles with [ cluster = nobody ]
  ]
end

to grow-cluster
  ask link-neighbors with [(cluster = nobody) and ((agent-similarity-between myself self true) >= similarity-threshold)]
  [
    if cluster = nobody [ set this-cluster this-cluster + 1 ]
    set cluster [ cluster ] of myself
    grow-cluster
  ]
end

to setup
  __clear-all-and-reset-ticks

  set-default-shape turtles "dot"

  setup-initial-value

  if network-structure = "scalefree" [
    setup-scalefree-nodes
    setup-scalefree-network
  ]
  if network-structure = "random" [
    setup-random-nodes
    setup-random-network
  ]
  if network-structure = "lattice" [
    setup-lattice-nodes
    setup-lattice-network
  ]

  update-link-color
  update-node-color
  update-plot
end

to set-anonymity
  ask turtles [
    set anonymous? false
    set color 55
  ]
  ask n-of (floor (population * anonymity)) turtles [
    set anonymous? true
    set color 15
  ]
  update-link-color
  update-node-color
end

;--------------------------------------------------------------------------
;
;  define initial context
;
;--------------------------------------------------------------------------

to-report random-opinion1
  report n-values number-of-information [random 4]
end

to-report random-opinion
  let rlist (list)
  let i 0
  let value 0

  while [ i < number-of-information ] [
;    ifelse random-float 1.0 < initial-convinced ; convinced
;    [ set value ifelse-value (random-float 1.0 < initial-convinced-true) [ 3 ] [ 2 ] ] ; convinced - T: 80%, F: 20%
;    [ set value ifelse-value (random-float 1.0 < initial-unconvinced-true) [ 1 ] [ 0 ] ] ; unconvinced - T: 80%, F: 20%

    set rlist fput get-unit-information rlist
    set i i + 1
  ]
  report rlist
end

to setup-initial-value
  set total-number-of-agents population
  set total-number-of-information total-number-of-agents * number-of-information
  ;if average-connection >= total-number-of-agents [ set average-connection total-number-of-agents - 1 ]
end

to calculate-cumulative-number-of-links
  let cumulative-number-of-links 0
  ask turtles [
    set lbound cumulative-number-of-links
    set cumulative-number-of-links (cumulative-number-of-links + count my-links)
    set ubound cumulative-number-of-links
  ]
end

to update-information
  ask turtles [
    set opinion remove-item 0 opinion
    set opinion lput (get-unit-information) opinion
  ]
end

to-report get-unit-information
  let unit-information 0
  ifelse random 100 < initial-convinced
  [ set unit-information ifelse-value (random-float 1.0 < initial-convinced-true) [3] [2] ]
  [ set unit-information ifelse-value (random-float 1.0 < initial-unconvinced-true) [1] [0] ]
  report unit-information
end

;--------------------------------------------------------------------------
;
;  setup random network
;
;--------------------------------------------------------------------------

to setup-random-nodes
  set-default-shape turtles "dot"

  crt population [
    set anonymous? false
    set opinion random-opinion
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    set color 55
  ]
  ask n-of (floor (population * anonymity)) turtles [
    set anonymous? true
    set color 15
  ]
end

to setup-random-network
  let number-of-links (average-connection * total-number-of-agents) / 2
  while [ count links < number-of-links ]
  [
    ask one-of turtles [
      let choice (min-one-of (other turtles with [not link-neighbor? myself]) [distance myself])
      if choice != nobody [ create-link-with choice ]
    ]
  ]
  calculate-cumulative-number-of-links

  repeat 10 [ ; make the network look a little prettier
    layout-spring turtles links 0.2 (world-width / (sqrt total-number-of-agents)) 1
  ]
end

;--------------------------------------------------------------------------
;
;  setup lattice network
;
;--------------------------------------------------------------------------

to setup-lattice-nodes
  let unitWidth (world-width / (cols + 0))
  let unitHeight (world-height / (rows + 0))

  set population (cols * rows)

  crt population [
    set anonymous? false
    set opinion random-opinion
    setxy ((who mod cols) * unitWidth) (floor (who / cols) * unitHeight)
    set color 55
  ]
  ask n-of (floor (population * anonymity)) turtles [
    set anonymous? true
    set color 15
  ]
end

to setup-lattice-network
  set average-connection 4
  ask turtles [
    ifelse (who mod cols) = 0
    [ create-link-with turtle (who + cols - 1) ]
    [ create-link-with turtle (who - 1) ]
    ifelse floor (who / cols) = 0
    [ create-link-with turtle (who + (rows - 1) * cols) ]
    [ create-link-with turtle (who - cols) ]
  ]
  calculate-cumulative-number-of-links
end

;--------------------------------------------------------------------------
;
;  setup scalefree network
;
;--------------------------------------------------------------------------

to setup-scalefree-nodes
  set-default-shape turtles "dot"

  crt population [
    set anonymous? false
    set opinion random-opinion
    set color 55
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
  ]
  ask n-of (floor (population * anonymity)) turtles [
    set anonymous? true
    set color 15
  ]
end

to setup-scalefree-network
  set-number-of-links-so-far average-connection

  let i average-connection
  while [i < count turtles]
  [
    connect-to-scalefree-node (turtle i)
    set i (i + 1)
    set-number-of-links-so-far i
  ]
end

to connect-to-scalefree-node [source-node]
  let i 0
  while [ i < 2 ]
  [
    let cumulative-number-of-links sum [count link-neighbors] of turtles
    let ticket random cumulative-number-of-links
    let choice one-of (turtles with [ticket >= lbound and ticket < ubound])

    if choice != nobody and choice != source-node [
      ask source-node [
        if not (link-neighbor? choice) [
          create-link-with choice
          set i i + 1
        ]
      ]
    ]
  ]
  ;layout
end

to set-number-of-links-so-far [number-of-agent-so-far]
  let num-links 0
  let i 0
  while [ i < number-of-agent-so-far ]
  [
    let t turtle i
    ask t [
      set lbound num-links
      set num-links (num-links + count my-links + 1)
      set ubound num-links
    ]
    set i i + 1
  ]
  set total-number-of-links num-links
end

to layout
  repeat 3 [
    let factor 4 * sqrt count turtles with [lbound > 0]
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    ;display  ;; for smooth animation
  ]

  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles

  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles with [lbound > 0] [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end

to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end

;--------------------------------------------------------------------------
;
;  define interaction between communicator and communicatee
;
;--------------------------------------------------------------------------

to interact
;  let src one-of turtles
  let total sum [count link-neighbors] of turtles
  let ticket random total
  let src one-of turtles with [ticket >= lbound and ticket < ubound]

  if src != nobody [
    ask [link-neighbors] of src [
      interact-with src self
    ]
;    ask one-of [link-neighbors] of src [
;      interact-with src self
;    ]
  ]
end

to interact-with [communicator communicatee]
  let indices (list)

  if ([anonymous?] of communicator) [
    set indices n-values number-of-information [?] ; index list of convinced and unconvinced
;    let index 0
;    foreach ([opinion] of communicator) [
;      if ? = 0 or ? = 1 [ ; index list of unconvinced
;        set indices fput index indices
;        set index index + 1
;      ]
;    ]
  ]

  if (not [anonymous?] of communicator) or (length indices = 0) [
    let index 0
    foreach ([opinion] of communicator) [
      if ? = 2 or ? = 3 [ ; index list of convinced
        set indices fput index indices
      ]
      set index index + 1
    ]
  ]

  let n-of-comm ifelse-value (number-of-communication > length indices) [(length indices)] [(number-of-communication)]
  set indices n-of n-of-comm indices

  interact-with-indices communicator communicatee indices
end

to interact-with-indices [communicator communicatee indices]
  if (agent-similarity-between communicator communicatee true) >= similarity-threshold [
    foreach indices [
      let communicator-info (item ? ([opinion] of communicator))
      let communicatee-info (item ? ([opinion] of communicatee))

      ask communicatee [
        let belief (change-belief communicator-info communicatee-info ([anonymous?] of communicator))
        if belief != communicatee-info [
          ifelse belief mod 2 != communicatee-info mod 2
          [ set number-of-change-in-belief number-of-change-in-belief + 1 ] ; belief-change
          [
            ifelse belief > communicatee-info
            [ set number-of-change-to-conviction number-of-change-to-conviction + 1 ] ; change-to-conviction
            [ set number-of-change-to-inconviction number-of-change-to-inconviction + 1 ] ; change-to-inconviction
          ]
          set opinion replace-item ? opinion belief
        ]
      ]
    ]
  ]
end

to-report change-belief [communicator-value communicatee-value anonymous-source?]
  let p1 0
  let p2 0

  ifelse communicatee-value = 0 or communicatee-value = 1
  [ ; if communicatee is unconvinced about his opinion
    set p1 ifelse-value anonymous-source? [ probability-of-convince * anonymous-credibility ] [ probability-of-convince ] ; probability of changing conviction to convinced
    set p2 ifelse-value anonymous-source? [ probability-of-believe * anonymous-credibility ] [ probability-of-believe ] ; probability of changing belief to conform to communicator

    ifelse (communicator-value mod 2) = (communicatee-value mod 2) ; check if it's same and don't care whether incoming opinion is convinced or not
    [ ifelse random-float 1.0 < p1 ; roll dice to determine conviction change to conviced
      [ report communicatee-value + 2 ]
      [ report communicatee-value ]
    ]
    [ ifelse random-float 1.0 < p2 ; roll dice to determin belief change
      [ report communicator-value mod 2 ]
      [ report communicatee-value ]
    ]
  ]
  [ ; if communicatee is convinced about his opinion
    set p1 ifelse-value anonymous-source? [ probability-of-unconvince * anonymous-credibility ] [ probability-of-unconvince ] ; probability of changing conviction to unconvinced
    ifelse (communicator-value mod 2) != (communicatee-value mod 2) ; check if it's same and don't care whether incoming opinion is convinced or not
    [ ifelse random-float 1.0 < p1 ; roll dice to determine conviction change to unconviced
      [ report communicatee-value - 2 ]
      [ report communicatee-value ]
    ]
    [ report communicatee-value ]
  ]
end

to-report topic-similarity-between [communicator communicatee with-indices]
  let value 0
  foreach with-indices [
    let communicator-info (item ? ([opinion] of communicator))
    let communicatee-info (item ? ([opinion] of communicatee))

    if (communicator-info mod 2) = (communicatee-info mod 2) [ set value value + 1 ]
  ]
  ifelse (length with-indices) = 0
  [ report 0 ]
  [ report value / (length with-indices) * 100 ]
end

to-report agent-similarity-between [communicator communicatee consider-anonymity?]
  let value similarity ([opinion] of communicator) ([opinion] of communicatee)
  if consider-anonymity? and [anonymous?] of communicator and [anonymous?] of communicatee [ set value value * anonymous-similarity-factor ]
  set value min sentence value 1.0
  set value max sentence value 0.0
  report value
end

to-report discrepancy [communicator-info communicatee-info]
  let value 0
  let index 0
  while [ index < number-of-information ]
  [
    set value value + (abs (item index communicator-info) - (item index communicatee-info)) mod 2
    set index index + 1
  ]
  report value / number-of-information
end

to-report similarity [communicator-info communicatee-info]
  report 1 - (discrepancy communicator-info communicatee-info)
end

;--------------------------------------------------------------------------
;
;  count the number of information in the world
;
;--------------------------------------------------------------------------

to-report total-number-of-change-in-belief
  report sum [number-of-change-in-belief] of turtles
end

to-report total-number-of-change-to-conviction
  report sum [number-of-change-to-conviction] of turtles
end

to-report total-number-of-change-to-inconviction
  report sum [number-of-change-to-inconviction] of turtles
end

to-report number-of-true-information
  let value 0
  ask turtles [ set value value + (number-of-true opinion) ]
  report value
end

to-report number-of-convinced-information
  let value 0
  ask turtles [ set value value + (number-of-convinced opinion) ]
  report value
end

to-report number-of-convinced-true-information
  let value 0
  ask turtles [ set value value + (number-of-convinced-true opinion) ]
  report value
end

to-report number-of-convinced-false-information
  let value 0
  ask turtles [ set value value + (number-of-convinced-false opinion) ]
  report value
end

to-report number-of-unconvinced-true-information
  let value 0
  ask turtles [ set value value + (number-of-unconvinced-true opinion) ]
  report value
end

to-report number-of-unconvinced-false-information
  let value 0
  ask turtles [ set value value + (number-of-unconvinced-false opinion) ]
  report value
end

to-report number-of-convinced-true-information-for [index]
  let value 0
  ask turtles [ set value value + (is-convinced-true-for index opinion) ]
  report value / (count turtles) * 100
end

to-report number-of-convinced-false-information-for [index]
  let value 0
  ask turtles [ set value value + (is-convinced-false-for index opinion) ]
  report value / (count turtles) * 100
end

to-report number-of-unconvinced-true-information-for [index]
  let value 0
  ask turtles [ set value value + (is-unconvinced-true-for index opinion) ]
  report value / (count turtles) * 100
end

to-report number-of-unconvinced-false-information-for [index]
  let value 0
  ask turtles [ set value value + (is-unconvinced-false-for index opinion) ]
  report value / (count turtles) * 100
end

;--------------------------------------------------------------------------
;
;  count the number of information of each agent
;
;--------------------------------------------------------------------------

to-report number-of-true [info] ; true == 1, 3
  report length filter [? = 1 or ? = 3] info
end

to-report number-of-convinced [info] ; convinced == 2, 3
  report length filter [? = 2 or ? = 3] info
end

to-report number-of-convinced-true [info] ; convinced-true == 3
  report length filter [? = 3] info
end

to-report number-of-convinced-false [info] ; convinced-false == 2
  report length filter [? = 2] info
end

to-report number-of-unconvinced-true [info] ; unconvinced-true == 1
  report length filter [? = 1] info
end

to-report number-of-unconvinced-false [info] ; unconvinced-false == 0
  report length filter [? = 0] info
end

to-report is-convinced-true-for [index info]
  report ifelse-value (item index info = 3) [ 1 ] [ 0 ]
end

to-report is-convinced-false-for [index info]
  report ifelse-value (item index info = 2) [ 1 ] [ 0 ]
end

to-report is-unconvinced-true-for [index info]
  report ifelse-value (item index info = 1) [ 1 ] [ 0 ]
end

to-report is-unconvinced-false-for [index info]
  report ifelse-value (item index info = 0) [ 1 ] [ 0 ]
end

;--------------------------------------------------------------------------
;
;  plot
;
;--------------------------------------------------------------------------

to update-link-color
  if switch-link-color? [
    ask links [
      let node-similarity agent-similarity-between end1 end2 false

      ifelse node-similarity >= similarity-threshold
      [ set color 9 ]
      [ set color 2 ]
    ]
  ]
end

to update-node-color
  if switch-node-color? [
    ask turtles [
      let truth-in-agent number-of-true [opinion] of self
      let truth-percent (truth-in-agent / number-of-information * 100)

      ifelse truth-percent >= 80 [ set color (ifelse-value anonymous? [ red + 2 ] [ green + 2 ]) ]
      [ ifelse truth-percent >= 60 [ set color (ifelse-value anonymous? [ red ] [ green ]) ]
        [ ifelse truth-percent >= 40 [ set color (ifelse-value anonymous? [ red - 2 ] [ green - 2 ]) ]
          [ ifelse truth-percent >= 20 [ set color (ifelse-value anonymous? [ red - 4 ] [ green - 4 ]) ]
            [ set color (ifelse-value anonymous? [ red - 5 ] [ green - 5 ]) ]
          ]
        ]
      ]
    ]
  ]
end

to update-plot
  set-current-plot "opinions"
  set-current-plot-pen "ct"
  plot number-of-convinced-true-information / total-number-of-information * 100
  set-current-plot-pen "cf"
  plot number-of-convinced-false-information / total-number-of-information * 100
  set-current-plot-pen "ut"
  plot number-of-unconvinced-true-information / total-number-of-information * 100
  set-current-plot-pen "uf"
  plot number-of-unconvinced-false-information / total-number-of-information * 100

  set-current-plot "belief changes"
  set-current-plot-pen "belief-changes"
  plot temp-number-of-change-in-belief
  set-current-plot-pen "reference-line"
  plot 5

  set-current-plot "opinion changes"
  set-current-plot-pen "change-in-belief"
  plot total-number-of-change-in-belief
  set-current-plot-pen "change-to-conviction"
  plot total-number-of-change-to-conviction
  set-current-plot-pen "change-to-inconviction"
  plot total-number-of-change-to-inconviction
end


; Copyright 2008 Uri Wilensky. All rights reserved.
; The full copyright notice is in the Information tab.
@#$#@#$#@
GRAPHICS-WINDOW
12
128
524
661
16
16
15.212121212121213
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
0
0
1
ticks
30.0

BUTTON
12
26
108
59
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
109
26
205
59
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

SLIDER
982
94
1175
127
population
population
10
1000
900
10
1
NIL
HORIZONTAL

SLIDER
982
60
1175
93
average-connection
average-connection
1
100
4
1
1
NIL
HORIZONTAL

SLIDER
400
26
593
59
anonymity
anonymity
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
206
26
399
59
number-of-information
number-of-information
1
40
10
1
1
NIL
HORIZONTAL

SLIDER
206
60
399
93
number-of-communication
number-of-communication
1
number-of-information
1
1
1
NIL
HORIZONTAL

PLOT
525
128
981
661
opinions
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"ct" 1.0 0 -10899396 true "" ""
"cf" 1.0 0 -2674135 true "" ""
"ut" 1.0 0 -6565750 true "" ""
"uf" 1.0 0 -1604481 true "" ""

SWITCH
12
60
205
93
switch-node-color?
switch-node-color?
1
1
-1000

SWITCH
12
94
205
127
switch-link-color?
switch-link-color?
1
1
-1000

SLIDER
206
94
399
127
similarity-threshold
similarity-threshold
0
1
0.6
0.1
1
NIL
HORIZONTAL

SLIDER
594
26
787
59
probability-of-convince
probability-of-convince
0
1
0.9
0.05
1
NIL
HORIZONTAL

SLIDER
594
60
787
93
probability-of-unconvince
probability-of-unconvince
0
1
0.1
0.05
1
NIL
HORIZONTAL

SLIDER
594
94
787
127
probability-of-believe
probability-of-believe
0
1.0
0.1
0.05
1
NIL
HORIZONTAL

SLIDER
788
26
981
59
initial-convinced
initial-convinced
0
1
0.2
0.05
1
NIL
HORIZONTAL

SLIDER
788
60
981
93
initial-convinced-true
initial-convinced-true
0
1
0.4
0.05
1
NIL
HORIZONTAL

SLIDER
788
94
981
127
initial-unconvinced-true
initial-unconvinced-true
0
1
0.7
0.05
1
NIL
HORIZONTAL

PLOT
982
128
1369
394
opinion changes
NIL
NIL
0.0
12.0
0.0
100.0
true
false
"" ""
PENS
"change-in-belief" 1.0 0 -16777216 true "" ""
"change-to-conviction" 1.0 0 -13210332 true "" ""
"change-to-inconviction" 1.0 0 -6565750 true "" ""

SLIDER
1176
60
1369
93
cols
cols
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
1176
94
1369
127
rows
rows
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
400
60
593
93
anonymous-similarity-factor
anonymous-similarity-factor
0
2
1.2
0.1
1
NIL
HORIZONTAL

CHOOSER
982
14
1369
59
network-structure
network-structure
"scalefree" "lattice" "random"
1

TEXTBOX
209
10
371
36
Bounded Confidence Model
12
0.0
1

TEXTBOX
404
10
554
28
Anonymity\n
12
0.0
1

SLIDER
400
94
593
127
anonymous-credibility
anonymous-credibility
0
1
0.5
0.1
1
NIL
HORIZONTAL

TEXTBOX
15
10
165
28
Application
12
0.0
1

TEXTBOX
598
10
748
28
Stochastic Process
12
0.0
1

TEXTBOX
793
10
943
28
Initial Context
12
0.0
1

PLOT
982
395
1369
661
belief changes
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"belief-changes" 1.0 0 -2674135 true "" ""
"reference-line" 1.0 0 -7500403 true "" ""

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
