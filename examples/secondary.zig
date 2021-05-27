const std = @import("std");
const slotmap = @import("slotmap");

const Key = slotmap.Key;
const SlotMap = slotmap.SlotMap;
const SecondaryMap = slotmap.SecondaryMap;

const print = std.debug.print;

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var users = SlotMap(u64).new(&arena.allocator);
    var names = SecondaryMap([]const u8).new(&arena.allocator);

    const user1 = users.insert(1000);
    names.insert(user1, "Michael");

    const user2 = users.insert(1001);
    names.insert(user2, "Christine");

    var iterator = users.iter();
    while (iterator.next()) |user| {
        if (names.get(user.key)) |name| {
            print("Found user {} whose name is {s}\n", .{user.value.*, name.*});
        }
    }
}