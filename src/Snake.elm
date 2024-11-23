module Snake exposing (game)

import Playground exposing (..)
import Random
import Array

-- PHYSICS PARAMETERS

movementSpeed = 2

-- CONSTANTS

radius = 25
appleRadius = 15

-- MAIN

game =
  { initialState = initialState
  , updateState = update
  , view = view
  }

initialState =
  { x = 0
  , y = 0
  , length = 1
  , vx = 0
  , vy = 0
  , dir = Left
  , isAlive = True
  , count = 0
  , appleX = 100
  , appleY = 100
  , segments = []
  }

type Direction = Left | Right | Up | Down


-- VIEW

view computer snake =
  let
    w = computer.screen.width
    h = computer.screen.height
    b = computer.screen.bottom
    convertY y = (b + 76 + y)
  in
    [ 
      if snake.isAlive then
      circle (rgb 255 0 255) radius 
        |> move snake.x snake.y
      else 
      words black "Dead!"
      , circle (rgb 255 0 0) appleRadius
        |> move snake.appleX snake.appleY
      , words black (String.fromInt snake.count)
        |> move 300 300
      , words black (String.fromInt (List.length snake.segments))
        |> move -200 -220
    ] 
    ++ (snake.segments |> List.map drawSegment)

-- UPDATE

update computer snake =
  let
    dt = 2
    vx = 1
    vy = 1
    newY = 
        (if snake.dir == Up then snake.y + movementSpeed else 
        if snake.dir == Down then snake.y - movementSpeed else snake.y)
    newX = 
      
        (if snake.dir == Right then snake.x + movementSpeed else 
        if snake.dir == Left then snake.x - movementSpeed else snake.x)
    newDir = 
        if computer.keyboard.right then Right
        else if computer.keyboard.left then Left
        else if computer.keyboard.up then Up
        else if computer.keyboard.down then Down
        else snake.dir
    newCount = if collided snake then snake.count + 1 else snake.count
    newAppleX = if collided snake then 200 else snake.appleX
    newAppleY = if collided snake then 200 else snake.appleY
    newSegments = 
      if collided snake then updateSegments (snake.segments ++ (newSegment snake)) snake 
      else updateSegments snake.segments snake
    
  in
    { snake
      | x = newX
      , y = newY
      , vx = 1
      , vy = 1
      , dir = newDir
      , isAlive = inBounds (computer.screen.left + (radius)) (computer.screen.right - (radius)) snake.x && inBounds (computer.screen.bottom + (radius)) (computer.screen.top - (radius)) snake.y && snake.isAlive
      , count = newCount
      , appleX = newAppleX
      , appleY = newAppleY
      , segments = newSegments
    }

newSegment snake = 
  [{
    x = snake.x
    , y = snake.y
  }]
 

drawSegment segment = 
  circle (rgb 255 0 0) 25
   |> fade 0.1
   |> move segment.x segment.y

updateSegments segments snake =
  segments |> (List.map (updateSegment snake)) 

updateSegment snake segment =  
 {
  x = snake.x + 10
  , y = snake.y + 10
 }

inBounds min max x = -- Don't allow character to move offscreen
    if x > max then
      False
    else if x < min then
      False 
    else
      True


  
collided snake = ((hypot(snake.x - snake.appleX) (snake.y - snake.appleY) < radius + appleRadius))

hypot x y = -- Returns distance between centers
  toPolar (x, y) |> Tuple.first
 





