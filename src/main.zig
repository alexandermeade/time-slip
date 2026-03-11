const std = @import("std");
const rl = @import("raylib");
const player_zig = @import("player.zig");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
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
    try enviorment.append(gpa, rl.Rectangle.init(100, 200, 30, 10));
    try enviorment.append(gpa, rl.Rectangle.init(200, 0, 30, 1000));




    
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------
        rl.pollInputEvents();

        var player_grounded = false;
        for (enviorment.items) |place| {
            if (player_grounded) {
                break;
            }
            player_grounded = player.isGrounded(place);
        }

        const player_fall_speed:f32 = player.max_vertical_speed;
        const onWall = player.isTouchingWall(enviorment.items);
        std.debug.print("grounded: {}, velocity: {}, onWall: {}\n", .{player_grounded, player.velocity, onWall});

        if (rl.isKeyDown(rl.KeyboardKey.space) and player_grounded) {
            player.velocity.y += -17.0;
        }

        if(rl.isKeyDown(rl.KeyboardKey.a)) {
            if (onWall[0]) {
                player.max_vertical_speed = 3; 
            }
            player.velocity.x -= 1.4;
        }
        if(rl.isKeyDown(rl.KeyboardKey.d)) {
            if (onWall[1]) {
                player.max_vertical_speed = 3; 
            }
            player.velocity.x += 1.4;
        }



        //apply gravity
        player.velocity.y += 1.3;
        player.move(enviorment);
        player.max_vertical_speed = player_fall_speed;

        
        if (player.transformer.checkCollision(floor)) {
            player.moveBack();
        }

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
