# Authors: Michelle Dong, May Kinnamon, Lucy Rubin
from tkinter import *
import random
import math
## Referenced: https://prrasad.medium.com/building-a-snake-game-using-python-and-tkinter-a-step-by-step-guide-652ea41d6dd0
MAX_TRAIL_LENGTH = 2
class SnakeGame:
    # Constants
    SPEED = 3 # Speed of the snake movement
    CANVAS_WIDTH = 300
    CANVAS_HEIGHT = 300
    SNAKE_DIAMETER = 20
    APPLE_DIAMETER = 15

    CHUNK_SIZE = 5 # number of circles per segment chunk of the snake body
    
    def __init__(self, root):
        self.root = root
        root.title("Python Game")
        
        # Create canvas widget
        self.canvas = Canvas(root, width=self.CANVAS_WIDTH, height=self.CANVAS_HEIGHT, bg="white")
        self.canvas.pack()

         # Draw snake head in the middle of the canvas
        x0=self.CANVAS_WIDTH / 2
        y0=self.CANVAS_HEIGHT / 2 
        x1=self.CANVAS_WIDTH / 2 + self.SNAKE_DIAMETER 
        y1=self.CANVAS_HEIGHT / 2 - self.SNAKE_DIAMETER

        self.head = Segment(self.canvas, x0, y0, x1, y1)

        # list of all snake segments
        self.snake = [self.head]

        # Apple
        a0=self.CANVAS_WIDTH * 3 / 4
        b0=self.CANVAS_WIDTH * 3 / 4
        a1=self.CANVAS_WIDTH * 3 / 4 + self.APPLE_DIAMETER 
        b1=self.CANVAS_HEIGHT * 3 / 4 - self.APPLE_DIAMETER

        self.apple = Apple(self.canvas, a0, b0, a1, b1)

        # Game loop values
        self.game_over = False
        self.direction = "up" # Direction that the head is moving
        self.delay = 50 # Delay between each frame
        self.tail_length = 0 # number of segment chunks in the body
        self.is_adding_segment = False # currently adding circles for a new segment chunk
        self.num_circles_added = 0 # number of circles added so far for a new segment chunk
        self.has_game_started = False
        
        # Key bindings
        root.bind("<Left>", lambda event: self.set_direction("left"))
        root.bind("<Right>", lambda event: self.set_direction("right"))
        root.bind("<Up>", lambda event: self.set_direction("up"))
        root.bind("<Down>", lambda event: self.set_direction("down"))
        root.bind("<space>", lambda event: self.start_game())

        # Text
        score_label = Label(root, width=20)
        score_label.pack(padx=10, pady=10)

        
        self.start_game_label = self.canvas.create_text(self.CANVAS_WIDTH / 2, self.CANVAS_HEIGHT / 2, text="Press the spacebar to start", fill="black")
        self.canvas.pack()
        
         # Start game
        self.grab_score(score_label)
        self.game_loop()
        
    def start_game(self):
        if not self.has_game_started:
            self.canvas.delete(self.start_game_label)
            self.has_game_started = True

    def grab_score(self, label):
        label.config(text=str(self.tail_length))
        label.after(100, self.grab_score, label)

    def set_direction(self, direction):
        self.direction = direction

    # Move the snake head in its current direction    
    def move(self):
        dx = 0
        dy = 0
        match self.direction: 
            case "left":
                dx = -self.SPEED
            case "right":
                dx = self.SPEED
            case "up":
                dy = -self.SPEED
            case "down": 
                dy = self.SPEED
        self.canvas.move(self.head.segment, dx, dy)
        self.head.update_snake_trail()
        self.head.move_child()
    
    # Add a new segment chunk to the snake
    def add_segment_chunk(self):
        # add multiple circles to the snake which count as one segment
        if self.is_adding_segment and self.num_circles_added < self.CHUNK_SIZE:
            # add a segment to the snake
            old_tail = self.snake[-1]
            
            # make a new segment and put it in the same place as the tail
            x0, y0, x1, y1 = self.canvas.coords(old_tail.segment)
            new_tail = Segment(self.canvas, x0, y0, x1, y1)

            # set up parent and child relationship
            new_tail.set_parent(old_tail)
            old_tail.set_child(new_tail)

            # add segment to the snake
            self.snake.append(new_tail)

            # Keep adding segments
            self.num_circles_added += 1 
            self.add_segment_chunk()
        else: 
            # Stop adding segments
            self.num_circles_added = 0
            self.is_adding_segment = False
    
    # checks for lose condition when the head of the snake hits a wall    
    def check_hit_wall(self):
        snake_x0, snake_y0, snake_x1, snake_y1 = self.canvas.coords(self.head.segment)
        if snake_x0 <= 0 or snake_y0 <= 0 or snake_x1 >= self.CANVAS_WIDTH or snake_y1 >= self.CANVAS_HEIGHT:
            self.game_over = True

    # checks for a lose condition when the head of the snake hits a body segment
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

    def check_eat_apple(self):
        snake_x0, snake_y0, snake_x1, snake_y1 = self.canvas.coords(self.head.segment)
        apple_x0, apple_y0, apple_x1, apple_y1 = self.canvas.coords(self.apple.apple)

        # calculate center coordinates of snake and apple
        snakeCenterX = snake_x0 + self.SNAKE_DIAMETER / 2
        snakeCenterY = snake_y0 + self.SNAKE_DIAMETER / 2
        appleCenterX = apple_x0 + self.APPLE_DIAMETER / 2
        appleCenterY = apple_y0 + self.APPLE_DIAMETER / 2

        # check if the snake head and apple instersect
        if math.dist([snakeCenterX, snakeCenterY], [appleCenterX, appleCenterY]) < self.SNAKE_DIAMETER:
            # calculate new random coordinates for apple
            x0 = random.randrange(self.CANVAS_WIDTH/20, self.CANVAS_WIDTH) - self.CANVAS_WIDTH/20
            y0 = random.randrange(self.CANVAS_HEIGHT/20, self.CANVAS_HEIGHT) - self.CANVAS_HEIGHT/20
            x1 = x0 + self.APPLE_DIAMETER
            y1 = y0 + self.APPLE_DIAMETER

            self.apple.move(x0, y0, x1, y1)

            self.is_adding_segment = True
            self.tail_length += 1
            self.add_segment_chunk()


    def end_game(self):
        self.canvas.create_text(self.CANVAS_WIDTH / 2, self.CANVAS_HEIGHT / 2, text="Game Over", fill='black', font=('Helvetica', 30))

    def game_loop(self):
        if self.has_game_started:
            if not self.game_over:
                self.move()
                self.check_hit_wall()
                self.check_eat_apple()
                self.check_hit_self()
                if not self.game_over:
                    # Loop again
                    self.root.after(self.delay, self.game_loop)
                else:
                    self.end_game()
        else:
            # Loop again
            self.root.after(self.delay, self.game_loop)

