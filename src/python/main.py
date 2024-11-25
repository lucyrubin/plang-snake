from tkinter import *
import random
import math
## Referenced: https://prrasad.medium.com/building-a-snake-game-using-python-and-tkinter-a-step-by-step-guide-652ea41d6dd0
MAX_TRAIL_LENGTH = 5
class SnakeGame:
    # Constants
    SPEED = 3
    CANVAS_WIDTH = 300
    CANVAS_HEIGHT = 300
    SNAKE_DIAMETER = 20
    APPLE_DIAMETER = 15
    
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

        a0=self.CANVAS_WIDTH * 3 / 4
        b0=self.CANVAS_WIDTH * 3 / 4
        a1=self.CANVAS_WIDTH * 3 / 4 + self.APPLE_DIAMETER 
        b1=self.CANVAS_HEIGHT * 3 / 4 - self.APPLE_DIAMETER



        self.head = Segment(self.canvas, x0, y0, x1, y1, isHead=True)

        # list of all snake segments
        self.snake = [self.head]

        # apple
        self.apple = Apple(self.canvas, a0, b0, a1, b1)

        # Game loop values
        self.game_over = False
        self.direction = "up"
        self.delay = 50
        self.tail_length = 1
        
        # Key bindings
        root.bind("<Left>", lambda event: self.set_direction("left"))
        root.bind("<Right>", lambda event: self.set_direction("right"))
        root.bind("<Up>", lambda event: self.set_direction("up"))
        root.bind("<Down>", lambda event: self.set_direction("down"))

        # Start game
        self.game_loop()
        
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
    
    # add a new segment to the snake
    def add_segment(self):
        old_tail = self.snake[-1]
        
        # make a new segment and put it in the same place as the tail
        x0, y0, x1, y1 = self.canvas.coords(old_tail.segment)
        new_tail = Segment(self.canvas, x0, y0, x1, y1, isHead=False)

        new_tail.set_parent(old_tail)
        old_tail.set_child(new_tail)

        self.snake.append(new_tail)
        
    def check_hit_wall(self):
        snake_x0, snake_y0, snake_x1, snake_y1 = self.canvas.coords(self.head.segment)
        if snake_x0 <= 0 or snake_y0 <= 0 or snake_x1 >= self.CANVAS_WIDTH or snake_y1 >= self.CANVAS_HEIGHT:
            self.game_over = True

    def check_hit_self(self):
        snake_x0, snake_y0, snake_x1, snake_y1 = self.canvas.coords(self.head.segment)
        headCenterX = snake_x0 + self.SNAKE_DIAMETER
        headCenterY = snake_y0 + self.SNAKE_DIAMETER

        # checks for intersection with snake segments but skips the first 4 segments
        for i in range(4 , len(self.snake)):
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
            self.head.eat_apple()

            # calculate new random coordinates for apple
            x0 = random.randrange(self.CANVAS_WIDTH/20, self.CANVAS_WIDTH) - self.CANVAS_WIDTH/20
            y0 = random.randrange(self.CANVAS_HEIGHT/20, self.CANVAS_HEIGHT) - self.CANVAS_HEIGHT/20
            x1 = x0 + self.APPLE_DIAMETER
            y1 = y0 + self.APPLE_DIAMETER

            self.apple.move(x0, y0, x1, y1)
            self.add_segment()


    def end_game(self):
        self.canvas.create_text(self.CANVAS_WIDTH / 2, self.CANVAS_HEIGHT / 2, text="Dead", fill='black', font=('Helvetica', 30))

    def game_loop(self):
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

class Segment:
    def __init__(self, canvas, x0, y0, x1, y1, isHead):
        self.canvas = canvas

        if isHead:
            self.segment = canvas.create_oval(x0, y0, x1, y1, fill="pink")
        else:
            self.segment = canvas.create_oval(x0, y0, x1, y1, fill="blue")

        self.trail = [] # trail of previous points
        self.isHead = isHead
        self.parent = None
        self.child = None
        self.apples = 0

    def set_parent(self, parent):
        self.parent = parent
    
    def set_child(self, child):
        self.child = child

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

            self.move_child()

    def move_child(self):
        if self.child:
            self.child.move()
    
    def eat_apple(self):
        self.apples = self.apples + 1


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

