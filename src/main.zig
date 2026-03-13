const std = @import("std");
const rl = @import("raylib");
const player_zig = @import("player.zig");

pub fn main() anyerror!void {
    var debugAllocator = std.heap.DebugAllocator(.{}).init;
    defer if( debugAllocator.deinit() != .ok) @panic("leak");
    const gpa = debugAllocator.allocator();

    const screenWidth = 800;
    const screenHeight = 450;

    var player = player_zig.Player.init(rl.Vector2.init(0, 0), rl.Vector2.init(40, 40));
    const floor = rl.Rectangle.init(0, 300, 2*screenHeight, 20);
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var enviorment = std.ArrayList(rl.Rectangle).empty;
    defer enviorment.deinit(gpa);
    try enviorment.append(gpa, floor);

    try enviorment.append(gpa, rl.Rectangle.init(50, 250, 30, 40));
    try enviorment.append(gpa, rl.Rectangle.init(100, 150, 30, 500));

    try enviorment.append(gpa, rl.Rectangle.init(200, 150, 30, 500));
    
    try enviorment.append(gpa, rl.Rectangle.init(300, 0, 30, 1000));

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        

        player.handle_input(enviorment.items);
        for (enviorment.items) |place| {
            rl.drawRectangleRec(place, rl.Color.blue);
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
