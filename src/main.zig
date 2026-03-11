const std = @import("std");
const rl = @import("raylib");
const player_zig = @import("player.zig");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    var player = player_zig.Player.init(rl.Vector2.init(0, 0), rl.Vector2.init(40, 40));
    const floor = rl.Rectangle.init(0, 150, 2*screenHeight, 20);
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------
        std.debug.print("{}", .{player.isGrounded(floor)});
        rl.pollInputEvents();
        if(rl.isKeyDown(rl.KeyboardKey.a)) {
            player.velocity.x -= 1.2;
        }
        if(rl.isKeyDown(rl.KeyboardKey.d)) {
            player.velocity.x += 1.2;
        }

        if (rl.isKeyDown(rl.KeyboardKey.space) and player.isGrounded(floor)) {
            player.velocity.y += -15.0;
        }

        //apply gravity
        player.velocity.y += 1.2;
        player.move(floor);

        if (player.transformer.checkCollision(floor)) {
            player.moveBack();
        }


        rl.drawRectangleRec(floor, rl.Color.blue);

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
