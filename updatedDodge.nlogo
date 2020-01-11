extensions [sound]
globals [
  alive?
  score
  highScore
  money
  playerSpeed
  bulletSpeed
  arrowSpeed
  spawnRate
  bulletSpawnRate ; how often the turret spawns more bullets
  items
  numArrows
  firstStartUp
  mouseClicked?
  firstShop
  level

  purchased


  backgroundColor

  up1
  up2
  pow1
  pow2
  pow3

  shopTab
]

breed [players player]
breed [bullets bullet]
breed [bombs bomb]
breed [turrets turret]
breed [arrows arrow]

players-own [
  playerMS
]

bullets-own [
  bulletMS
  fromBomb
  lifetime
]

bombs-own [
  bombMS
  lifetime
]

turrets-own [
  turretMS
  lifetime
]

arrows-own [
  contact
]

to-report rItems
  report items
end

to-report rArrows
  report numArrows
end

to setup
  set mouseClicked? true
  clear-patches

  ifelse firstStartUp = 0
  [
    setupShop
    set firstStartUp 1
    ask patches [ set pcolor white ]
  ]

  [
    ask patches [set pcolor blue - 2]

    if difficulty = "easy" [ set level 1 ]
    if difficulty = "medium" [ set level 3 ]
    if difficulty = "hard" [ set level 5 ]
    if difficulty = "expert" [ set level 7 ]

    set firstShop 0
    set score 0
    set numArrows (pow1 * 3)
    set items pow2
    set bulletSpeed 1
    set spawnRate 3
    set playerSpeed .2 + (up1 * .008)
    set arrowSpeed playerSpeed - (up1 * .008)
    set shopTab "menu"
    sound:play-note "Seashore" 60 64 1

    set alive? true
    create-players 1 [
      set shape "player"
      set color white
      set size 3
    ]
  ]
end

to setupShop
  set up1 0
  set up2 0
  set pow1 0
  set pow2 0
  set pow3 0
end

to play
  createLabels
  if not mouse-down? [ set mouseClicked? false]

  ; death mechanism
  ifelse not alive? [
    ask patches [ set pcolor blue - 2 ]

    if shopTab = "menu" [ menuTab ]
    if shopTab = "powerups" [ powerupTab ]
    if shopTab = "upgrades" [ upgradeTab ]
    if shopTab = "backgrounds" [ backgroundTab ]


    if highScore < score [
      set highScore score
    ]
    set score 0
    set items 0
    set numArrows 0
  ]


  [

    ifelse score > 0
    [set bulletSpeed (sqrt(sqrt(score)) / 3)]
    [ set bulletSpeed 0.3 ]

    if score > 40 [
      set bulletSpeed (sqrt(sqrt(40))) / 3
    ]

    ; creation of powerups
    createPowerup
    checkPowerup

    createItem
    checkItem

    ; creation of bullets and bombs
    every spawnRate / level [

      if count players > 0 [
        genBullet

        if random 7 - level < 1 and count bombs < 1 [
          genBomb
        ]

        if random 10 - level < 1 and count turrets < 1 [
          genTurret
        ]
      ]
    ]


    ; movement of ALL entities
    every .03 [
      if count players > 0 [
        ask player 0 [
          set heading towardsxy mouse-xcor mouse-ycor
          fd playerSpeed
        ]
      ]

      ask bullets [
        fd bulletSpeed
        set lifetime (lifetime + 1)
      ]
      ask bombs [
        fd bulletSpeed
        set lifetime (lifetime + 1)
      ]
      ask arrows [
        set arrowSpeed playerSpeed * 2
        fd arrowSpeed
      ]
      ask turrets [
        fd bulletSpeed / 2
        set lifetime (lifetime + 1)
      ]

      ; gives arrows to player
      every 3 [
        if numArrows < 10 + up2 [
          set numArrows (numArrows + 1)
        ]
      ]

      ; check death of ALL entities
      checkPlayerDeath
      checkBulletDeath
      checkTurretDeath
      checkBombDeath
      checkArrowDeath

      ; activation of obstacles
      if random 100 < 1 and count bombs > 0 [
        bombActivate
      ]

      if count turrets > 0 [
        every bulletSpawnRate [
          spawnBullet
        ]
      ]
    ]

  ]
