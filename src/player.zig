const rl = @import("raylib");
const std = @import("std");
const entity = @import("entity.zig");

pub const AttackDir = enum(u4) {
    left = 0b1000,
    right = 0b0100,
    up = 0b0010,
    down = 0b0001,
};

pub const Player = struct {
    dimensions: rl.Vector2,    
    velocity: rl.Vector2,
    transformer: rl.Rectangle,
    prev_pos: rl.Vector2,
    max_horizontal_speed: f32,
    max_vertical_speed: f32,
    max_falling_speed: f32,
    can_jump: bool,

    wall_jump_velocity: rl.Vector2,

    coyote_timer: f32,
    coyote_duration: f32,
    can_swing: bool,

    pub fn init(pos: rl.Vector2, dim: rl.Vector2) @This() {
        return Player {
            .dimensions = dim,
            .velocity = rl.Vector2.zero(),
            .transformer = rl.Rectangle.init(pos.x, pos.y, dim.x, dim.y),  
            .prev_pos = .zero(),
            .max_horizontal_speed = 5,
            .max_vertical_speed = 18,
            .max_falling_speed = 18,
            .can_jump = true,
            .wall_jump_velocity = rl.Vector2.init(10, 5),
            .coyote_timer = 0,
            .coyote_duration = 8,
            .can_swing = true,
        };
    }
    
    pub fn moveBack(self: *Player) void {
        self.transformer.x = self.prev_pos.x;
        self.transformer.y = self.prev_pos.y;
    }

    pub fn handle_input(self: *Player, enviorment: []entity.Entity) void {
        rl.pollInputEvents();

        var player_grounded = false;
        for (enviorment) |e| {
            if (player_grounded) {
                break;
            }
            player_grounded = self.isGrounded(e.rect);
        }

        if (player_grounded) {
            self.coyote_timer = self.coyote_duration;
        } else if (self.coyote_timer > 0) {
            self.coyote_timer -= 1;
        }
        
        //4 bit uint 
        const attack_dir_bits:u4 = if(self.can_swing) 
              @as(u4, @intFromBool(rl.isKeyDown(rl.KeyboardKey.left))) << 3 | 
              @as(u4, @intFromBool(rl.isKeyDown(rl.KeyboardKey.right))) << 2 |  
              @as(u4, @intFromBool(rl.isKeyDown(rl.KeyboardKey.up))) << 1 | 
              @as(u4, @intFromBool(rl.isKeyDown(rl.KeyboardKey.down)))
        else 0b0000;
        
        //this should go in the opposite direction of attack
        var attack_vec = rl.Vector2.zero();
        std.debug.print("{}", .{attack_dir_bits}); 
        const sword_height = 5;
        const sword_width = 10;
        const sword_offset = 5;
        const sword_rect:?rl.Rectangle = switch(attack_dir_bits) {
            @intFromEnum(AttackDir.left) => left: { 
                attack_vec.x = 1;
                attack_vec.y = 0;

                break :left rl.Rectangle {
                    .x = self.transformer.x - sword_offset ,
                    .y = self.transformer.y + self.transformer.height/2,
                    .height = sword_height,
                    .width = sword_width,
                };
            },
            @intFromEnum(AttackDir.right) => right: {
                attack_vec.x = -1;
                attack_vec.y = 0;

                break :right rl.Rectangle {
                    .x = self.transformer.x + sword_offset + self.transformer.width ,
                    .y = self.transformer.y + self.transformer.height/2,
                    .height = sword_height,
                    .width = sword_width,
                };
            },
            @intFromEnum(AttackDir.down) => down: {
                attack_vec.x = 0;
                attack_vec.y = -1;

                break :down rl.Rectangle {
                    .x = self.transformer.x + self.transformer.width/2,
                    .y = self.transformer.y + sword_offset + self.transformer.height,
                    .height = sword_width,
                    .width = sword_height,
                };
            },
            @intFromEnum(AttackDir.up) => up: {
                attack_vec.y = 1;
                attack_vec.x = 0;

                break :up rl.Rectangle {
                    .x = self.transformer.x + self.transformer.width/2,
                    .y = self.transformer.y - sword_offset,
                    .height = sword_width,
                    .width = sword_height,
                };
            },
            else => none: {
                break :none null;
            }
        };

        
        var hit_entity: ?entity.Entity = null;

        if (sword_rect) |rect| {

            rl.drawRectangleRec(rect, rl.Color.dark_gray);
            for (enviorment) |e| {
                if (rect.checkCollision(e.rect)) {
                    hit_entity = e;
                }
            }
        }

        if (hit_entity) |e| {
            if (e.tag == .Enemy or e.tag == .Projectile) {
                attack_vec = attack_vec.scale(25);
                self.velocity = self.velocity.add(attack_vec);
            }
        }


        const can_coyote_jump = self.coyote_timer > 0 and self.velocity.y >= 0;

        const player_fall_speed:f32 = self.max_vertical_speed;
        const player_horizontal_speed: f32 = self.max_horizontal_speed;

        const onWall = self.isTouchingWall(enviorment);
        //std.debug.print("grounded: {}, velocity: {}, onWall: {}\n", .{player_grounded, self.velocity, onWall});

        if (rl.isKeyDown(rl.KeyboardKey.space) and can_coyote_jump and self.can_jump) {
            self.velocity.y += -17.0;
            self.can_jump = false;
            self.coyote_timer = 0;
        }

        if(rl.isKeyDown(rl.KeyboardKey.a)) {
            if (onWall[0]) {
                self.max_vertical_speed = 3; 
            }

            if (onWall[0] and rl.isKeyDown(rl.KeyboardKey.space) and self.can_jump) {
                self.max_vertical_speed *= 2;

                self.velocity.y += -2*self.wall_jump_velocity.y;
                self.max_horizontal_speed *= 4;
                self.velocity.x += 2*self.wall_jump_velocity.x;
                self.can_jump = false;
                self.transformer.x += 1;
            } else {
                self.velocity.x -= 1.4;
            }         
        }
        if(rl.isKeyDown(rl.KeyboardKey.d)) {
            if (onWall[1]) {
                self.max_vertical_speed = 3; 
            }

            if (onWall[1] and rl.isKeyDown(rl.KeyboardKey.space) and self.can_jump) {
                self.max_vertical_speed *= 2;

                self.velocity.y += -self.wall_jump_velocity.y;
                self.max_horizontal_speed *= 4;
                self.velocity.x -= self.wall_jump_velocity.x;
                self.can_jump = false;
                self.transformer.x -= 1;
            }else {
                self.velocity.x += 1.4;
            } 
        }

        self.velocity.y += 1.3;
        self.move(enviorment);
        self.max_horizontal_speed = player_horizontal_speed;
        self.max_vertical_speed = player_fall_speed;
        
        self.can_jump = rl.isKeyUp(rl.KeyboardKey.space) or self.can_jump;
        self.can_swing = rl.isKeyUp(rl.KeyboardKey.left)  and 
                         rl.isKeyUp(rl.KeyboardKey.right) and 
                         rl.isKeyUp(rl.KeyboardKey.up)    and 
                         rl.isKeyUp(rl.KeyboardKey.down); 
    }

    pub fn move(self: *Player, colliders: []entity.Entity) void {
        const friction: f32 = 1.0;

        self.prev_pos.x = self.transformer.x;
        self.prev_pos.y = self.transformer.y;
        
        self.transformer.x += self.velocity.x;
        for (colliders) |collider| {
            if (self.transformer.checkCollision(collider.rect)) {
                self.transformer.x = self.prev_pos.x;
                self.velocity.x = 0;
                break;
            }
        }

        self.transformer.y += self.velocity.y;
        for (colliders) |collider| {
            if (self.transformer.checkCollision(collider.rect)) {
                self.transformer.y = self.prev_pos.y;
                self.velocity.y = 0;
                break;
            }
        }

        if (self.velocity.x > 0) {
            self.velocity.x -= friction;
            self.velocity.x = std.math.clamp(self.velocity.x, 0, self.max_horizontal_speed);
        } else if (self.velocity.x < 0) {
            self.velocity.x += friction;
            if (self.velocity.x > 0) self.velocity.x = 0;
            self.velocity.x = std.math.clamp(self.velocity.x, -self.max_horizontal_speed, 0);
        }

        self.velocity.y = std.math.clamp(self.velocity.y, -self.max_falling_speed, self.max_vertical_speed);
    }

    
    pub fn isTouchingWall(self: @This(), enviroment: []entity.Entity) struct {bool, bool} {
        const hand_height = 10;
        const lHand = rl.Rectangle {
            .x = self.transformer.x - 2,
            .y = self.transformer.y + self.transformer.height/2,
            .width = 1,
            .height = hand_height
        };

        const rHand = rl.Rectangle {
            .x = self.transformer.x + self.transformer.width + 1,
            .y = self.transformer.y + self.transformer.height/2,
            .width = 1,
            .height = hand_height
        };
        rl.drawRectangleRec(lHand, rl.Color.red);
        rl.drawRectangleRec(rHand, rl.Color.green);

        var lHandWall = false;
        var rHandWall = false;

        for (enviroment) |place| {
            if (!lHandWall) {
                lHandWall = lHand.checkCollision(place.rect);
            }
            if (!rHandWall) {
                rHandWall = rHand.checkCollision(place.rect);
            }
        }

        return .{lHandWall, rHandWall};
    }

    pub fn isGrounded(self: @This(), floor: rl.Rectangle) bool {
        const foot = rl.Rectangle {
            .x = self.transformer.x,
            .y = self.transformer.y + self.transformer.height + 3,
            .width = self.transformer.width,
            .height = 1,
        };

        rl.drawRectangleRec(foot, rl.Color.green);
        return foot.checkCollision(floor);
    }

    pub fn draw(self: @This()) void {
        rl.drawRectangleRec(self.transformer, rl.Color.red);
    }
};
