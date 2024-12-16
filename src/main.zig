const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);

    if (args.len < 2) {
        try stdout.print("Usage: ultrawide-patcher <path to exe>\n", .{});
        return;
    }

    const exePath = args[1];

    var exe = try std.fs.cwd().openFile(exePath, .{ .mode = .read_write });
    defer exe.close();
    const exeBytes = try exe.readToEndAlloc(allocator, 1024 * 1024 * 1024); // 1GB

    // change all occurences of 39 8E E3 3F to 8E E3 18 40
    const default = &[_]u8{ 0x39, 0x8E, 0xE3, 0x3F };
    const patch = &[_]u8{ 0x8E, 0xE3, 0x18, 0x40 };

    const replacementSize = std.mem.replacementSize(u8, exeBytes, default, patch);
    const output = try allocator.alloc(u8, replacementSize);
    const replacements = std.mem.replace(u8, exeBytes, default, patch, output);

    try stdout.print("Replaced {} occurences\n", .{replacements});

    try exe.seekTo(0);
    try exe.writeAll(output);
}