end

to checkPlayerDeath
  ask players [
    if count neighbors with [count bullets-here > 0 or count bombs-here > 0] > 0 [
      set alive? false
      set shopTab "menu"
      ask patches with [pcolor != black] [set pcolor black]
    ]
  ]

  if not alive? [ clear-turtles ]
end

to checkBulletDeath
  ask bullets with [(xcor > max-pxcor - .3 or
    xcor < min-pxcor + .3 or
    ycor > max-pycor - .3 or
    ycor < min-pycor + .3) and lifetime > 20] [

    if not fromBomb [
      set score (score + 1)
      set money (money + 1)
    ]
    die
  ]
end

to checkBombDeath
  ask bombs with [(xcor > max-pxcor - .3 or
    xcor < min-pxcor + .3 or
    ycor > max-pycor - .3 or
    ycor < min-pycor + .3) and lifetime > 20] [
    set score (score + 3)
    set money (money + 3)
    die
  ]
end

to checkTurretDeath
  ask turrets with [(xcor > max-pxcor - .3 or
    xcor < min-pxcor + .3 or
    ycor > max-pycor - .3 or
    ycor < min-pycor + .3) and lifetime > 20] [
    set score (score + 5)
    set money (money + 5)
    die
  ]
end

to checkArrowDeath
  ask arrows with [xcor > max-pxcor - .3 or
    xcor < min-pxcor + .3 or
    ycor > max-pycor - .3 or
    ycor < min-pycor + .3] [
    die
  ]

  ask arrows [
    if count bullets-on neighbors > 0 [
      ask bullets-on neighbors [
        set score (score + 1)
        set money (money + 1)
        die
      ]
      set contact true
    ]

    if count bombs-on neighbors > 0 [
      ask bombs-on neighbors [
        set score (score + 1)
        set money (money + 1)
        die
      ]
      set contact true
    ]

    if count turrets-on neighbors > 0 [
      ask turrets-on neighbors [
        set score (score + 1)
        set money (money + 1)
        die
      ]
      set contact true
    ]
  ]

  ask arrows with [contact] [
    die
  ]
end

to genBullet
  create-bullets 1 [
    spawnRandomLocation

    set shape "fish 1.1"
    set size 2
    set fromBomb false
    set heading towards player 0
  ]
end

to genBomb
  create-bombs 1 [
    set size 3
    set shape "fish bowl (full)"
    spawnRandomLocation

    set heading towards player 0
  ]
end

to genTurret
  create-turrets 1 [
    set bulletSpawnRate 1
    set size 5
    set shape "jellyfish"
    spawnRandomLocation

    set heading towardsxy mouse-xcor mouse-ycor
  ]
end

to spawnBullet
  create-bullets 1 [
    set fromBomb true
    set shape "fish 3"
    set size 1.5
    setxy ([xcor] of one-of turrets) ([ycor] of one-of turrets)
    set heading towards player 0
  ]
end

to genArrow
  if numArrows > 0 [
    set numArrows (numArrows - 1)
    create-arrows 1 [
      setxy ([xcor] of player 0) ([ycor] of player 0)
      set heading towardsxy mouse-xcor mouse-ycor
      set contact false
    ]
  ]
end

