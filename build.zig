const std = @import("std");

const examples = [_][]const u8 { "ecs", "secondary", "slotmap" };

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    // Compiles the slotmap library
    const slotmap = b.addStaticLibrary("slotmap", "slotmap/lib.zig");
    slotmap.setBuildMode(mode);
    slotmap.install();

    const slotmap_pkg = std.build.Pkg {
        .name = "slotmap",
        .path = "slotmap/lib.zig",
        .dependencies = &[_]std.build.Pkg{},
    };

    const test_step = b.step("tests", "Run library tests");

    const main_tests = b.addTest("slotmap/lib.zig");
    main_tests.setBuildMode(mode);
    test_step.dependOn(&main_tests.step);

    const dll_tests = b.addTest("dll/lib.zig");
    dll_tests.setBuildMode(mode);
    dll_tests.addPackage(slotmap_pkg);
    test_step.dependOn(&dll_tests.step);

    // Optionally compile the doubly-linked list
    const dll_step = b.step("dll", "Compile the doubly-linked list");

    {
        const dll = b.addStaticLibrary("dll", "dll/lib.zig");
        dll.setBuildMode(mode);
        dll.addPackage(slotmap_pkg);

        dll_step.dependOn(&b.addInstallArtifact(dll).step);
    }

    // Optionally compiles examples
    const examples_step = b.step("examples", "Compile all examples");
    inline for (examples) |name| {
        const path = "examples/" ++ name ++ ".zig";
        const exe = b.addExecutable(name, path);
        exe.setBuildMode(mode);
        exe.addPackage(slotmap_pkg);

        examples_step.dependOn(&b.addInstallArtifact(exe).step);
    }
}
