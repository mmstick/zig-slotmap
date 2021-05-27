pub usingnamespace @import("slotmap.zig");
pub usingnamespace @import("secondary.zig");

pub const Key = packed struct {
    gen: u32,
    indice: u32,
};