to bombActivate
  ifelse score < 10
  [
    create-ordered-bullets 4 [
      set fromBomb true
      set shape "fish 2"
      set size 1.5
      setxy ([xcor] of one-of bombs) ([ycor] of one-of bombs)
    ]
  ]
  [
    ifelse score < 20
    [
      create-ordered-bullets 6 [
        set fromBomb true
        set shape "fish 2"
        set size 1.5
        setxy ([xcor] of one-of bombs) ([ycor] of one-of bombs)
      ]
    ]
    [
      create-ordered-bullets 8 [
        set fromBomb true
        set shape "fish 2"
        set size 1.5
        setxy ([xcor] of one-of bombs) ([ycor] of one-of bombs)
      ]
    ]
  ]

  ask bombs [ die ]
end

to createPowerup
  if count patches with [pcolor = green] = 0 [
    if random 20000 < 1 [
      ask one-of patches [
        set pcolor green
      ]
    ]
  ]
end

to checkPowerup
  ask patches with [pcolor = green] [
    ask neighbors [
      if count players-here > 0 [
        ask patches with [pcolor = green] [
          set pcolor blue - 2
        ]

        set playerSpeed (playerSpeed * 1.2)
      ]
    ]
  ]
end

to createItem
  if count patches with [pcolor = orange] = 0 [
    if random 600000 < 1 [
      ask one-of patches [
        set pcolor orange
      ]
    ]
  ]
end

to checkItem
  ask patches with [pcolor = orange] [
    ask neighbors [
      if count players-here > 0 [
        ask patches with [pcolor = orange] [
          set pcolor blue - 2
        ]

        set items (items + 1)
      ]
    ]
  ]
end

to useItem
  if items > 0 [
    sound:play-note "gunshot" 60 64 1
    set items (items - 1)
    create-ordered-arrows 15 + (pow3 * 2) [
      set contact false
      setxy ([xcor] of player 0) ([ycor] of player 0)
    ]
  ]
end








to spawnRandomLocation
  ifelse random 4 = 0
      [setxy max-pxcor ((random (2 * max-pycor)) - max-pycor)]
  [ifelse random 3 = 0
    [setxy min-pxcor (((random 2 * max-pycor)) - max-pycor)]
    [ifelse random 2 = 0
      [setxy (((random 2 * max-pxcor)) - max-pxcor) max-pycor]
      [setxy (((random 2 * max-pxcor)) - max-pxcor) min-pycor]
    ]
  ]
end

to createLabels
  ask patch 15 13 [set plabel word "Score: "  score]
  ask patch 15 15 [set plabel word "Highscore: " highScore]
  ask patch 15 -15 [set plabel word "Money: " money]
;  ask patch -8 15 [set plabel word "Money: " money]
end

;shop option spacing: (((max-pycor * 2) + 1) / 5)
;

to clearOptions
  ask patches with [pycor > ((max-pycor - (4 * (((max-pycor * 2) + 1) / 5))) - 1) and pycor < ((max-pycor - (2 * (((max-pycor * 2) + 1) / 5))) + 1)]
          [set plabel " "]
end

to menuTab ;initial menu of shop
  ask patch 2 8 [set plabel "Shop"]
  ask patch -7 3 [set plabel "Upgrades"]
  ask patch -6 -3 [set plabel "Customize"]
  ask patch -6.6 -9 [set plabel "Powerups"]

  if firstShop = 0 [
    cro 1 [
      set shape "jellyfish"
      setxy 8 0
      set size 5
    ]
    print "hello"
    set firstShop 1
  ]
  ask patch 10 -8 [set plabel "Continue"]

  if mouse-down? and not mouseClicked? [
    if mouse-xcor > -14.8 and
    mouse-xcor < -6.2 and
    mouse-ycor < 4 and
    mouse-ycor > 2.2 [
      set shopTab "upgrades"
      clear-patches
      clear-turtles
      createLabels
      set firstShop 0
    ]

    if mouse-xcor > -14.8 and
    mouse-xcor < -4.5 and
    mouse-ycor < -2.1 and
    mouse-ycor > -3.5 [
      set shopTab "backgrounds"
      clear-patches
      clear-turtles
      createLabels
      set firstShop 0
    ]

    if mouse-xcor > -15 and
    mouse-xcor < -6.4 and
    mouse-ycor < -8 and
    mouse-ycor > -9.7 [
      set shopTab "powerups"
      clear-patches
      clear-turtles
      createLabels
      set firstShop 0
    ]

    if mouse-xcor > 2.5 and
    mouse-xcor < 10.5 and
    mouse-ycor < -7 and
    mouse-ycor > -8.8 and
    shopTab = "menu" [
      setup
      clear-patches
      clear-turtles
      createLabels
      set firstShop 0
      setup
    ]
  ]

