const std = @import("std");
usingnamespace @import("lib.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn Slot(comptime T: type) type {
    return struct {
        gen: u32,
        value: T,

        const Self = @This();

        pub fn new(gen: u32, value: T) Self {
            return Self {
                .gen = gen,
                .value = value,
            };
        }
    };
}

/// Companion for the SlotMap for storing secondary associations.
///
/// This is useful as storages for an entity-component architecture.
pub fn SecondaryMap(comptime T: type) type {
    return struct {
        store: ArrayList(?Slot(T)),
        len: u32,

        const Self = @This();

        pub fn new(allocator: *Allocator) Self {
            return Self {
                .store = ArrayList(?Slot(T)).init(allocator),
                .len = 0
            };
        }

        /// Inserts a new value into the map
        pub fn insert(self: *Self, key: Key, component: T) void {
            self.len += 1;
            var idx = self.store.items.len;
            while (idx <= key.indice) {
                self.store.append(null) catch unreachable;
                idx += 1;
            }

            self.store.items[key.indice] = Slot(T).new(key.gen, component);
        }

        /// Fetch the slot for a key, and check if the generation is valid.
        fn get_(self: *Self, key: Key) ?*Slot(T) {
            if (self.store.items.len <= key.indice) {
                return null;
            }

            const slot = &self.store.items[key.indice];

            if (slot.*) |*s| {
                if (s.gen == key.gen) {
                    return s;
                }
            }

            return null;
        }

        /// Get the value that corresponds to the key, if the key is still valid.
        pub fn get(self: *Self, key: Key) ?*T {
            if (self.get_(key)) |slot| {
                return &slot.value;
            } else {
                return null;
            }
        }

        /// Remove the value that corresponds to the key, if the key is still valid.
        pub fn remove(self: *Self, key: Key) ?T {
            if (self.get_(key)) |slot| {
                self.len -= 1;
                const value = slot.value;
                *slot = null;
                return value;
            } else {
                return null;
            }
        }

        /// Frees the memory that was allocated for the slot array.
        pub fn deinit(self: *Self) void {
            self.store.deinit();
        }

        /// Iterates across keys and values in the map.
        pub fn iter(self: *Self) SecondaryIter(T) {
            return SecondaryIter(T).new(self.store.items);
        }
    };
}

/// Each iteration of SecondaryIter returns an SecondaryEntry which contains a key and value
pub fn SecondaryEntry(comptime T: type) type {
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
pub fn SecondaryIter(comptime T: type) type {
    return struct {
        slots: []?Slot(T),
        step: u32,

        const Self = @This();

        pub fn new(slots: []?Slot(T)) Self {
            return Self {
                .slots = slots,
                .step = 0,
            };
        }

        /// Fetch the next value in the map.
        pub fn next(self: *Self) ?SecondaryEntry(*T) {
            while (true) {
                if (self.slots.len <= self.step) {
                    return null;
                }

                var com = &self.slots[self.step];

                if (com.*) |*comp| {
                    const key = Key {
                        .gen = comp.gen,
                        .indice = self.step,
                    };

                    self.step += 1;
                    return SecondaryEntry(*T).new(key, &comp.value);
                }

                self.step += 1;
                continue;
            }
        }
    };
}