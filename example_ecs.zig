const std = @import("std");
const slotmap = @import("src/lib.zig");

const Key = slotmap.Key;
const SlotMap = slotmap.SlotMap;
const SecondaryMap = slotmap.SecondaryMap;

const print = std.debug.print;

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var devices = SlotMap([]const u8).new(&arena.allocator);
    var parents = SecondaryMap(Key).new(&arena.allocator);
    var filesystems = SecondaryMap([]const u8).new(&arena.allocator);

    defer devices.deinit();
    defer parents.deinit();
    defer filesystems.deinit();

    const disk_a = devices.insert("/dev/sda");
    const part1 = devices.insert("/dev/sda1");
    const part2 = devices.insert("/dev/sda2");
    const part3 = devices.insert("/dev/sda3");

    parents.insert(part1, disk_a);
    parents.insert(part2, disk_a);
    parents.insert(part3, disk_a);

    filesystems.insert(part1, "VFAT");
    filesystems.insert(part2, "Ext4");

    if (devices.remove(part1)) |name| {
        print("Removed {s} from the map\n", .{name});
    }
    
    const part4 = devices.insert("/dev/sda4");
    parents.insert(part4, disk_a);

    var iterator = devices.iter();
    while (iterator.next()) |slot| {
        if (parents.get(slot.key)) |p| {
            const parent = p.*;
            if (devices.get(parent)) |pslot| {
                print("  Partition: {s}\n", .{slot.value.*});
                print("    Parent:     {s}\n", .{pslot.*});
            }
        } else {
            print("Disk: {s}\n", .{slot.value.*});
        }

        var fs: []const u8 = "None";
        if (filesystems.get(slot.key)) |fsv| {
            fs = fsv.*;
        }

        print("    Filesystem: {s}\n", .{fs});
    }

    var fs_iter = filesystems.iter();
    while (fs_iter.next()) |slot| {
        print("{} has FS {s}\n", .{slot.key, slot.value.*});
    }
}