end

to upgradeTab
  ;placeholder options
  ask patch 4 11 [set plabel "Upgrades"]
  ask patch -12 -15 [set plabel "Back"]


  ask patch 7 6 [set plabel "Increase Base Speed"]
  ask patch 12 6 [set plabel up1]
  ask patch 16 6 [set plabel "$10"]

  ask patch 7 2 [set plabel "Increase Arrow Inventory"]
  ask patch 12 2 [set plabel up2]
  ask patch 16 2 [set plabel "$5"]

  if mouse-down? = true and not mouseClicked? [
    if mouse-xcor <= -11.2 and mouse-xcor >= -16.1 and mouse-ycor > -15.8 and mouse-ycor < -13.8 [
      set shopTab "menu"
      clear-patches
      createLabels
    ]

    if mouse-ycor < 8 and mouse-ycor > 4 and money >= 10 [
      set up1 (up1 + 1)
      set money (money - 10)
      set mouseClicked? true
    ]


    if mouse-ycor < 4 and mouse-ycor > 0 and money >= 5 [
      set up2 (up2 + 1)
      set money (money - 5)
      set mouseClicked? true
    ]
  ]

end

to backgroundTab
  ;placeholder options
  ask patch 10 0 [set plabel "Currently no options"]
  ask patch -12 -15 [set plabel "BACK"]
  if mouse-down? = true and not mouseClicked? [
    if mouse-xcor <= -11.2 and mouse-xcor >= -16.1 and mouse-ycor > -15.8 and mouse-ycor < -13.8 [
      set shopTab "menu"
      clear-patches
      createLabels
    ]
  ]
end

