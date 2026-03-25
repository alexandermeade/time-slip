const std = @import("std");
const rl = @import("raylib");
const player_zig = @import("player.zig");
const entity = @import("entity.zig");
const level = @import("level.zig");

pub fn main() anyerror!void {
    var debugAllocator = std.heap.DebugAllocator(.{}).init;
    defer if( debugAllocator.deinit() != .ok) @panic("leak");
    const gpa = debugAllocator.allocator();

    const screenWidth = 320;
    const screenHeight = 180;

 
    //rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");

    rl.initWindow(rl.getScreenWidth(), rl.getScreenHeight(), "raylib-zig [core] example - basic window");
    const render_texture = try rl.RenderTexture2D.init(screenWidth, screenHeight);
    defer rl.closeWindow(); // Close window and OpenGL context
    //Need raylib window init before using raylib textures
    var player = try player_zig.Player.init(rl.Vector2.init(30, 30), rl.Vector2.init(20 * 0.4, 40 * 0.4));
    defer player.deinit();


    rl.setTargetFPS(30); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var enviorment = std.ArrayList(entity.Entity).empty;
    defer enviorment.deinit(gpa);
    const json_content = try std.fs.cwd().readFileAlloc(gpa, "./levels.json", 100000);
    defer gpa.free(json_content);

    const levelTemplates = std.json.parseFromSlice([]level.LevelTemplate, gpa, json_content, .{ .allocate = .alloc_always}) catch |err| {
        std.debug.print("failed at parse {}", .{err});
        return err;
    };  
    defer levelTemplates.deinit();

    const level1 = try levelTemplates.value[0].into_level(gpa);
    defer gpa.free(level1.entities);

    for (level1.entities) |e| {
        try enviorment.append(gpa, e);
    }

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key 


        player.handle_input(enviorment.items);
        rl.beginTextureMode(render_texture);

        player.draw();
        for (enviorment.items) |e| {
            switch (e.tag){
                .Enemy => rl.drawRectangleRec(e.rect, rl.Color.red),
                else => rl.drawRectangleRec(e.rect, rl.Color.blue)
            }
        }
        var buf:[300]u8 =undefined; 
        const res = try std.fmt.bufPrintZ(&buf, "x: {} y: {}", .{player.transformer.x, player.transformer.y});
        rl.drawText(res, 0, 0, 12, rl.Color.red);
                
        rl.clearBackground(rl.Color.white);
        rl.endTextureMode();

        const screen_w: f32 = @floatFromInt(rl.getScreenWidth());
        const screen_h: f32 = @floatFromInt(rl.getScreenHeight());
        const scale = @min(screen_w / screenWidth, screen_h / screenHeight);

        const offset_x = (screen_w - screenWidth * scale) / 2.0;
        const offset_y = (screen_h - screenHeight * scale) / 2.0;

        rl.beginDrawing();

        
        rl.clearBackground(rl.Color.black); 
            
        const src = rl.Rectangle{ 
            .x = 0, 
            .y = 0, 
            .width = screenWidth, 
            .height = -screenHeight 
        }; 
        const dst = rl.Rectangle{ 
            .x = offset_x, 
            .y = offset_y, 
            .width = screenWidth * scale, 
            .height = screenHeight * scale 
        };
        defer rl.endDrawing();

        rl.drawTexturePro(render_texture.texture, src, dst, rl.Vector2.zero(), 0.0, rl.Color.white);

    }
}
