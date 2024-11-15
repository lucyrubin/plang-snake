module Snake exposing (game)

import Playground exposing (..)

-- PHYSICS PARAMETERS

movementSpeed = 2

-- CONSTANTS

width = 100
height = 100

appleX = 100
appleY = 100

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
    [ if snake.isAlive then
      rectangle (rgb 255 0 255) width height 
        |> move snake.x snake.y  
      else 
      words black "Dead!"
      , circle (rgb 255 0 0) 25 
        |> move appleX appleY] 



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
    
  in
    { snake
      | x = newX
      , y = newY
      , vx = 1
      , vy = 1
      , dir = newDir
      , isAlive = inBounds (computer.screen.left + (width / 2)) (computer.screen.right - (width / 2)) snake.x && inBounds (computer.screen.bottom + (height / 2)) (computer.screen.top - (height / 2)) snake.y && (not (collided snake)) && snake.isAlive
    }


inBounds min max x = -- Don't allow character to move offscreen
    if x > max then
      False
    else if x < min then
      False 
    else
      True


  
collided snake = ((hypot(snake.x - appleX) (snake.y - appleY) < 25))

hypot x y = -- Returns distance between centers
  toPolar (x, y) |> Tuple.first
 


