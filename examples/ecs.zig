const std = @import("std");
const slotmap = @import("slotmap");

const Key = slotmap.Key;
const SlotMap = slotmap.SlotMap;
const SecondaryMap = slotmap.SecondaryMap;

const print = std.debug.print;

const World = struct {
    devices: SlotMap([]const u8),
    parents: SecondaryMap(Key),
    filesystems: SecondaryMap([]const u8),

    const Self = @This();

    pub fn new(allocator: *std.mem.Allocator) Self {
        return Self {
            .devices = SlotMap([]const u8).new(allocator),
            .parents = SecondaryMap(Key).new(allocator),
            .filesystems = SecondaryMap([]const u8).new(allocator),
        };
    }

    pub fn display(self: *Self) void {
        var iterator = self.devices.iter();
        while (iterator.next()) |slot| {
            print("Device: {s}\n", .{slot.value.*});
            if (self.parents.get(slot.key)) |p| {
                const parent = p.*;
                if (self.devices.get(parent)) |pslot| {
                    print("    Partiton of: {s}\n", .{pslot.*});
                }
            }

            var fs: []const u8 = "None";
            if (self.filesystems.get(slot.key)) |fsv| {
                fs = fsv.*;
            }

            print("    Filesystem:  {s}\n", .{fs});
        }

        var fs_iter = self.filesystems.iter();
        while (fs_iter.next()) |slot| {
            if (self.devices.get(slot.key)) |dev| {
                print("{s} has FS {s}\n", .{dev.*, slot.value.*});
            }
            
        }
    }

    pub fn create(self: *Self, path: []const u8) Key {
        return self.devices.insert(path);
    }

    pub fn remove(self: *Self, key: Key) ?[]const u8 {
        return self.devices.remove(key);
    }

    pub fn deinit(self: *Self) void {
        self.devices.deinit();
        self.parents.deinit();
        self.filesystems.deinit();
    }
};

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var world = World.new(&arena.allocator);
    defer world.deinit();

    const disk_a = world.create("/dev/sda");
    const part1 = world.create("/dev/sda1");
    const part2 = world.create("/dev/sda2");
    const part3 = world.create("/dev/sda3");

    world.parents.insert(part1, disk_a);
    world.parents.insert(part2, disk_a);
    world.parents.insert(part3, disk_a);

    world.filesystems.insert(part1, "VFAT");
    world.filesystems.insert(part2, "Ext4");

    if (world.remove(part1)) |name| {
        print("Removed {s} from the map\n", .{name});
    }
    
    const part4 = world.create("/dev/sda4");
    world.parents.insert(part4, disk_a);

    world.display();
}
