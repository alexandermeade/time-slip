const std = @import("std");
const rl = @import("raylib");
const player_zig = @import("player.zig");
const entity = @import("entity.zig");
const level = @import("level.zig");

pub fn main() anyerror!void {
    var debugAllocator = std.heap.DebugAllocator(.{}).init;
    defer if( debugAllocator.deinit() != .ok) @panic("leak");
    const gpa = debugAllocator.allocator();

    const screenWidth = 800;
    const screenHeight = 450;

    var player = player_zig.Player.init(rl.Vector2.init(30, 30), rl.Vector2.init(40, 40));
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var enviorment = std.ArrayList(entity.Entity).empty;
    defer enviorment.deinit(gpa);
    const json_content = try std.fs.cwd().readFileAlloc(gpa, "./levels.json", 100000);
    defer gpa.free(json_content);

    const levelTemplates = std.json.parseFromSlice(level.LevelTemplate, gpa, json_content, .{ .allocate = .alloc_always}) catch |err| {
        std.debug.print("failed at parse {}", .{err});
        return err;
    };  
    defer levelTemplates.deinit();

    const level1 = try levelTemplates.value.into_level(gpa);
    defer gpa.free(level1.entities);

    for (level1.entities) |e| {
        try enviorment.append(gpa, e);
    }

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key 
        player.handle_input(enviorment.items);
        for (enviorment.items) |e| {
            switch (e.tag){
                .Enemy => rl.drawRectangleRec(e.rect, rl.Color.red),
                else => rl.drawRectangleRec(e.rect, rl.Color.blue)
            }
        }

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();
        player.draw();
        rl.clearBackground(.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        //----------------------------------------------------------------------------------
    }
}
