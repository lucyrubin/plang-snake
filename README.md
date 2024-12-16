# Running:
To run elm version: elm-live --open -- src/Main.elm --output=elm.js in the plang-snake directory


## Introduction

We implemented the classic Snake Game in both Elm and Python. Elm is a purely functional language, while Python is object oriented. We used the same general structure and logic for both versions, but implemented them differently. We then looked at the differences between the two implementations:  


## General Structure
Both versions of the snake game are made up of the same general structure. 

Snake is made up of a list of segments, where the head is the leader and has its own properties. 

**Head segment:**
- Has a direction (left, right, up, down)
- Each frame, the head moves in its direction
- The direction can be changed with the arrow keys
- Head segment is attached to body 
- Head can collide with apple, body, and walls

**Body segments:**
- Each frame, each segment checks if it has collided with head segment 
- All body segments follow the path of the head
- Each body segment is made up of multiple circles, resulting in a smooth animation

**Apple:**
- Checks each frame for a collision with the head
- After collided goes to a new random coordinate on the screen


## Snake body movement
### Python Version:
We used object oriented programming to implement the movement of the snake’s body. 

Each part of the snake (including the head) is a `Segment`, which has a trail, a parent `Segment`, and a child `Segment`.

Every frame, a segment updates its trail, which contains its most recent two locations. 
```
def update_snake_trail(self):
       # add new coordinate to trail
       self.trail.append(self.canvas.coords(self.segment))


       # don't allow trail to exceed max length
       if len(self.trail) > MAX_TRAIL_LENGTH:
           # remove oldest coord from the trail
           self.trail = self.trail[1:]
```

Every frame, the head 'Segment' moves. It then tells its child segment to move as well. It will move to its parent’s (the head in this case) oldest trail value. That child segment then tells its child to move as well, and the movement travels down the snake body. 

```
def move(self):
       # check if parent has a full trail
       if len(self.parent.trail) == MAX_TRAIL_LENGTH:
           # move to the oldest trail value
           self.canvas.coords(self.segment, self.parent.trail[0])
           self.update_snake_trail()
           self.move_child()

   def move_child(self):
       if self.child:
           self.child.move()
```


### Elm Version:
We did not use objects to implement the movement of the snake’s body. Although the implementation is different, the behavior is the same as the Python version. 

Because Elm is purely functional, we could not create segment objects that have parent and child relationships. Pure functions cannot have external effects on anything, and parent/child relationships would violate that rule. 

Within the snake’s model are values for:
- x and y coordinates of the head
- count of number of apples eaten
- array of segments
- an array of recent trail coordinates

```
type alias Model = 
  {
    x : Float -- x coordinate of the head
    , y : Float -- y coordinate of the head
    ...
    , tailLength : Int -- number of segment chunks in the body
    ...
    , segments : Array Segment -- all body segments
    , head : Segment -- head segment
    , trail: Array Point
    ...
  }
 ```

There are still `Segment` types in this version, but they are not objects that can be instantiated like in the Python version, instead it is a piece of immutable data.
A `Segment` is a type alias for a record:
` type alias Segment = {point: Point, distanceFromHead: Int} `

Each body segment follows the trail of the head segment. The position of the segment is based on its distance from the head. (ex. the 5th segment from the head will be placed at the 5th coordinate in the trail list)

Each frame, segments are updated based on the previous game state:

```
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
```

Segments are drawn each frame based on their data
```
-- Draw a Segment based on its Point data
drawSegment : Segment -> Shape
drawSegment segment =
 circle (rgb 255 255 0) 25
  |> fade 0.5
  |> move segment.point.x segment.point.y
```

## Collisions
When checking whether or not the snake has eaten/collided with the apple object the logic is mostly the same between python and elm but the code looks a bit different due to the natue of the languages and the way we had to set up our code. 

### Collisions with Apple
#### Elm Version
In the Elm version (like Python) the coordinates of the apple and head of the snake are taken to caculate the distance between the two. If the distance is less than both radius' then the counter must be increased and the apple must spawn in a new location. 

In the function that checks whether the snake has eaten the apple, we had to pass the function the model itself so that we wer able to refer back to changing variables in our code because of Elm's pure functions.

```
collidedWithApple: Model -> Bool  
collidedWithApple model = ((hypot(model.x - model.appleX) (model.y - model.appleY) < radius + appleRadius))
```

When changing the eaten apple counter in Elm, we had to create a new variable newTailLength that checked this function and was set to the previous tailLength + 1. Then we set tailLength to newTailLength in update. The same thing happens with the coordinates of the new apple by creating a new variable and setting the old variable to the new one.

```
newTailLength = if collidedWithApple model then model.tailLength + 1 else model.tailLength -- if snake ate an apple, increase the tail length
```

```
, tailLength = newTailLength
```


#### Python Version
In Python the process of checking whether the coordinates are close enough to have intersected is essentailly the same. However when it comes to changing the apple counter and the placement of the apple things look a bit different. The process of moving the apple is very different. In Python we made the apple its own object and gave it parameters for the new random x and y corrdinates. The apple object then had its own method that changed its position on the screen. Additionally we could change the tail_length (apples eaten) inside of this method which is not something we could have done in Elm!
```
def check_eat_apple(self):
    ...
    if math.dist([snakeCenterX, snakeCenterY], [appleCenterX, appleCenterY]) < self.SNAKE_DIAMETER/2 + self.APPLE_DIAMETER/2:
            # calculate new random coordinates for apple
            x0 = random.randrange(self.CANVAS_WIDTH/20, self.CANVAS_WIDTH) - self.CANVAS_WIDTH/20
            y0 = random.randrange(self.CANVAS_HEIGHT/20, self.CANVAS_HEIGHT) - self.CANVAS_HEIGHT/20
            x1 = x0 + self.APPLE_DIAMETER
            y1 = y0 + self.APPLE_DIAMETER

            self.apple.move(x0, y0, x1, y1)

            self.is_adding_segment = True
            self.tail_length += 1
            self.add_segment_chunk() 
```