to powerupTab
  ;placeholder options
  ask patch 5 11 [set plabel "Powerups"]
  ask patch -12 -15 [set plabel "BACK"]

  ask patch 7 6 [set plabel "Start with +3 arrows"]
  ask patch 12 6 [set plabel pow1]
  ask patch 16 6 [set plabel "$5"]

  ask patch 7 2 [set plabel "Start with +1 item"]
  ask patch 12 2 [set plabel pow2]
  ask patch 16 2 [set plabel "$5"]

  ask patch 7 -2 [set plabel "Item spawn more arrows"]
  ask patch 12 -2 [set plabel pow3]
  ask patch 16 -2 [set plabel "$5"]

  if mouse-down? = true and not mouseClicked? [
    if mouse-xcor <= -11.2 and mouse-xcor >= -16.1 and mouse-ycor > -15.8 and mouse-ycor < -13.8 [
      set shopTab "menu"
      clear-patches
      createLabels
    ]

    if mouse-ycor < 8 and mouse-ycor > 4 and money >= 5 [
      set pow1 (pow1 + 1)
      set money (money - 5)
      set mouseClicked? true
    ]


    if mouse-ycor < 4 and mouse-ycor > 0 and money >= 5 [
      set pow2 (pow2 + 1)
      set money (money - 5)
      set mouseClicked? true
    ]

    if mouse-ycor < 0 and mouse-ycor > -4 and money >= 5 [
      set pow3 (pow3 + 1)
      set money (money - 5)
      set mouseClicked? true
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
219
13
656
451
-1
-1
13.0
1
26
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

BUTTON
121
24
184
57
NIL
play
T
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
43
21
106
54
NIL
setup
NIL
1
T
OBSERVER
NIL
Q
NIL
NIL
1

BUTTON
38
117
124
150
NIL
genArrow
NIL
1
T
OBSERVER
NIL
Z
NIL
NIL
1

BUTTON
128
123
210
156
NIL
useItem
NIL
1
T
OBSERVER
NIL
X
NIL
NIL
1

MONITOR
314
23
371
68
items
rItems
17
1
11

MONITOR
227
22
284
67
arrows
numArrows
17
1
11

BUTTON
49
291
166
324
mouse
if mouse-down? [\nprint mouse-xcor\nprint mouse-ycor\n]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
28
350
144
395
NIL
mouse-xcor
17
1
11

MONITOR
29
413
107
458
NIL
mouse-ycor
17
1
11

CHOOSER
73
171
211
216
difficulty
difficulty
"easy" "medium" "hard" "expert"
1

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

fish 1.1
false
0
Polygon -1 true false 59 116 36 72 30 71 15 105 30 135 15 165 28 199 35 197 60 151
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 60 165
Circle -16777216 true false 215 106 30
Polygon -7500403 true true 269 194
Polygon -16777216 true false 281 178 291 162 292 149 285 131 269 128 253 139 247 156 247 165 248 175 266 185 273 189

fish 1.2
false
0
Polygon -1 true false 59 116 36 72 30 71 15 105 30 135 15 165 28 199 35 197 60 151
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 60 165
Circle -16777216 true false 215 106 30
Polygon -7500403 true true 269 194
Polygon -16777216 true false 281 178 291 162 292 149 287 138 274 137 265 145 262 157 264 167 266 176 268 183 274 187

fish 1.3
false
0
Polygon -1 true false 59 116 36 72 30 71 15 105 30 135 15 165 28 199 35 197 60 151
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 60 165
Circle -16777216 true false 215 106 30
Polygon -7500403 true true 269 194
Polygon -2064490 true false 285 180
Polygon -16777216 true false 280 178 289 167 292 155 288 147 276 148 271 158 274 171 281 178

fish 1.4
false
0
Polygon -1 true false 59 116 36 72 30 71 15 105 30 135 15 165 28 199 35 197 60 151
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 60 165
Circle -16777216 true false 215 106 30

fish 2
false
0
Polygon -1 true false 56 133 34 127 12 105 21 126 23 146 16 163 10 194 32 177 55 173
Polygon -7500403 true true 156 229 118 242 67 248 37 248 51 222 49 168
Polygon -7500403 true true 30 60 45 75 60 105 50 136 150 53 89 56
Polygon -7500403 true true 50 132 146 52 241 72 268 119 291 147 271 156 291 164 264 208 211 239 148 231 48 177
Circle -1 true false 237 116 30
Circle -16777216 true false 241 127 12
Polygon -1 true false 159 228 160 294 182 281 206 236
Polygon -7500403 true true 102 189 109 203
Polygon -1 true false 215 182 181 192 171 177 169 164 152 142 154 123 170 119 223 163
Line -16777216 false 240 77 162 71
Line -16777216 false 164 71 98 78
Line -16777216 false 96 79 62 105
Line -16777216 false 50 179 88 217
Line -16777216 false 88 217 149 230

fish 3
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1184463 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

fish bowl (full)
true
12
Polygon -1 true false 110 210 111 203 107 193 101 193 106 204 103 214 107 216 111 206
Polygon -7500403 false false 60 74 254 74 240 106 255 136 255 198 210 241 104 240 60 197 61 164 61 135 75 105
Polygon -13791810 true false 72 120 64 138 63 196 106 239 211 239 253 198 252 138 245 122 228 118 211 123 192 117 174 122 154 117 141 124 132 121 123 120 106 121 88 118
Polygon -1 true false 120 213 116 203 110 198 105 203 110 214 106 223 111 230 116 224
Polygon -1 true false 229 174 233 164 239 159 244 164 239 175 243 184 238 191 233 185
Polygon -1 true false 119 153 115 143 109 138 104 143 109 154 105 163 110 170 115 164
Polygon -1 true false 122 217 120 225 129 225 137 231 139 221 122 217
Polygon -1 true false 224 177 232 187 222 185 216 192 212 182 230 177
Polygon -1 true false 121 155 119 167 128 165 138 170 136 159 119 154
Polygon -1 true false 149 206 140 195 124 191 127 197 123 203 129 211 150 207
Polygon -1 true false 201 166 208 158 223 150 220 159 226 163 218 170 200 167
Polygon -1 true false 151 148 145 137 128 133 129 139 126 145 132 149 152 149
Circle -16777216 true false 145 203 2
Circle -16777216 true false 145 203 2
Polygon -8630108 true false 186 172 200 162 220 166 239 175 208 186 189 184 185 178
Polygon -14835848 true false 164 151 150 141 130 145 111 154 142 165 161 163 165 157
Polygon -5825686 true true 164 211 150 201 130 205 111 214 142 225 161 223 165 217
Circle -16777216 true false 150 150 2
Circle -16777216 true false 184 191 2
Circle -16777216 true false 151 209 2
Circle -16777216 true false 196 172 2
Polygon -13840069 true false 189 240 190 240 188 234 191 226 188 218 194 212 194 205 197 200 200 208 199 219 196 222 197 227 196 235 195 237 192 236
Polygon -13840069 true false 182 236 179 228 177 216 179 207 180 192 185 183 190 191 187 198 189 207 187 217 189 227 188 238

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

jellyfish
true
0
Polygon -13791810 true false 143 142 142 158 146 173 145 187 148 197 146 210 150 221 155 211 155 199 155 189 158 180 155 170 156 164 153 152 154 146 146 141
Polygon -13791810 true false 125 145 131 166 131 186 130 199 131 211 134 225 141 215 140 199 141 186 138 177 141 165 136 154 136 143 127 145
Polygon -13791810 true false 109 144 109 158 109 170 114 178 113 187 116 205 112 214 118 223 122 219 123 207 122 197 125 188 124 177 127 163 123 157 123 143 112 144
Polygon -13791810 true false 94 143 92 154 94 165 91 178 97 191 96 202 100 213 98 224 103 221 107 214 105 202 106 195 104 183 103 171 106 158 106 149 105 141
Polygon -11221820 true false 92 144 83 127 83 113 87 101 96 90 114 85 131 83 149 86 161 91 170 106 170 122 164 137 156 145 126 145
Circle -16777216 true false 106 108 8
Circle -16777216 true false 136 108 8
Polygon -16777216 true false 118 121 136 122 132 128 126 129 121 127 119 121

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

player
true
0
Line -7500403 true 195 75 195 90
Line -7500403 true 195 75 180 60
Line -7500403 true 180 60 135 60
Line -7500403 true 135 60 90 105
Line -2064490 false 195 90 180 105
Line -7500403 true 180 105 150 105
Line -7500403 true 150 105 135 120
Line -7500403 true 134 120 134 135
Line -7500403 true 90 105 90 135
Line -7500403 true 90 135 75 150
Line -7500403 true 135 135 120 165
Line -7500403 true 75 150 45 150
Line -7500403 true 45 150 30 165
Line -7500403 true 30 165 30 180
Line -7500403 true 30 180 45 195
Line -7500403 true 45 195 90 195
Line -7500403 true 90 195 105 180
Line -7500403 true 120 165 105 180
Polygon -2064490 true false 180 60 135 60 90 105 90 135 75 150 45 150 30 165 30 180 45 195 90 195 120 165 135 135 135 120 150 105 180 105 195 90 195 75 180 60
Line -16777216 false 136 59 150 108
Line -16777216 false 89 118 126 151
Line -16777216 false 80 146 102 185
Line -16777216 false 57 150 57 195
Rectangle -16777216 true false 180 75 180 75
Line -16777216 false 106 88 134 123
Polygon -16777216 true false 181 93 196 93 181 108 181 93
Circle -7500403 true true 180 75 0
Circle -16777216 true false 175 71 8

player (2)
true
0
Line -7500403 true 135 60 180 60
Line -7500403 true 180 60 195 75
Line -7500403 true 195 75 195 90
Line -7500403 true 195 90 180 105
Line -7500403 true 180 105 150 105
Line -7500403 true 135 60 105 90
Line -7500403 true 150 105 135 120
Line -7500403 true 105 90 75 90
Line -7500403 true 75 90 60 120
Line -7500403 true 135 120 105 135
Line -7500403 true 105 135 117 166
Line -7500403 true 60 120 74 143
Line -7500403 true 74 143 46 151
Line -7500403 true 116 165 90 187
Line -7500403 true 46 152 32 164
Line -7500403 true 30 166 30 180
Line -7500403 true 33 181 43 195
Line -7500403 true 90 187 44 194
Polygon -2064490 true false 181 61 137 61 106 89 76 91 62 120 73 143 46 152 32 166 29 182 44 194 92 189 116 165 107 136 134 122 150 105 181 106 194 91 196 74 182 62
Circle -16777216 true false 174 70 8
Polygon -16777216 true false 180 105 193 92 179 92 180 105
Line -16777216 false 137 62 150 105
Line -16777216 false 107 89 136 119
Line -16777216 false 77 91 107 135
Line -16777216 false 73 142 102 176
Line -16777216 false 48 150 68 192

player (3)
true
0
Line -7500403 true 135 60 180 60
Line -7500403 true 180 60 195 75
Line -7500403 true 195 75 195 90
Line -7500403 true 195 90 180 105
Line -7500403 true 180 105 150 105
Line -7500403 true 150 105 135 120
Line -7500403 true 135 60 105 90
Line -7500403 true 105 90 75 90
Line -7500403 true 75 90 60 120
Line -7500403 true 60 120 60 150
Line -7500403 true 60 150 75 180
Line -7500403 true 75 180 75 210
Line -7500403 true 75 210 90 225
Line -7500403 true 90 225 105 225
Line -7500403 true 105 225 120 210
Line -7500403 true 120 210 120 180
Line -7500403 true 120 180 105 135
Line -7500403 true 105 135 135 120
Polygon -2064490 true false 181 60 136 60 106 90 76 90 61 120 61 150 76 180 76 210 91 225 106 225 121 210 121 180 106 135 136 120 151 105 181 105 196 90 196 75 181 60
Circle -16777216 true false 175 72 8
Polygon -16777216 true false 180 105 194 91 179 91 179 103
Line -16777216 false 135 61 150 104
Line -16777216 false 106 89 133 121
Line -16777216 false 73 96 110 131
Line -16777216 false 62 135 113 158
Line -16777216 false 77 182 121 181

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

starfish
false
0
Polygon -955883 true false 151 32 179 114 263 119 200 176 224 254 153 209 80 259 107 184 42 118 125 117
Circle -16777216 true false 118 132 12
Circle -16777216 true false 172 132 12
Polygon -16777216 true false 126 155 179 155 173 167 166 176 152 178 141 176 132 167 127 156
Polygon -8630108 true false 119 45 179 15 179 45 118 14
Circle -1 true false 118 198 8
Circle -1 true false 108 220 2
Circle -1 true false 182 200 8
Circle -1 true false 202 225 2
Circle -1 true false 209 133 8
Circle -1 true false 230 130 2
Circle -1 true false 90 133 8
Circle -1 true false 72 127 2
Circle -1 true false 150 71 2
Circle -1 true false 147 93 8

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
