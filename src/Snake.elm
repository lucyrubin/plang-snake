-- Authors: Michelle Dong, May Kinnamon, Lucy Rubin
module Snake exposing (game)

import Playground exposing (..)
import Random
import Array exposing (Array)
import Array.Extra as Array

-- CONSTANTS
movementSpeed : Float -- Speed of the snake movement
movementSpeed = 2

radius : Float -- Radius of a snake segment
radius = 25 
appleRadius : Float -- Radius of the apple circle
appleRadius = 15

chunkSize : Int -- number of circles per segment chunk of the snake body
chunkSize = 10

-- MAIN
game =
  { initialState = initialState
  , updateState = update
  , view = view
  }

type alias Model = 
  {
    x : Float -- x coordinate of the head
    , y : Float -- y coordinate of the head
    , dir : Direction -- Direction that the head is moving
    , isAlive : Bool -- Whether or not the snake has dies
    , tailLength : Int -- number of segment chunks in the body
    , appleX : Float -- x coordinate of the apple
    , appleY : Float -- y coordinate of the apple
    , segments : Array Segment -- all body segments
    , head : Segment -- head segment
    , trail: Array Point -- list of the head's past Points
    , isAddingSegment: Bool -- currently adding circles for a new segment chunk
    , numAdded: Int -- number of circles added so far for a new segment chunk
    , seedX : Random.Seed
    , seedY : Random.Seed
    , bumpSelf : Bool
    , hasGameStarted : Bool 
  }

initialState : Model  
initialState =
  { x = 0
  , y = 0
  , dir = Left
  , isAlive = True
  , tailLength = 0 
  , segments = Array.empty
  , head = {point = {x= 0, y= 0}, distanceFromHead = 0}
  , trail = Array.empty
  , isAddingSegment = False
  , numAdded = 0
  , seedX = Random.initialSeed 12345
  , seedY = Random.initialSeed 55105
  , appleX = 50
  , appleY = 50
  , bumpSelf = False
  , hasGameStarted = False
  }

type Direction = Left | Right | Up | Down

type alias Point = {x: Float, y: Float}

type alias Segment = {point: Point, distanceFromHead: Int} -- A segment has a Point (coordinate) and a distance from the head. Ex, the 5th body segment has a distanceFromHead of 5

-- VIEW

view computer model =

  (Array.toList (model.segments) |> List.map drawSegment) -- for eeach segment in model.segments, call drawSegment on it
  ++
  [ 
    if not model.hasGameStarted then
    words black "Press the spacebar to start"
    else if model.isAlive then
    circle (rgb 0 255 0) radius  -- draw the head of the snake according to its position data
      |> move model.x model.y
    else 
    words black "Game Over" -- draw game over text

    , circle (rgb 255 0 0) appleRadius -- draw the apple according to its position data
      |> move model.appleX model.appleY
    , words black (String.fromInt model.tailLength) -- draw the current score
      |> move 300 300
  ] 
    
-- UPDATE

update computer model =
  let
    newY = -- calculate the new head y position based on the current direction
        (if model.dir == Up then model.y + movementSpeed else 
        if model.dir == Down then model.y - movementSpeed else model.y)
    newX =  -- calculate the new head x position based on the current direction
        (if model.dir == Right then model.x + movementSpeed else 
        if model.dir == Left then model.x - movementSpeed else model.x)
    newDir = -- update the direction based on user input
        if computer.keyboard.right then Right
        else if computer.keyboard.left then Left
        else if computer.keyboard.up then Up
        else if computer.keyboard.down then Down
        else model.dir
    newTailLength = if collidedWithApple model then model.tailLength + 1 else model.tailLength -- if snake ate an apple, increase the tail length
    (newRandomX, nextSeedX) = if collidedWithApple model then
                    Random.step (Random.float -300 300) model.seedX
                    else (model.appleX, model.seedX)
    (newRandomY, nextSeedY) = if collidedWithApple model then
                    Random.step (Random.float -300 300) model.seedY
                    else (model.appleY, model.seedY)
    newTrail = updateTrail model {x= newX, y= newY} -- update the trail with the new head coordinates

    newIsAddingSegment = if collidedWithApple model then True  -- Add multiple new segments instead of one so that they are easier to see
      else if model.isAddingSegment && model.numAdded < chunkSize then True
      else False
    newNumAdded = if model.isAddingSegment then model.numAdded + 1 -- Number of new segments added to the current chunk
      else 0
    newSegments = 
      if  model.isAddingSegment then updateSegments (addNewSegment model) model -- create a new segment and add it to the model
      else updateSegments model.segments model
    newBumpSelf = if model.isAlive then 
        checkSegments model.segments model
      else
        True
    newHasGameStarted = if model.hasGameStarted then True 
      else if computer.keyboard.space then True 
      else False
  in
    { model
      | x = newX
      , y = newY
      , dir = newDir
      , isAlive = inBounds (computer.screen.left + (radius)) (computer.screen.right - (radius)) model.x && inBounds (computer.screen.bottom + (radius)) (computer.screen.top - (radius)) model.y && model.isAlive && (not newBumpSelf)
      , tailLength = newTailLength
      , segments = newSegments
      , head = model.head
      , trail = newTrail
      , isAddingSegment = newIsAddingSegment
      , numAdded = newNumAdded
      , appleX = newRandomX
      , seedX = nextSeedX
      , appleY = newRandomY
      , seedY = nextSeedY
      , bumpSelf = newBumpSelf
      , hasGameStarted = newHasGameStarted
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
  circle (rgb 0 255 0) 25
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
collidedWithApple: Model -> Bool  
collidedWithApple model = ((hypot(model.x - model.appleX) (model.y - model.appleY) < radius + appleRadius))

-- Taken from Paul's Asteroid Game 
-- Returns distance between centers
hypot : Float -> Float -> Float
hypot x y = 
  toPolar (x, y) |> Tuple.first

checkSegments segments model = 
  segments |> (Array.map (collidedSelf model)) |> Array.slice 30 -1 |> Array.any (\x -> x == True)
 
-- Check if self(segment) collided with head
collidedSelf model segment = 
  ((hypot(model.x - segment.point.x) (model.y -  segment.point.y) < radius + appleRadius))
