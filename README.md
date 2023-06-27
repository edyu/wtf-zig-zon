# Zig Package Manager - WTF is Zon

The <u>power</u> **hack** and complexity of **Package Manager** in Zig

---

Ed Yu ([@edyu](https://github.com/edyu) on Github and
[@edyu](https://twitter.com/edyu) on Twitter)
Jun.27.2023

---

![Zig Logo](https://ziglang.org/zig-logo-dark.svg)

## Introduction

[**Zig**](https://ziglang.org) is a modern system programming language and although it claims to a be a **better C**, many people who initially didn't need system programming were attracted to it due to the simplicity of its syntax compared to alternatives such as **C++** or **Rust**.

However, due to the power of the language, some of the syntax are not obvious for those first coming into the language. I was actually one such person.

Today we will take a break from the language itself to talk about one of the most important new features that was introduced recently in **Zig** -- the *package manager*. I've read somewhere that all modern langauge need to have package manager built in. Although I don't share the same opinion, it's indicative of how important a good package manager is for the the underlying language. For example, **Javascript** has `npm`, [**Haskell**](https://www.haskell.org) has [`cabal`](https://haskell.org/cabal/), and **Rust** has [`cargo`](https://doc.rust-lang.com/cargo/).

## Disclaimer

There is a reason why I changed my typical subtitle of *power and complexity* to *hack and complexity* for this particular article because unfortunately the **Zig** *Package Manager* is currently only on the *master* branch (or edge) and its a work-in-progress until `0.11` is released. As for the **hack** part, it will make sense after you read through the part of [Provide a Package](#provide-a-package).

The state of the release `0.11` as of June 2023 is in flux so you will encounter many bugs and problems along the way. I'm not writing this to discourage you from using it but to set the right expetation so you don't throw away the *baby* (**Zig**) with the *bath water* (*package manager*).

**Zig** along with its *package manager* is being constantly improved and honestly it's already very useful and usable even in the current state (despite the frustrations along with one of the **hackest** things I've done, which I will describe later in the article).

When you run `zig build`, you may see several failures (such as `segmentation fault`) when it's pulling down packages before it will succeed after several more tries. Although there is indication it's because of *TLS* but I don't want to give out wrong information that I haven't investigated myself.

```fish
~/w/z/my-wtf-project main• ❱ zig build
fish: Job 1, 'zig build' terminated by signal SIGSEGV (Address boundary error)
~/w/z/my-wtf-project main• 3.8s | 139 ❱ zig build
fish: Job 1, 'zig build' terminated by signal SIGSEGV (Address boundary error)
~/w/z/my-wtf-project main• 1.2s | 139 ❱ zig build
fish: Job 1, 'zig build' terminated by signal SIGSEGV (Address boundary error)
~/w/z/my-wtf-project main• 1.2s | 139 ❱ zig build
fish: Job 1, 'zig build' terminated by signal SIGSEGV (Address boundary error)
~/w/z/my-wtf-project main• 3s | 139 ❱ zig build
~/w/z/my-wtf-project main• 38s ❱ ls
```

## Package Manager

So what's the purpose of the *package manager*? For a developer, the *package manager* is used to use other people's code easily. For example, say you need to use a new library, it's much easier to use the underlying *package manager* to add (either download and/or link to the library) the library and then somehow configure something in your project to *magically* link to the library for you to use it in your code.

## Zig Package Manager(s)

**Zig** had some other *package managers* in the past but now we have a built-in *official package manager* as part of `version 0.11` (not released yet as of July, 2023).

Interestingly, there are no additional commands to remember as the *package manager* is built into the language. **Zig** also does not have a global repository or a website that hosts the global repository such as [npmjs](https://npmjs.com) does for *Javascript* or [crates.io](https://crates.io) for **Rust**.

So really, the **Zig** *Package Manager* is just same old `zig build` that you need to build your project anyways. There is nothing new you really need to use the *package manager*.

There is however a new file-type with the extension `.zon` and a new file called `build.zig.zon`. `zon` stands for **Zig** Object Notation similar to how `json` stands for **JavaScript** Object Notation. It's mainly a way to describe hierarchical relationship such as dependencies needed in the project.

In order to use a **Zig** package using the *Package Manager*, you'll need to do 3 things:
1. Add your dependencies in `build.zig.zon`
2. Incorporate your dependencies to your build process in `build.zig`
3. Import your dependencies in your code using `@import`

## build.zig.zon

If you open up a `zon` file such as the following, you'll notice, it looks like a `json` file such as the typical `package.json` somewhat.

```zig
// because zon file is really just a zig struct
// comments are really done in the same way using 2 forward slashes
.{
    // the name of your project
    .name = "my-wtf-project",
    // the version of your project
    .version = "0.0.1",

    // the actual packages you need as dependencies of your project 
    .dependencies = .{
        // the name of the package
        .zap = .{
            // the url to the release of the module
            .url = "https://github.com/zigzap/zap/archive/refs/tags/v0.1.7-pre.tar.gz",
            // the hash of the module, this is not the checksum of the tarball
            .hash = "1220002d24d73672fe8b1e39717c0671598acc8ec27b8af2e1caf623a4fd0ce0d1bd",
        },
    }
}
```

There are several things of note here in the code above:

1. The *object* looking curly braces are actually *anonymous* `struct`s, if you don't know what `struct`s are, you can think them as like an object. I briefly talked about `struct`s in my previous article: [Zig Union(Enum)](https://zig.news/edyu/zig-unionenum-wtf-is-switchunionenum-2e02).

2. The `.` in front of the curly braces are important as it denotes the `struct` as an *anonymous* `struct`. The reason it's called *anonymous* because you don't need to specify the name or the type because it's defined a priori. In other words, the type of the `struct` is based upon the context. In this case, the parser that's reading and reifying the `struct` will expect a particular structure of the `struct` to include certain fields.

3. The `.` in front of field names are also important because it conforms to the expected structure. In this particular `struct`, there is an expectation of three top level fields of `name`, `version`, and `dependencies` respectively.

## dependencies

To use a package that's been prepared for the new Zig Package Manager, you just need to list it in the `dependencies` section.

In the previous example, I showed how to add [*Zap*](https://github.com/zigzap/zap), a webserver, to your project by listing both the `url` of the release and the `hash`.

The `url` is fairly easy to find as you can normally find it on [github](https://github.com/zigzap/zap/releases) directly.

However, the `hash` is difficult to find out because it's not just the `md5sum`, `sha1sum`, or even `sha256sum` of the tarball listed in `url`. The `hash` does use *sha256* but it's not a direct hash of the tarball so it's not easily calculated by the user of the package.

Luckily the easiest way I found is just to put any `hash` there initially and then `zig build` will complain and give you the correct hash. I know it's not ideal until all package author follows what [*Zap*](https://github.com/zigzap/zap) does by listing the `hash` in the [release notes](https://github.com/zigzap/zap/releases) or the README.

The `dependencies` section showing 2 packages:

```zig
    .dependencies = .{
        .zap = .{
            .url = "https://github.com/zigzap/zap/archive/refs/tags/v0.1.7-pre.tar.gz",
            .hash = "1220002d24d73672fe8b1e39717c0671598acc8ec27b8af2e1caf623a4fd0ce0d1bd",
        },
        .duck = .{
            .url = "https://github.com/beachglasslabs/duckdb.zig/archive/refs/tags/v0.0.1.tar.gz",
            .hash = "12207c44a5bc996bb969915a5091ca9b70e5bb0f9806827f2e3dd210c946e346a05e",
        }
    }
```

Once you add your `dependencies`, `zig buid` would pull down your dependent packages as part of your project.

But you may need to add the package in your build step as well. **Zig** is different in many languages that it minimizes a runtime so often you'll need to build and link your `dependencies` in your project.

# build.zig

**Zig** expects the dependencies as a `module` in order to pull in the package as part of the build process. In the `build.zig` of the `zap` module, it will list itself as a module with the name `zap`.


Here is an example of the `build.zig` how to include the `zap` project in your build:

```zig
const std = @import("std");

pub fn build(b: *std.Build) !void {
    // these are boiler plate code until you know what you are doing
    // and you need to add additional options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // this is your own program
    const exe = b.addExecutable(.{
        // the name of your project
        .name = "my-wtf-project",
        // your main function
        .root_source_file = .{ .path = "testzon.zig" },
        // references the ones you declared above
        .target = target,
        .optimize = optimize,
    });

    // using duck as a dependency
    const duck = b.dependency("duck", .{
        .target = target,
        .optimize = optimize,
    });
    // duck has exported itself as duck 
    // now you are re-exporting duck
    // as a module in your project with the name duck
    exe.addModule("duck", duck.module("duck"));
    // you need to link to the output of the build process
    // that was done by the duck package
    // in this case, duck is outputting a library
    // to which your project need to link as well
    exe.linkLibrary(duck.artifact("duck"));

    // now install your own executable after it's built correctly
    b.installArtifact(exe);
}
```

What the code snippet above does is that it first declares your project as an executable and then pulls in `duck` as a dependency.

The `build.zig` in the `duck` project already *exported* itself as the module `duck` but you are adding it again as a module with the same name `duck`.

The `linkLibrary` call is the actual call to link to the output (**Zig** calls it `artifact`) of the `duck` module.

# @import

Now you have everything setup in your build, you need to use the new package in your code.

All you need to do is to use the `@import` builtin to import your new library just like how you normally import the standard library `@import(std)`.

```zig
const std = @import("std");
const DuckDb = @import("duck");

pub fn main() !void {
    // setup database
    var duck = try DuckDb.init(null);
    defer duck.deinit();
}
```

---

## Provide a Package

Ok, this is for those who would like to understand how the **Zig** *package manager* works as a library/package provider.

To better illustrate things, I'll use a new package [`duckdb.zig`](https://github.com/beachglasslabs/duckdb.zig) that I wrote.

[DuckDb](https://duckdb.org/) is a column-based SQL database so think it as basically a column-based [SQLite](https://www.sqlite.org/index.html).
I will split the project into 3 packages A, B, and C. Basically the idea is that our project will be C that is the actual project that uses *DuckDb*. The project C will then use the **Zig** layer provided by package B, which in turn will need the actual *DuckDb* libraries in package A. 

So in our case, we have the project *my-wtf-project*, which will call the **Zig** library provided by [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig). The [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig) is really a wrapper of [libduckdb](https://github.com/beachglasslabs/libduckdb) that provides the dynamic library of [release 0.8.1](https://github.com/duckdb/duckdb/releases/tag/v0.8.1) of [DuckDb](https://duckdb.org). To use the A, B, C in the previous paragraph, C is our project *my-wtf-project*, B is [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig), and A is [libduckdb](https://github.com/beachglasslabs/libduckdb).

Note: I will talk about the actual process of making a wrapper library in a future article.

## A: [libduckdb](https://github.com/beachglasslabs/libduckdb)

The *duckdb* is written in c++ and the `libduckdb-linux-amd64` release from *duckdb* only provided 3 files: `duckdb.h`, `duckdb.hpp`, and `libduckdb.so`.

I unzipped the package and placed `duckdb.h` under `include` directory and `libduckdb.so` under `lib` directory.

Here are the first 3 hacks needed: 

1. You don't need to build anything but the package manager expects to see a `build.zig` file in the package so you must provide one.
2. Because you provided a `build.zig`, you need to provide some build artifact even if it's not needed
3. The most important part and the **hackiest** part is that you need to use the constructs used for header files to install the library.

## build.zig.zon of A: [libduckdb](https://github.com/beachglasslabs/libduckdb).

This is probably the simplest `build.zig.zon` as you don't need any dependencies.

This should remind people of a very simple `.cabal`, `cargo.toml`, or `package.json` file.

```zig
// build.zig.zon
// there are no dependencies
// eventually, may want to list duckdb itself as a dependency
.{
    .name = "duckdb",
    .version = "0.8.1",
}
```

## Artifact

You'll see the word `artifact` used often in the build process. One way to grasp `artifact` is to think it as the output of the build. If you are building a shared library, the `.so` file is the `artifact`; a static library, the `.a` file is the `artifact`; and for an executable, the actual execuable is the `artifact`.

When you have the `artifact` in the code (`build.zig`), you can then use the `artifact` *object* to pass in to other function calls that can *extract* parts of the artifact based on their individual need. For example, `installLibraryHeaders()` would take in the `artifact` *object* and install any header files installed as part of the `artifact`.

In fact, this is something we will and we have to take advantage of in order to make our <u>hack</u> build work.

In the code below, the executable `.name = "my-wtf-project` tells the build that *my-wtf-project* is the name of the `artifact` and the executable is the actual `artifact`. 

```zig
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "my-wtf-project",
        .root_source_file = .{ .path = "testzon.zig" },
        .target = target,
        .optimize = optimize,
    });

    // see how exe is now referred as artifact
    b.installArtifact(exe);
}


```

## build.zig of A: [libduckdb](https://github.com/beachglasslabs/libduckdb).

We are essentially building something we don't really need but we definitely need the `installHeader` calls because this is how we *install* the 2 files we need in our `artifact`: `include/duckdb.h` and `lib/libduckdb.so`.

Note that we are building a library without specifying a source code anywhere. We however do need to at least link to something. In this case, we need to link to the `libduckdb.so` even though we don't need any symbols from it because the build process needs either a source file or a library to link to.

Yes, we are using the `installHeader` to install a dynamic library because there is no alternative.

We can use `installLibFile` to install the `lib/libduckdb.so` but as you'll see in package B, it won't work without using `installHeader`.

The call to `installHeader` requires a source and destination arguments but the destination argument assumes relative path of the target header directory. Therefore, we need to use `../lib/libduckdb.so` in order to install `libduckdb.so` under `lib` directory instead of the default `include`.

The final call to `installArtifact` is the one that will be utilized by B to grab the 2 files needed as described next. It will in this case, create an `artifact` `libduckdb.a` that we don't really need. For us, the `artifact` contains 3 things, the `duckdb.h`, `libduckdb.so`, and `libduckdb.a`. We only need the first two and `libduckdb.a` really is a side-effect of the artifact that we can toss away later in B.

You can say we only need the bath water, not the baby. (Sorry for the bad jokes but I can't help myself. :blush: )

```zig
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var libduckdb_module = b.createModule(.{
        .source_file = .{
            .path = "lib/libduckdb.so"
        }
    });

    try b.modules.put(b.dupe("libduckdb"), libduckdb_module);

    // We don't need this static library
    // but a build process is required
    // in order to use the artifact
    // the artifact is named by the .name field
    // in this case it's called 'duckdb'
    // notice there is no reference to a source file
    const lib = b.addStaticLibrary(.{
        .name = "duckdb",
        .target = target,
        .optimize = optimize,
    });

    // point to the library path
    lib.addIncludePath("include");
    // point to the library path so we can find the system library
    // we need this to find the libduckdb.so
    lib.addLibraryPath("lib");
    // this means to link to libduckdb.so in the lib directory
    // the call will prepend 'lib' and append '.so'
    lib.linkSystemLibraryName("duckdb");

    // HACK XXX hope zig fixes it
    // installHeader assumes include target directory
    // so we need to use '..' to go to the parent directory
    lib.installHeader("lib/libduckdb.so", "../lib/libduckdb.so");
    lib.installHeader("include/duckdb.h", "duckdb.h");

    b.installArtifact(lib);
}
```

## B: [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig)

The [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig) is a minimal (for now) **Zig** wrapper to *duckdb*. The idea is so that any **Zig** project depending on it doesn't have to deal with the **C/C++** API just the **Zig** equivalent.

We still need to perpetuate the **hack** by making sure `libduckdb.so` is part of the output `artifact` of [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig) as well.

## build.zig.zon of B: [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig)

We do have a dependency now as we need to refer to a release of A: [libduckdb](https://github.com/beachglasslabs/libduckdb).

```zig
// build.zig.zon
// Now we depend on a release of A: libduckdb
.{
    // name of the package
    .name = "duck",
    // now we can version it to anything
    // as it's just the version of the zig wrapper
    .version = "0.0.1",

    .dependencies = .{
        // point to the name defined in libduckdb's build.zig.zon
        .duckdb = .{
            // the github release
            .url = "https://github.com/beachglasslabs/libduckdb/archive/refs/tags/v0.8.1.tar.gz",
            .hash = "1220f2fd60e07231291a44683a9297c1b42ed9adc9c681594ee21e0db06231bf4e07",
        }
    }
}
```

## build.zig of B: [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig)

We now need to refer to the `libduckdb` (A) package using the name `duckdb` by making a call to `Build.dependency("duckdb)`.

We then name our module `duck` and add the module to `Build` with such name so that the build process can get the module by name if needed.

Our own artifact is now named `duck` by calling `Build.addStaticLibrary()` with `.name = "duck"` in the *anonymous* `struct`.

Although we call `linkLibrary(duck_dep.artifact("duckdb"))`, the empty library created in `libduckdb` A doesn't actually resolve anything symbols because all the symbols are really in the dynamic library `libduckdb.so`.

The most important part of the <u>hack</u> build is to call to `installLibraryHeaders()` because we want to once again include the output of the `libduckdb` `artifact` in our own `artifact` so that anything that depends on `duckdb.zig` would have access to both the `duckdb.h` and `libduckdb.so` from A.

```zig
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // we need to refer to the dependency in build.zig.zon
    const duck_dep = b.dependency("duckdb", .{
        .target = target,
        .optimize = optimize,
    });

    // we are creating our own module here
    var duck_module = b.createModule(.{
        .source_file = .{ .path = "src/main.zig" },
    });

    // we name the module duck which will be used later
    try b.modules.put(b.dupe("duck"), duck_module);

    // we are building a static library
    const lib = b.addStaticLibrary(.{
        // the output will be libduck.a
        .name = "duck",
        // the code to our wrapper library
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // we link to the empty library in libduckdb
    // package that doesn't resolve any symbols
    // as these symbols are defined in libduckdb.so
    lib.linkLibrary(duck_dep.artifact("duckdb"));

    // we must use this hack again
    // to make sure include/duckdb.h and lib/libduckdb.so
    // are installed
    lib.installLibraryHeaders(duck_dep.artifact("duckdb"));
    // run the install to install the output artifact
    b.installArtifact(lib);
}
```

## C: my-wtf-project

Now to create the executable for our project, we need to link to the packages A [libduckdb](https://github.com/beachglasslabs/libduckdb) and B [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig).

## build.zig.zon of C: my-wtf-project

Our only dependency is the release of B: [duckdb.zig](https://github.com/beachglasslabs/duckdb.zig).

Notice that we do not need to refer to A ([libduckdb](https://github.com/beachglasslabs/libduckdb)) at all because B hides that from us.

```zig
// build.zig.zon
// Now we depend on a release of B: duckdb.zig
.{
    // this is the name of our own project
    .name = "my-wtf-project",
    // this is the version of our own project
    .version = "0.0.1",

    .dependencies = .{
        // we depend on the duck package described in B
        .duck = .{
            .url = "https://github.com/beachglasslabs/duckdb.zig/archive/refs/tags/v0.0.1.tar.gz",
            .hash = "12207c44a5bc996bb969915a5091ca9b70e5bb0f9806827f2e3dd210c946e346a05e",
        },
    },
}
```

## build.zig of C: my-wtf-project

This is somewhat similar to the `build.zig` of B ([duckdb.zig](https://github.com/beachglasslabs/duckdb.zig)).

Although we never referred to A ([libduckdb](https://github.com/beachglasslabs/libduckdb)) at all in `build.zig.zon`, we do need to refer to the artifact of "duck" and install `libduckdb.so` from A ([libduckdb](https://github.com/beachglasslabs/libduckdb)) using the same <u>hack</u> call `installLibraryHeaders(duck.artifact("duck"))`. However, We now refer to the library header as part of the `artifact` of B ([duckdb.zig](https://github.com/beachglasslabs/duckdb.zig)), not that of A ([libduckdb](https://github.com/beachglasslabs/libduckdb)).

We also have to link to the library provided by B ([duckdb.zig](https://github.com/beachglasslabs/duckdb.zig)) because it actually includes the **Zig** wrapper functions we need in our code by calling `linkLibrary(duck.artifact("duck"))`.

If you look at the code below, you'll notice a curious use of `std.fmt.allocPrint()` that refers to something called `Build.install_prefix`. It's just a fancy way to refer to the output directory what typically defaults to `zig-out`. The reason is that our executable do need to find the symbols exposed by the dynamic library from A ([libduckdb](https://github.com/beachglasslabs/libduckdb)) for the linking process.

We basically tell the build that to add `zig-out/lib` to find the libraries needed for linking and then link to `libduckdb.so` by calling `linkSystemLibraryName("duckdb")`.

Due to the latest change in **Zig**, we also now need to tell the build that `libduckdb.so` requires the `libC` by calling `linkLibC`.

Afterwards, we just install the executable by calling 'Build.installArtifact()', which would install the executable to `zig-out/bin` just like how **Zig** normally does. Note that our artifact for our project is called "my-wtf-project" because we put that name in `.name` during our call to `Build.addExecutable`.


```zig
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        // the name of our project artifact (executable)
        .name = "my-wtf-project",
        // we point to our project code
        .root_source_file = .{ .path = "testzon.zig" },
        .target = target,
        .optimize = optimize,
    });

    // we depends on duckdb.zig artifact
    // this is the name in build.zig.zon
    const duck = b.dependency("duck", .{
        .target = target,
        .optimize = optimize,
    });
    exe.installLibraryHeaders(duck.artifact("duck"));
    exe.addModule("duck", duck.module("duck"));
    exe.linkLibrary(duck.artifact("duck"));

    // install_prefix by default is "zig-out"
    const path = try std.fmt.allocPrint(b.allocator, "{s}/lib", .{b.install_prefix});
    defer b.allocator.free(path);
    // we need to somehow refer to the location of the libduckdb.so
    exe.addLibraryPath(path);
    exe.linkSystemLibraryName("duckdb");
    // libduckdb requires libC
    exe.linkLibC();

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);
}
```

## Running the executable

Note that in order to run our executable, we need to tell it where to find `libduckdb.so`.
 
The easiest way I found is to invoke our exectable like `LID_LIBRARY_PATH=zig-out/lib my-wtf-project`.

```fish
~/w/z/wtf-zig-zon master• ❱ LD_LIBRARY_PATH=zig-out/lib zig-out/bin/my-wtf-project
duckdb: opened in-memory db
duckdb: db connected
duckdb: query sql select * from pragma_version();
Database version is v0.8.1


STOPPED!

Leaks detected: false
```

## Bonus: Cache

When the **Zig** Package Manager pulls down the packages, it saves them under `.cache/zig`. What it means is that once you have pulled down a package, you don't need network to pull down the same package again. However, there are times where the **Zig** Package Manager doesn't update/work properly, you'll need to delete the cache specific to your package and tell **Zig** to re-download the package.

The following command will remove all the packages from your cache:

```fish
rm -rf ~/.cache/zig/*
```

## The End

You can find the code [here](https://github.com/edyu/wtf-zig-zon).

## ![Zig Logo](https://ziglang.org/zero.svg)
