# SlotMap for Zig

Implementation of a SlotMap for Zig, which is an arena allocator with generational indices that also features a secondary map for secondary associations.

## SlotMap

A `SlotMap` is a vector where each element is a versioned reusable slot. Slots are considered to be vacant when the generation of that slot is odd-numbered. Components added to the map increment the generation, and the generation is stored in the returned key along with the indice of the slot. The key may be used to get or remove the value in the future.

```zig
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
```

When accessing a slot via the key, the generation of the key and slot is compared to determine if the key is stale. It is effectively identical to a slab, with similar performance to accessing an element in an array via its indice. There is a version check to compare if the key is valid for the component it is fetching.

## SecondaryMap

A `SecondaryMap` is also included which can be used to set up secondary associations for keys. When inserting a value, you must supply the entity to associate, with the value that will be associated with the entity.

```zig
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
```

Note that the `SecondaryMap` will allocate the same number of slots as the highest-indiced entity you insert, because the values are stored in the same indice as defined in the key. It may be better to use a `HashMap` for components that are sparsely allocated to keys.

## Libraries

There are two libraries in this repository:

- [slotmap](./slotmap/): The base SlotMap library
- [slotmap-dll](./dll/): SlotMap-based doubly-linked list

Both have their root source file as `lib.zig`.

## Examples

- [Doubly-Linked List](./dll/lib.zig)
- [Entity-Component System](./examples/ecs.zig)

## Reference

Based on the excellent work in the Rust implementation which this is based on: [orlp/slotmap](https://github.com/orlp/slotmap)