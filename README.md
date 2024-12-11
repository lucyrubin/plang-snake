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

There are still `Segment` types in this version, but they are not objects that can be instantiated like in the Python version.
A `Segment` is a type alias for a record:
` type alias Segment = {point: Point, distanceFromHead: Int} `

Each body segment follows the trail of the head segment. The position of the segment is based on its distance from the head. (ex. the 5th segment from the head will be placed at the 5th coordinate in the trail list)

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
When checking whether or not the snake has eaten/collided with the apple object the logic is mostly the same between python and elm but the code looks a bit different. For both python and elm we check whether or not the distance between the center x and y of the apple and the center x and y of the snake head is less than their two radius’ added together. 

### Elm Version
In the Elm version this is very simple. We just take the hypotenuse of the different between x and y values for the snake head and the apple and return true if that distance is less than the two radius’ added together and false if otherwise. 

### Python Version
In Python it looks a little different. Since tkinter determines coordinates of objects based on their upper left corner of the bounding box we need to calculate the center coordinates of the apple and the snake in order to calculate the distance between those two points and check if they are less than  sum of the diameters of the apple and the snake head. 

We also check whether the snake has collided with itself to initiate the game over response in both Elm and Python. 

In the Python version we do something similar to the way we check if it has eaten the apple. First we calculate the center x and y of the snake head then then loop through the list of segments of the snake. On line 123 the first bound on the range make it so that it doesn’t check collision with the first 3 segments. When testing we had some errors with the game immediately ending when adding a new segments because they would initially be added to the canvas to close to the snake head and would then cause the check_hit_self method to initiate the game over response. Within the for loop i


## Random
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
In elm, random is a bit more complicated, our approach technically isn’t random since we are using a seed. Using a seed basically gives a set list of random values that we pull from rather than generating something completely new. 

    ```
    (newRandomX, nextSeedX) = if collidedWithApple model then
                    Random.step (Random.float -300 300) model.seedX
                    else (model.appleX, model.seedX)
    (newRandomY, nextSeedY) = if collidedWithApple model then
                    Random.step (Random.float -300 300) model.seedY
                    else (model.appleY, model.seedY)
    ```

This is because of the purely functional aspect of Elm and how output is purely based on the input. For more on Elm randomness, and something that is more random, it would be interesting to into Elm's Random.Generator 

## Conclusion
We were able to create the Snake Game in both Elm and Python with the same logic, but with different implementations. In writing the Elm version, we did not encounter any runtime errors, only compile-time errors. In writing the Python version, we encountered both runtime and compile-time errors. While the Elm version is more difficult for us to read and write (because we are more unfamiliar with it), it would be easier to implement a pause and resume game function than it would be in the Python version. 
