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

    dash_velocity: f32,
    dash_timer: f32,
    dash_duration: f32,
    dash_cooldown_timer: f32,
    dash_cooldown: f32,
    is_dashing: bool,
    dash_dir: f32,
    player_sprite: rl.Texture,

    pub fn init(pos: rl.Vector2, dim: rl.Vector2) !@This() {
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
            .dash_velocity = 18,
            .dash_timer = 0,
            .dash_duration = 12,
            .dash_cooldown_timer = 0,
            .dash_cooldown = 40,
            .is_dashing = false,
            .dash_dir = 1,
            .player_sprite = try rl.Texture2D.init("./assets/player.png"), 
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
            
            
            if (self.velocity.y > 0) self.velocity.y = 0;
        } else if (self.coyote_timer > 0) {
            self.coyote_timer -= 1;
        }

        
        if (self.dash_cooldown_timer > 0) self.dash_cooldown_timer -= 1;

        
        if (rl.isKeyDown(rl.KeyboardKey.a)) self.dash_dir = -1;
        if (rl.isKeyDown(rl.KeyboardKey.d)) self.dash_dir =  1;

        
        if (rl.isKeyDown(rl.KeyboardKey.left_shift) and
            !self.is_dashing and
            self.dash_cooldown_timer <= 0) {
            self.is_dashing = true;
            self.dash_timer = self.dash_duration;
            self.velocity.x = self.dash_velocity * self.dash_dir;
            self.velocity.y = 0; 
        }

        
        if (self.is_dashing) {
            self.velocity.x = self.dash_velocity * self.dash_dir;
            self.velocity.y = 0;
            self.dash_timer -= 1;
            if (self.dash_timer <= 0) {
                self.is_dashing = false;
                self.dash_cooldown_timer = self.dash_cooldown;
                
                self.velocity.x = self.dash_dir * self.max_horizontal_speed;
            }
        }

        const attack_dir_bits:u4 = if(self.can_swing) 
              @as(u4, @intFromBool(rl.isKeyDown(rl.KeyboardKey.left))) << 3 | 
              @as(u4, @intFromBool(rl.isKeyDown(rl.KeyboardKey.right))) << 2 |  
              @as(u4, @intFromBool(rl.isKeyDown(rl.KeyboardKey.up))) << 1 | 
              @as(u4, @intFromBool(rl.isKeyDown(rl.KeyboardKey.down)))
        else 0b0000;
        
        
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

        if (!self.is_dashing) {
            const can_coyote_jump = self.coyote_timer > 0 and self.velocity.y >= 0;
            const onWall = self.isTouchingWall(enviorment);

            if (rl.isKeyDown(rl.KeyboardKey.space) and can_coyote_jump and self.can_jump) {
                
                self.velocity.y = -17.0;
                self.can_jump = false;
                self.coyote_timer = 0;
            }

            if(rl.isKeyDown(rl.KeyboardKey.a)) {
                if (onWall[0] and rl.isKeyDown(rl.KeyboardKey.space) and self.can_jump) {
                    self.velocity.y  = -self.wall_jump_velocity.y * 2;
                    self.velocity.x  =  self.wall_jump_velocity.x * 2;
                    self.can_jump = false;
                    self.transformer.x += 1;
                } else {
                    self.velocity.x -= 1.4;
                    
                    if (onWall[0] and self.velocity.y > 3) self.velocity.y = 3;
                }
            }

            if(rl.isKeyDown(rl.KeyboardKey.d)) {
                if (onWall[1] and rl.isKeyDown(rl.KeyboardKey.space) and self.can_jump) {
                    self.velocity.y  = -self.wall_jump_velocity.y;
                    self.velocity.x  = -self.wall_jump_velocity.x;
                    self.can_jump = false;
                    self.transformer.x -= 1;
                } else {
                    self.velocity.x += 1.4;
                    
                    if (onWall[1] and self.velocity.y > 3) self.velocity.y = 3;
                }
            }

            
            self.velocity.y += 1.3;
        }

        self.move(enviorment);
        
        self.can_jump = rl.isKeyUp(rl.KeyboardKey.space) or self.can_jump;
        self.can_swing = rl.isKeyUp(rl.KeyboardKey.left)  and 
                         rl.isKeyUp(rl.KeyboardKey.right) and 
                         rl.isKeyUp(rl.KeyboardKey.up)    and 
                         rl.isKeyUp(rl.KeyboardKey.down); 
    }

    pub fn move(self: *Player, colliders: []entity.Entity) void {
        
        if (!self.is_dashing) {
            const friction: f32 = 1.0;
            if (self.velocity.x > 0) {
                self.velocity.x = @max(0, self.velocity.x - friction);
            } else if (self.velocity.x < 0) {
                self.velocity.x = @min(0, self.velocity.x + friction);
            }
        }

        self.velocity.x = std.math.clamp(self.velocity.x, -self.max_horizontal_speed, self.max_horizontal_speed);
        self.velocity.y = std.math.clamp(self.velocity.y, -self.max_falling_speed, self.max_vertical_speed);

        self.prev_pos.x = self.transformer.x;
        self.prev_pos.y = self.transformer.y;
        
        self.transformer.x += self.velocity.x;
        for (colliders) |collider| {
            if (self.transformer.checkCollision(collider.rect)) {
                self.transformer.x = self.prev_pos.x;
                self.velocity.x = 0;
                
                if (self.is_dashing) {
                    self.is_dashing = false;
                    self.dash_cooldown_timer = self.dash_cooldown;
                }
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
        const src = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = 8,
            .height = 18,
        };


        const dst = rl.Rectangle{
            .x = self.transformer.x,
            .y = self.transformer.y,
            .width = self.transformer.width,
            .height = self.transformer.height,
        };

        const origin = rl.Vector2{ .x = 0, .y = 0 };

        rl.drawTexturePro(self.player_sprite, src, dst, origin, 0.0, rl.Color.white);    
    }

    pub fn deinit(self: @This()) void {
        self.player_sprite.unload();
    }
};