class Segment:
    def __init__(self, canvas, x0, y0, x1, y1):
        self.canvas = canvas
        self.segment = canvas.create_oval(x0, y0, x1, y1, fill="green", outline="green")

        self.trail = [] # trail of previous points
        self.parent = None
        self.child = None

    def set_parent(self, parent):
        self.parent = parent # parent segment
    
    def set_child(self, child):
        self.child = child # child segment

    # Add a new coordinate to the trail based on current coordinate
    def update_snake_trail(self):
        # add new coordinate to trail
        self.trail.append(self.canvas.coords(self.segment))

        # don't allow trail to exceed max length
        if len(self.trail) > MAX_TRAIL_LENGTH:
            # remove oldest coord from the trail
            self.trail = self.trail[1:]
    
    def move(self):
        # check if parent has a full trail
        if len(self.parent.trail) == MAX_TRAIL_LENGTH:
            # move to the oldest trail value
            self.canvas.coords(self.segment, self.parent.trail[0])
            self.update_snake_trail()
            
            # Go down the body segments
            self.move_child()

    def move_child(self):
        if self.child:
            self.child.move()

class Apple :
    def __init__(self, canvas, x0, y0, x1, y1):
        self.canvas = canvas

        self.apple = canvas.create_oval(x0, y0, x1, y1, fill="red")

    def move(self, x0, y0, x1, y1):
        self.canvas.coords(self.apple, x0, y0, x1, y1)

# Create window
root = Tk()

# Create game
snake = SnakeGame(root)

# Run the window
root.mainloop()

