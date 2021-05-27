const std = @import("std");
usingnamespace @import("slotmap");

const Allocator = std.mem.Allocator;

/// A node from the SlotMap-based Doubly-Linked List
pub fn Node(comptime T: type) type {
    return struct {
        value: T,
        prev: ?Key,
        next: ?Key,

        const Self = @This();

        pub fn new(value: T, prev: ?Key, next: ?Key) Self {
            return Self {
                .value = value,
                .prev = prev,
                .next = next,
            };
        }
    };
}

/// SlotMap-based Doubly-Linked List
pub fn List(comptime T: type) type {
    return struct {
        map: SlotMap(Node(T)),
        tail: ?Key,
        head: ?Key,

        const Self = @This();

        pub fn new(allocator: *Allocator) Self {
            return Self {
                .map = SlotMap(Node(T)).new(allocator),
                .tail = null,
                .head = null,
            };
        }

        fn get_node(self: *Self, key: ?Key) ?*Node(T) {
            if (key) |k| {
                return self.map.get(k);
            }

            return null;
        }

        /// Fetch the value of the node corresponding to this key
        pub fn get(self: *Self, key: ?Key) ?*T {
            if (self.get_node(key)) |node| {
                return node.value;
            }

            return null;
        }

        /// The number of values stored
        pub fn len(self: *Self) usize {
            return self.map.store.items.len;
        }

        /// Pushes a new value onto the front of the list
        pub fn push_head(self: *Self, value: T) Key {
            const k = self.map.insert(Node(T).new(value, null, self.head));

            if (self.head) |head| {
                if (self.map.get(head)) |old| {
                    old.prev = k;
                    self.head = k;
                    return k;
                }
            }

            self.tail = k;
            self.head = k;
            return k;
        }

        /// Pushes a new value onto the end of the list
        pub fn push_tail(self: *Self, value: T) Key {
            const k = self.map.insert(Node(T).new(value, self.tail, null));

            if (self.tail) |tail| {
                if (self.map.get(tail)) |old| {
                    old.next = k;
                    self.tail = k;
                    return k;
                }
            }

            self.head = k;
            self.tail = k;
            return k;
        }

        /// Removes the first value in the list
        pub fn pop_head(self: *Self) ?T {
            if (self.head) |head| {
                if (self.map.remove(head)) |old| {
                    self.head = old.next;
                    return old.value;
                }
            }

            return null;
        }

        /// Removes the last value in the list
        pub fn pop_tail(self: *Self) ?T {
            if (self.tail) |tail| {
                if (self.map.remove(tail)) |old| {
                    self.tail = old.prev;
                    return old.value;
                }
            }

            return null;
        }

        /// Removes a value from the list
        pub fn remove(self: *Self, key: ?Key) ?T {
            if (key) |k| {
                if (self.map.remove(k)) |node| {
                    if (self.get_node(node.prev)) |prev_node| {
                        prev_node.next = node.next;
                    } else {
                        self.head = node.next;
                    }

                    if (self.get_node(node.next)) |next_node| {
                        next_node.prev = node.prev;
                    } else {
                        self.tail = node.prev;
                    }

                    return node.value;
                }
            }

            return null;
        }
    };
}

test "dll" {
    const expect = std.testing.expect;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var dll = List(u32).new(&arena.allocator);

    // Create a list with 5 values
    var k = dll.push_head(5);
    _ = dll.push_tail(6);
    _ = dll.push_head(3);
    _ = dll.push_tail(7);
    _ = dll.push_head(4);

    try expect(dll.len() == 5);
    try expect(dll.pop_head().? == 4);
    try expect(dll.pop_head().? == 3);

    if (dll.head) |h| {
        try expect (h.gen == k.gen and h.indice == k.indice);
    } else {
        unreachable;
    }

    _ = dll.push_head(10);

    try expect(dll.remove(k).? == 5);
    try expect(dll.pop_tail().? == 7);
    try expect(dll.pop_tail().? == 6);
    try expect(dll.pop_head().? == 10);

    try expect(dll.pop_head() == null);
    try expect(dll.pop_tail() == null);
}