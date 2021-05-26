const std = @import("std");

usingnamespace @import("lib.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

/// A slot in the SlotMap
///
/// A key is considered vacant when the generation is odd.
fn Slot(comptime T: type) type {
    return struct {
        gen: u32,
        comp: T,

        const Self = @This();

        pub fn new(comp: T) Self {
            return Self {
                .gen = 0,
                .comp = comp,
            };
        }
    };
}

/// Arena allocator with generational indices.
///
/// Similar to a slab, but each indice has a generation number to check if a slot is
/// vacant or valid. Inserting or removing a value will increment the generation, with
/// odd-numbered generations being vacant.
///
/// Keys are returned on insert which contain both the indice and generation, where
/// the indice fetches the slot for that key, and the generation checks if the key is
/// still valid.
pub fn SlotMap(comptime T: type) type {
    return struct {
        store: ArrayList(Slot(T)),
        len: u32,

        const Self = @This();

        pub fn new(allocator: *Allocator) Self {
            return Self {
                .store = ArrayList(Slot(T)).init(allocator),
                .len = 0
            };
        }

        /// Inserts a new value into the map, and generating a new key for that value.
        pub fn insert(self: *Self, component: T) Key {
            self.len += 1;

            var idx: u32 = 0;
            for (self.store.items) |*slot| {
                if (slot.gen % 2 != 0) {
                    slot.gen += 1;
                    slot.comp = component;
                    return Key {
                        .gen = slot.gen,
                        .indice = idx,
                    };
                }

                idx += 1;
            }

            self.store.append(Slot(T).new(component)) catch unreachable;

            return Key {
                .gen = 0,
                .indice = idx,
            };
        }

        /// Fetch the slot for a key, and check if the generation is valid.
        fn get_(self: *Self, key: Key) ?*Slot(T) {
            if (self.store.items.len <= key.indice) {
                return null;
            }

            const slot = &self.store.items[key.indice];

            if (slot.gen != key.gen) {
                return null;
            }

            return slot;
        }

        /// Get the value that corresponds to the key, if the key is still valid.
        pub fn get(self: *Self, key: Key) ?*T {
            if (self.get_(key)) |slot| {
                return &slot.comp;
            } else {
                return null;
            }
        }

        /// Remove the value that corresponds to the key, if the key is still valid.
        pub fn remove(self: *Self, key: Key) ?T {
            if (self.get_(key)) |slot| {
                self.len -= 1;
                slot.gen += 1;
                return slot.comp;
            } else {
                return null;
            }
        }

        /// Frees the memory that was allocated for the slot array.
        pub fn deinit(self: *Self) void {
            self.store.deinit();
        }

        /// Iterates across keys and values in the map.
        pub fn iter(self: *Self) SlotIter(T) {
            return SlotIter(T).new(self.store.items);
        }
    };
}

/// Each iteration of SlotIter returns an Entry which contains a key and value
pub fn Entry(comptime T: type) type {
    return struct {
        key: Key,
        value: T,

        const Self = @This();

        pub fn new(key: Key, value: T) Self {
            return Self {
                .key = key,
                .value = value
            };
        }
    };
}

/// Iterates the slots of a SlotMap
pub fn SlotIter(comptime T: type) type {
    return struct {
        slots: []const Slot(T),
        step: u32,

        const Self = @This();

        pub fn new(slots: []const Slot(T)) Self {
            return Self {
                .slots = slots,
                .step = 0,
            };
        }

        /// Fetch the next value in the map.
        pub fn next(self: *Self) ?Entry(*const T) {
            while (true) {
                if (self.slots.len <= self.step) {
                    return null;
                }

                const comp = &self.slots[self.step];

                if (comp.gen % 2 != 0) {
                    self.step += 1;
                    continue;
                }

                const key = Key {
                    .gen = comp.gen,
                    .indice = self.step,
                };

                self.step += 1;
                return Entry(*const T).new(key, &comp.comp);
            }
        }
    };
}