### Collisions with Self
#### Python Version
The way we check whether or not the snake has collided with itself is very simple in python and is essentially the same as checking whether the snake has eaten the apple. We loop over every segment in the snake (skipping the first couple or segements) and check if it intersects with the head. Then we can set gameOver to be true which causes other game over responses. 

```
def check_hit_self(self):
    snake_x0, snake_y0, snake_x1, snake_y1 = self.canvas.coords(self.head.segment)
    headCenterX = snake_x0 + self.SNAKE_DIAMETER
    headCenterY = snake_y0 + self.SNAKE_DIAMETER

    # checks for intersection with snake segments but skips the first few segments
    for i in range(self.CHUNK_SIZE * 3 , len(self.snake)):
        s = self.snake[i]
        segment_x0, segment_y0, segment_x1, segment_y1 = self.canvas.coords(s.segment)
        segmentCenterX = segment_x0 + self.SNAKE_DIAMETER
        segmentCenterY = segment_y0 + self.SNAKE_DIAMETER
        if math.dist([headCenterX, headCenterY], [segmentCenterX, segmentCenterY]) < self.SNAKE_DIAMETER:
            self.game_over = True
```

### Elm Version

In elm this looks a little different. We again create a new variable newBumpSelf that is set to either the result of the checkSegments function or false if the snake is dead. 

```
    newBumpSelf = if model.isAlive then 
        checkSegments model.segments model -- checks whether any of the body segments bumps with head
      else
        True
```

We would expect the function to use a loop to check each body segement and stop when it reached a case where the segement and head collided, however instead we used map to create an array that held true and false values for whether or not each of the segements (skipping the first few) had collided with the head. The function then returns true if any of the values in the array are true. The result of this function was then set as the value of the newBumpSelf variable which was set to bumpSelf in update.

```
-- Calls the collidedSelf method on all segments, if the segments not originally touching the head bumps with head, return True
checkSegments segments model = 
  segments |> (Array.map (collidedSelf model)) |> Array.slice 30 -1 |> Array.any (\x -> x == True)
 
-- Check if self(single segment) collided with head
collidedSelf model segment = 
  ((hypot(model.x - segment.point.x) (model.y -  segment.point.y) < radius + appleRadius))
```

## Random

We use random when we want to update the coordinates of the apple. 

### Python Version
Python random is just 'random.randrange'
```
x0 = random.randrange(self.CANVAS_WIDTH/20, self.CANVAS_WIDTH) - self.CANVAS_WIDTH/20
           y0 = random.randrange(self.CANVAS_HEIGHT/20, self.CANVAS_HEIGHT) - self.CANVAS_HEIGHT/20
           x1 = x0 + self.APPLE_DIAMETER
           y1 = y0 + self.APPLE_DIAMETER

           self.apple.move(x0, y0, x1, y1)
```

### Elm Version
In elm, random is a bit more complicated. As a purely functional language, given the same input, it can only have one output. If we want random results, our outputs would not be the same for the same inputs. To make random "pure", our approach to random is "pseudo-random" since we are using a seed. Using a seed basically gives a predefined "random" value. Using Random.step, we would get a new "random" seed, to generate a new "random" value. 

"random" is in quotes because for the same seed, the value returned will always be the same and the new "random" seed generated is also the same. This means that everytime you play the game, the apple will always follow the same path.

```
(newRandomX, nextSeedX) = if collidedWithApple model then
                Random.step (Random.float -300 300) model.seedX
                else (model.appleX, model.seedX)
(newRandomY, nextSeedY) = if collidedWithApple model then
                Random.step (Random.float -300 300) model.seedY
                else (model.appleY, model.seedY)
```

We used this approach since it was easier to understand and implement. An alternative method for random in Elm is Elm Random.Generator; this method will handle the seeds so that it feels more random and you could also combine the function with different mappings. 

## Conclusion
We were able to create the Snake Game in both Elm and Python with the same logic, but with different implementations. 

Besides the differences mentioned previously, when it comes to implementing the game in Elm, we noticed that it was much more difficult to do two things at once. For example, when we checked for collision with self, we needed a complete step for returning a boolean, and then another step for setting the boolean to end the game; whereas in python, we could directly end the game. This is related to the immutability of functional programming and is something we had to get used to. 

With Elm, other aspects we had to get used to was being more aware of types and if-statements always needing an "else". 

In writing the Elm version, we did not encounter any runtime errors, only compile-time errors. This is because of its pure functions which cannot have any external effects. In writing the Python version, we encountered both runtime and compile-time errors. The Elm version is more difficult for us to read and write (in part because we are more unfamiliar with it). However, was more difficult to debug the Python version because of runtime errors. Once we could get Elm to compile, we no longer had to worry about runtime errors. It it would be easier to implement a pause and resume game function in Elm than it would be in Python, but other new game functions that require code reorganization would likely be easier to implement in Python. 
