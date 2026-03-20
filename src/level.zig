const entity = @import("entity.zig");
const std = @import("std");

pub const LevelTemplate = struct {
    name: []const u8,
    entities: []entity.EntityTemplate,
    
    pub fn into_level(self: @This(), allocator: std.mem.Allocator) !Level {
        var entities = try std.ArrayList(entity.Entity).initCapacity(allocator, self.entities.len);
        defer entities.deinit(allocator);

        for (self.entities) |e| {
            const en = try e.into_entity();
            try entities.append(allocator, en);
        }

        return Level {
            .name = self.name,
            .entities = try entities.toOwnedSlice(allocator),        
        };
    }
};

pub const Level = struct {
    name: []const u8, 
    entities: []entity.Entity,
};
