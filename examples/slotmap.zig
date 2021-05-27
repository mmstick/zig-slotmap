const std = @import("std");
const slotmap = @import("slotmap");

const Key = slotmap.Key;
const SlotMap = slotmap.SlotMap;

const print = std.debug.print;

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var persons = SlotMap([]const u8).new(&arena.allocator);

    const michael = persons.insert("Michael");
    const christine = persons.insert("Christine");

    if (persons.remove(michael)) |name| {
        print("Removed an entity named {s}\n", .{name});
    }

    print("Name of entity is {s}\n", .{persons.get(christine).?.*});
}