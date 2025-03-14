const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Create a module for each of our source files
    const counter_module = b.createModule(.{
        .root_source_file = b.path("src/counter.zig"),
    });

    const options_module = b.createModule(.{
        .root_source_file = b.path("src/options.zig"),
    });

    const formatter_module = b.createModule(.{
        .root_source_file = b.path("src/formatter.zig"),
        .imports = &.{
            .{ .name = "counter", .module = counter_module },
            .{ .name = "options", .module = options_module },
        },
    });

    const cli_module = b.createModule(.{
        .root_source_file = b.path("src/cli.zig"),
        .imports = &.{
            .{ .name = "options", .module = options_module },
            .{ .name = "counter", .module = counter_module },
            .{ .name = "formatter", .module = formatter_module },
        },
    });

    const exe = b.addExecutable(.{
        .name = "wc",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add module dependencies
    exe.root_module.addImport("cli", cli_module);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the binary");
    run_step.dependOn(&run_cmd.step);

    // Create separate test steps for each module
    const counter_tests = b.addTest(.{
        .root_source_file = b.path("src/counter.zig"),
        .target = target,
        .optimize = optimize,
    });

    const options_tests = b.addTest(.{
        .root_source_file = b.path("src/options.zig"),
        .target = target,
        .optimize = optimize,
    });

    const cli_tests = b.addTest(.{
        .root_source_file = b.path("src/cli.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add module dependencies to cli tests
    cli_tests.root_module.addImport("options", options_module);

    const formatter_tests = b.addTest(.{
        .root_source_file = b.path("src/formatter.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add module dependencies to formatter tests
    formatter_tests.root_module.addImport("counter", counter_module);
    formatter_tests.root_module.addImport("options", options_module);

    // Add the new cli_test from the tests directory
    const cli_integration_tests = b.addTest(.{
        .root_source_file = b.path("tests/cli_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add module dependencies to cli integration tests
    cli_integration_tests.root_module.addImport("options", options_module);
    cli_integration_tests.root_module.addImport("cli", cli_module);
    cli_integration_tests.root_module.addImport("counter", counter_module);

    const run_counter_tests = b.addRunArtifact(counter_tests);
    const run_options_tests = b.addRunArtifact(options_tests);
    const run_cli_tests = b.addRunArtifact(cli_tests);
    const run_formatter_tests = b.addRunArtifact(formatter_tests);
    const run_cli_integration_tests = b.addRunArtifact(cli_integration_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Execute all unit and integration tests");
    test_step.dependOn(&run_counter_tests.step);
    test_step.dependOn(&run_options_tests.step);
    test_step.dependOn(&run_cli_tests.step);
    test_step.dependOn(&run_formatter_tests.step);
    test_step.dependOn(&run_cli_integration_tests.step);
}
