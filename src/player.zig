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
            .max_horizontal_speed = 5,
            .max_vertical_speed = 18,
            .max_falling_speed = 18,
        };
    }
    
    pub fn moveBack(self: *Player) void {
        self.transformer.x = self.prev_pos.x;
        self.transformer.y = self.prev_pos.y;
    }

    pub fn move(self: *Player, colliders: std.ArrayList(rl.Rectangle)) void {
        const friction: f32 = 1.0;

        self.prev_pos.x = self.transformer.x;
        self.prev_pos.y = self.transformer.y;

        // Move horizontally
        self.transformer.x += self.velocity.x;
        for (colliders.items) |collider| {
            if (self.transformer.checkCollision(collider)) {
                self.transformer.x = self.prev_pos.x;
                self.velocity.x = 0;
                break; // stop checking further collisions on X
            }
        }

        // Move vertically
        self.transformer.y += self.velocity.y;
        for (colliders.items) |collider| {
            if (self.transformer.checkCollision(collider)) {
                self.transformer.y = self.prev_pos.y;
                self.velocity.y = 0;
                break; // stop checking further collisions on Y
            }
        }

        // Apply friction horizontally
        if (self.velocity.x > 0) {
            self.velocity.x -= friction;
            self.velocity.x = std.math.clamp(self.velocity.x, 0, self.max_horizontal_speed);
        } else if (self.velocity.x < 0) {
            self.velocity.x += friction;
            if (self.velocity.x > 0) self.velocity.x = 0;
            self.velocity.x = std.math.clamp(self.velocity.x, -self.max_horizontal_speed, 0);
        }

        // Limit vertical speed
        self.velocity.y = std.math.clamp(self.velocity.y, -self.max_falling_speed, self.max_vertical_speed);
    }
    
    pub fn isTouchingWall(self: @This(), enviroment: []rl.Rectangle) struct {bool, bool} {
        const lHand = rl.Rectangle {
            .x = self.transformer.x - self.transformer.width/2 - 1,
            .y = self.transformer.y + self.transformer.height/2,
            .width = 1,
            .height = 2
        };

        const rHand = rl.Rectangle {
            .x = self.transformer.x + self.transformer.width + 1,
            .y = self.transformer.y + self.transformer.height/2,
            .width = 1,
            .height = 2
        };
        rl.drawRectangleRec(lHand, rl.Color.red);

        rl.drawRectangleRec(rHand, rl.Color.green);

        var lHandWall = false;
        var rHandWall = false;

        for (enviroment) |place| {
            if (!lHandWall) {
                lHandWall = lHand.checkCollision(place);
            }
            if (!rHandWall) {
                rHandWall = rHand.checkCollision(place);
            }
        }

        return .{lHandWall, rHandWall};
    }

    pub fn isGrounded(self: @This(), floor: rl.Rectangle) bool {
        const foot = rl.Rectangle {
            .x = self.transformer.x + self.transformer.width/2,
            .y = self.transformer.y + self.transformer.height + 3,
            .width = 3,
            .height = 1,
        };

        rl.drawRectangleRec(foot, rl.Color.green);

        return foot.checkCollision(floor);
    }

    pub fn draw(self: @This()) void {
        rl.drawRectangleRec(self.transformer, rl.Color.red);
    }
};
