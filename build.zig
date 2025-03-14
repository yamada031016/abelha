const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enableLogger = b.option(bool, "enableLogger", "Enable logging function.") orelse false;
    const options = b.addOptions();
    options.addOption(bool, "enableLogger", enableLogger);

    const exe = b.addExecutable(.{
        .name = "abelha",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .Debug,
    });
    exe.root_module.addOptions("config", options);

    const abelha_mod = b.addModule("abelha", .{
        .root_source_file = b.path("src/abelha.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    abelha_mod.addOptions("config", options);

    exe.root_module.addImport("abelha", abelha_mod);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/abelha.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_unit_tests.root_module.addOptions("config", options);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const docs_obj = b.addObject(.{
        .name = "abelha",
        .root_source_file = b.path("src/abelha.zig"),
        .target = target,
        .optimize = .Debug,
    });

    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs_obj.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Install docs into zig-out/docs");
    docs_step.dependOn(&install_docs.step);
}
