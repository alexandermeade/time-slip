const rl = @import("raylib");
const std = @import("std");

pub const EntityTag = enum {
    Player,
    Environment,
    Enemy,
    Projectile
};

pub const EntityErrors = error {
    FailedToMatchEnum
};

pub const EntityTemplate = struct {
    name: []const u8,
    pos: [2]f32,
    size: [2]f32,
    tag: []const u8,

    pub fn into_entity(self: @This()) !Entity {
        return Entity {
            .name = self.name,
            .rect = rl.Rectangle.init(self.pos[0], self.pos[1], self.size[0], self.size[1]),
            .tag = try EntityTemplate.string_to_enum(self.tag)
        };
    }

    pub fn string_to_enum(tag: []const u8) !EntityTag {
        if (std.mem.eql(u8, tag, "Player")) {
            return .Player;
        }
        
        if (std.mem.eql(u8, tag, "Environment")) {
            return .Environment;
        }

        if (std.mem.eql(u8, tag, "Enemy")) {
            return .Enemy;
        }
        
        if (std.mem.eql(u8, tag, "Projectile")) {
            return .Projectile;
        }


        return EntityErrors.FailedToMatchEnum; 
    }
};

pub const Entity = struct {
    name: []const u8,
    rect: rl.Rectangle,
    tag: EntityTag,
};
