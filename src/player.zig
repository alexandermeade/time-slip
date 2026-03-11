const rl = @import("raylib");
const std = @import("std");

pub const Player = struct {
    dimensions: rl.Vector2,    
    velocity: rl.Vector2,
    transformer: rl.Rectangle,
    prev_pos: rl.Vector2,
    max_horizontal_speed: f32,
    max_vertical_speed: f32,
    max_falling_speed: f32,

    pub fn init(pos: rl.Vector2, dim: rl.Vector2) @This() {
        return Player {
            .dimensions = dim,
            .velocity = rl.Vector2.zero(),
            .transformer = rl.Rectangle.init(pos.x, pos.y, dim.x, dim.y),  
            .prev_pos = .zero(),
            .max_horizontal_speed = 4,
            .max_vertical_speed = 4,
            .max_falling_speed = 9,
        };
    }
    
    pub fn moveBack(self: *Player) void {
        self.transformer.x = self.prev_pos.x;
        self.transformer.y = self.prev_pos.y;
    }

    pub fn move(self: *Player, collider: rl.Rectangle) void {
        const friction: i32 = 1;

        self.prev_pos.x = self.transformer.x;
        self.prev_pos.y = self.transformer.y;

        self.transformer.x += self.velocity.x;

        if (self.transformer.checkCollision(collider)) {
            self.transformer.x = self.prev_pos.x;
            self.velocity.x = 0;
        }

        self.transformer.y += self.velocity.y;

        if (self.transformer.checkCollision(collider)) {
            self.transformer.y = self.prev_pos.y;
            self.velocity.y = 0;
        }

        //apply friction
        if (self.velocity.x > 0) {
            self.velocity.x -= friction;
            self.velocity.x = std.math.clamp(self.velocity.x, 0, self.max_horizontal_speed);
        } else if (self.velocity.x < 0) {
            self.velocity.x += friction;
            if (self.velocity.x > 0) self.velocity.x = 0;
        }

        if (self.velocity.y > 0) {
            self.velocity.y -= friction;
            self.velocity.y = std.math.clamp(self.velocity.y, 0, self.max_falling_speed);
        } else if (self.velocity.y < 0) {
            self.velocity.y += friction;
            if (self.velocity.y > 0) self.velocity.y = 0;
        }
    }

    pub fn isGrounded(self: @This(), floor: rl.Rectangle) bool {
        const foot = rl.Rectangle {
            .x = self.transformer.x,
            .y = self.transformer.y + self.transformer.height + 1,
            .width = 1,
            .height = 1,
        };

        return foot.checkCollision(floor);
    }

    pub fn draw(self: @This()) void {
        rl.drawRectangleRec(self.transformer, rl.Color.red);
    }
};
