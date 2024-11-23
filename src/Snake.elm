module Snake exposing (game, addNewSegment)

import Playground exposing (..)
import Random
import Array exposing (Array)
-- PHYSICS PARAMETERS

movementSpeed : Float
movementSpeed = 2

-- CONSTANTS

radius : Float
radius = 25
appleRadius : Float
appleRadius = 15

segmentSize : Int
segmentSize = 10

-- MAIN

game =
  { initialState = initialState
  , updateState = update
  , view = view
  }

type alias Model = 
  {
    x : Float
    , y : Float
    , length : Int
    , dir : Direction
    , isAlive : Bool
    , count : Int
    , appleX : Float
    , appleY : Float
    , segments : Array Segment
    , head : Segment
    , trail: Array Point
    , isAddingSegment: Bool 
    , numAdded: Int 
  }

initialState : Model  
initialState =
  { x = 0
  , y = 0
  , length = 1
  , dir = Left
  , isAlive = True
  , count = 0
  , appleX = 100
  , appleY = 100
  , segments = Array.empty
  , head = {point = {x= 0, y= 0}, distanceFromHead = 0}
  , trail = Array.empty
  , isAddingSegment = False
  , numAdded = 0
  }

type Direction = Left | Right | Up | Down

type alias Point = {x: Float, y: Float}

type alias Segment = {point: Point, distanceFromHead: Int}

-- VIEW

view computer model =
  let
    w = computer.screen.width
    h = computer.screen.height
    b = computer.screen.bottom
    convertY y = (b + 76 + y)
  in
    [ 
      if model.isAlive then
      circle (rgb 255 0 255) radius 
        |> move model.x model.y
      else 
      words black "Dead!"
      , circle (rgb 255 0 0) appleRadius
        |> move model.appleX model.appleY
      , words black (String.fromInt model.count)
        |> move 300 300
      , words black (String.fromInt (Array.length model.trail))
        |> move -200 -220
    ] 
    ++ (Array.toList (model.segments) |> List.map drawSegment)

-- UPDATE

update computer model =
  let
    newY = 
        (if model.dir == Up then model.y + movementSpeed else 
        if model.dir == Down then model.y - movementSpeed else model.y)
    newX = 
      
        (if model.dir == Right then model.x + movementSpeed else 
        if model.dir == Left then model.x - movementSpeed else model.x)
    newDir = 
        if computer.keyboard.right then Right
        else if computer.keyboard.left then Left
        else if computer.keyboard.up then Up
        else if computer.keyboard.down then Down
        else model.dir
    newCount = if collided model then model.count + 1 else model.count
    newAppleX = if collided model then 
        if model.appleX == 200 then 0
          else 200
        else model.appleX
    newAppleY = if collided model then 
        if model.appleY == 200 then 0 
          else 200
        else model.appleY
    newTrail = updateTrail model {x= newX, y= newY}

    -- Add multiple new segments instead of one so that they are easier to see
    newIsAddingSegment = if collided model then True 
      else if model.isAddingSegment && model.numAdded < segmentSize then True
      else False
    newNumAdded = if model.isAddingSegment then model.numAdded + 1
      else 0
    newSegments = 
      if  model.isAddingSegment then updateSegments (addNewSegment model) model 
      else updateSegments model.segments model
    
   
    
  in
    { model
      | x = newX
      , y = newY
      , dir = newDir
      , isAlive = inBounds (computer.screen.left + (radius)) (computer.screen.right - (radius)) model.x && inBounds (computer.screen.bottom + (radius)) (computer.screen.top - (radius)) model.y && model.isAlive
      , count = newCount
      , appleX = newAppleX
      , appleY = newAppleY
      , segments = newSegments
      , head = model.head
      , trail = newTrail
      , isAddingSegment = newIsAddingSegment
      , numAdded = newNumAdded
      
    }

-- add a new Segment to the Model
addNewSegment : Model -> Array Segment
addNewSegment model = Array.append model.segments (Array.fromList [newSegment model])


-- create a new Segment
newSegment : Model -> Segment
newSegment model = 
  let 
    segmentDistanceFromHead = -- how many segments away this new segment is from the head
      Array.length model.segments
  in 
  { point = 
    { x = model.x
    , y = model.y}
    , distanceFromHead = segmentDistanceFromHead
  }

-- update the trail of the snake
updateTrail : Model -> Point -> Array Point
updateTrail model newPoint = 
  let
    maxTrail = maxTrailLength model -- Maximum length that the trail can be
    trailLength = Array.length model.trail -- Current length of the trail
    currentTrail = model.trail 
    newTrailPart = Array.fromList [newPoint] -- New trail point to add
  in 
    if trailLength <= maxTrail then Array.append (currentTrail) (newTrailPart) -- If the trail is shorter than the max, add the new point
   else Array.append (Array.slice 1 trailLength currentTrail) (newTrailPart) -- If the trail is already at the max, remove the oldest point (first value in array) and add the new point

-- maximum length that the trail array can be
maxTrailLength : Model -> Int 
maxTrailLength model = 
  Array.length model.segments

-- Draw a Segment based on its Point data 
drawSegment : Segment -> Shape
drawSegment segment = 
  circle (rgb 255 0 0) 25
   |> fade 0.5
   |> move segment.point.x segment.point.y

-- Update all Segments to match their Point data
updateSegments : Array Segment -> Model -> Array Segment
updateSegments segments model =
  segments |> (Array.map (updateSegment model)) 

-- Update the given Segment to match its Point data
updateSegment : Model -> Segment -> Segment
updateSegment model segment = 
  let 
    -- Which index of the trail array the segment should follow
    trailFollowIndex = 
      (maxTrailLength model) - (segment.distanceFromHead)
  in
  -- Try to get the trail value to follow
  case Array.get trailFollowIndex model.trail of 
    Nothing ->
      {point = segment.point
      , distanceFromHead = segment.distanceFromHead}
    Just aPoint ->
      {point = aPoint
      , distanceFromHead = segment.distanceFromHead}

 -- Don't allow character to move offscreen
inBounds: Float -> Float -> Float -> Bool
inBounds min max x =
    if x > max then
      False
    else if x < min then
      False 
    else
      True

-- Check if snake head collided with apple
collided: Model -> Bool  
collided model = ((hypot(model.x - model.appleX) (model.y - model.appleY) < radius + appleRadius))

-- Returns distance between centers
hypot : Float -> Float -> Float
hypot x y = 
  toPolar (x, y) |> Tuple.first
 





