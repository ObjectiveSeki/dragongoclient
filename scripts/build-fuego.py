#!/usr/bin/env python3
"""Build pinned Fuego 1.1 frameworks directly from upstream source.

The compatibility changes preserve the behavior of Justin Weiss's historical
fuego-framework recipe without cloning that repository or using its binaries.
"""

from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / ".build" / "fuego"
DOWNLOADS = BUILD / "downloads"
SOURCES = BUILD / "sources"
OBJECTS = BUILD / "objects"
PRODUCTS = BUILD / "products"
DEPLOYMENT_TARGET = "15.0"
os.environ.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")

FUEGO = {
    "version": "1.1",
    "url": "https://downloads.sourceforge.net/project/fuego/fuego/1.1/fuego-1.1.tar.gz",
    "sha256": "c61d18293670c3cde8cc8b7b28ae037a85a4b8018827f2a0f93e34b165bc16ce",
    "archive": "fuego-1.1.tar.gz",
    "root": "fuego-1.1",
}
BOOST = {
    "version": "1.58.0",
    "url": "https://archives.boost.io/release/1.58.0/source/boost_1_58_0.tar.bz2",
    "sha256": "fdfc204fc33ec79c99b9a74944c3e54bd78be4f7f15e260c0e2700a36dc7d3e5",
    "archive": "boost_1_58_0.tar.bz2",
    "root": "boost_1_58_0",
    "members": ("boost", "LICENSE_1_0.txt"),
}


def run(arguments, **kwargs):
    return subprocess.run(arguments, check=True, text=True, **kwargs)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(spec):
    DOWNLOADS.mkdir(parents=True, exist_ok=True)
    destination = DOWNLOADS / spec["archive"]
    if destination.exists() and sha256(destination) == spec["sha256"]:
        return destination
    if destination.exists():
        destination.unlink()
    temporary = destination.with_suffix(destination.suffix + ".part")
    if temporary.exists():
        temporary.unlink()
    print(f"Downloading {spec['archive']} from {spec['url']}")
    try:
        with urllib.request.urlopen(spec["url"], timeout=60) as response, temporary.open("wb") as output:
            shutil.copyfileobj(response, output)
        actual = sha256(temporary)
        if actual != spec["sha256"]:
            raise RuntimeError(
                f"Checksum mismatch for {spec['archive']}: expected {spec['sha256']}, got {actual}"
            )
        temporary.replace(destination)
    finally:
        if temporary.exists():
            temporary.unlink()
    return destination


def safe_extract(archive, expected_root, destination, selected_members=None):
    with tempfile.TemporaryDirectory(dir=BUILD, prefix="extract-") as temporary_name:
        temporary = Path(temporary_name)
        with tarfile.open(archive) as tar:
            members = []
            for member in tar.getmembers():
                parts = Path(member.name).parts
                if not parts or parts[0] != expected_root or ".." in parts:
                    raise RuntimeError(f"Unsafe archive member: {member.name}")
                if member.issym() or member.islnk():
                    raise RuntimeError(f"Archive links are not allowed: {member.name}")
                if not member.isdir() and not member.isfile():
                    raise RuntimeError(f"Unsupported archive member: {member.name}")
                relative = parts[1:]
                if selected_members and relative and relative[0] not in selected_members:
                    continue
                members.append(member)
            tar.extractall(temporary, members=members)
        extracted = temporary / expected_root
        if not extracted.is_dir():
            raise RuntimeError(f"Archive did not contain {expected_root}")
        if destination.exists():
            shutil.rmtree(destination)
        extracted.rename(destination)


def replace(path, old, new, expected=1):
    text = path.read_text(encoding="latin-1")
    actual = text.count(old)
    if actual != expected:
        raise RuntimeError(f"Expected {expected} occurrence(s) in {path}, found {actual}")
    path.write_text(text.replace(old, new), encoding="latin-1")


def patch_fuego(source):
    source_directories = [source / name for name in ("go", "gouct", "gtpengine", "smartgame")]
    source_files = [
        path
        for directory in source_directories
        for path in directory.iterdir()
        if path.suffix in (".h", ".cpp")
    ]
    # Fuego's public C++ types change layout with this flag. Give it a dedicated
    # name so Debug app code and the Release library always agree on their ABI.
    ndebug_count = sum(path.read_text(encoding="latin-1").count("NDEBUG") for path in source_files)
    if ndebug_count != 51:
        raise RuntimeError(f"Expected 51 NDEBUG references in Fuego 1.1, found {ndebug_count}")
    for path in source_files:
        text = path.read_text(encoding="latin-1")
        path.write_text(text.replace("NDEBUG", "FUEGO_NDEBUG"), encoding="latin-1")

    # Adapt removed Boost 1.58 APIs and namespace ambiguities in modern Clang.
    replace(source / "go/GoGtpEngine.cpp", ".native_file_string()", ".string()")
    replace(source / "go/GoGtpEngine.cpp", "boost::TIME_UTC", "boost::TIME_UTC_", 1)
    replace(source / "gtpengine/GtpEngine.cpp", "boost::TIME_UTC", "boost::TIME_UTC_", 1)
    replace(
        source / "smartgame/SgHash.h",
        "std::ostream& operator>>(std::istream& in, const SgHash<N>& hash)",
        "std::istream& operator>>(std::istream& in, const SgHash<N>& hash)",
    )
    replace(
        source / "smartgame/SgPointSetUtil.h",
        "mutable SgPointSet& m_pointSet;",
        "SgPointSet& m_pointSet;",
    )

    for relative_path in ("gtpengine/GtpEngine.cpp", "smartgame/SgUctSearch.cpp"):
        path = source / relative_path
        text = path.read_text(encoding="latin-1")
        if "void Notify(mutex&" not in text or "mutex::scoped_lock" not in text:
            raise RuntimeError(f"Unexpected mutex declarations in {path}")
        text = text.replace("void Notify(mutex&", "void Notify(boost::mutex&")
        text = text.replace("mutex::scoped_lock", "boost::mutex::scoped_lock")
        text = text.replace("    mutex m_", "    boost::mutex m_")
        path.write_text(text, encoding="latin-1")

    replace(
        source / "smartgame/SgUctSearch.cpp",
        "shared_ptr<Thread> thread(new Thread(*this, state));",
        "boost::shared_ptr<Thread> thread(new Thread(*this, state));",
    )
    replace(
        source / "smartgame/SgUctTree.cpp",
        "m_stack.push(shared_ptr<SgUctChildIterator>(it));",
        "m_stack.push(boost::shared_ptr<SgUctChildIterator>(it));",
    )

    process_header = source / "smartgame/SgProcess.h"
    replace(
        process_header,
        "// Not yet implemented for Windows\n#ifndef WIN32\n\n#include <ext/stdio_filebuf.h> // GCC specific\n#include <iosfwd>\n#include <memory>",
        "#include <iosfwd>\n\n// Process launching is unavailable with Apple's Clang/iOS runtime.\n#if defined(__GNUC__) && ! defined(__clang__)\n#include <ext/stdio_filebuf.h> // GCC specific\n#include <memory>",
    )
    replace(
        process_header,
        "//----------------------------------------------------------------------------\n\n#endif // ifndef WIN32\n\n#endif // SG_PROCESS_H",
        "//----------------------------------------------------------------------------\n\n#else\n\nclass SgProcess\n{\npublic:\n    SgProcess(const std::string& command);\n    ~SgProcess();\n};\n\n#endif // defined(__GNUC__) && ! defined(__clang__)\n\n#endif // SG_PROCESS_H",
    )

    process_source = source / "smartgame/SgProcess.cpp"
    replace(
        process_source,
        '#include "SgProcess.h"\n\n// Not yet implemented for Windows\n#ifndef WIN32\n\n'
        '#include <errno.h>\n#include <fstream>\n#include <iostream>\n#include <stdio.h>\n#include <stdlib.h>\n'
        '#include <string.h>\n#include <sys/types.h>\n#include <unistd.h>\n#include "SgDebug.h"\n'
        '#include "SgException.h"\n#include "SgStringUtil.h"',
        '#include "SgProcess.h"\n#include "SgException.h"\n\n'
        '// Process launching is unavailable with Apple\'s Clang/iOS runtime.\n'
        '#if defined(__GNUC__) && ! defined(__clang__)\n\n'
        '#include <errno.h>\n#include <fstream>\n#include <iostream>\n#include <stdio.h>\n#include <stdlib.h>\n'
        '#include <string.h>\n#include <sys/types.h>\n#include <unistd.h>\n#include "SgDebug.h"\n'
        '#include "SgStringUtil.h"',
    )
    replace(
        process_source,
        "}\n\nSgProcess::~SgProcess()",
        '}'
        '\n\n#else\n\nSgProcess::SgProcess(const std::string& command)\n'
        '{\n    SG_UNUSED(command);\n    throw SgException("SgProcess is unavailable on iOS");\n}'
        '\n\n#endif // defined(__GNUC__) && ! defined(__clang__)\n\nSgProcess::~SgProcess()',
    )
    replace(process_source, "\n//----------------------------------------------------------------------------\n\n#endif // ifndef WIN32", "\n//----------------------------------------------------------------------------")

    replace(
        source / "smartgame/SgGtpCommands.cpp",
        '    int retval = system(s.str().c_str());\n'
        '    if (retval != 0)\n'
        '        throw GtpFailure() << "command returned " << retval;',
        '    throw GtpFailure("External debuggers are unavailable on iOS");',
    )


def prepare_sources(spec, destination, patch=None):
    archive = download(spec)
    stamp = destination / ".dragon-go-source"
    recipe = spec["sha256"]
    if spec.get("members"):
        recipe += ":" + ",".join(spec["members"])
    if patch is not None:
        recipe += ":" + sha256(Path(__file__))
    if stamp.exists() and stamp.read_text() == recipe:
        return destination
    destination.parent.mkdir(parents=True, exist_ok=True)
    safe_extract(archive, spec["root"], destination, spec.get("members"))
    if patch is not None:
        patch(destination)
    stamp.write_text(recipe)
    return destination


def xcrun(sdk, *arguments):
    environment = os.environ.copy()
    environment.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")
    result = run(["xcrun", "--sdk", sdk, *arguments], env=environment, capture_output=True)
    return result.stdout.strip()


def compile_one(compiler, source, output, common_flags, platform_flags, environment):
    result = subprocess.run(
        [compiler, "-c", str(source), "-o", str(output), *common_flags, *platform_flags],
        env=environment,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Failed compiling {source.name}:\n{result.stdout}{result.stderr}")


def build_archives(fuego_source, boost_source):
    source_directories = [fuego_source / name for name in ("go", "gouct", "gtpengine", "smartgame")]
    sources = sorted(path for directory in source_directories for path in directory.glob("*.cpp"))
    if len(sources) != 102 or len({path.name for path in sources}) != len(sources):
        raise RuntimeError("The pinned Fuego source manifest changed")

    environment = os.environ.copy()
    environment.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")
    include_flags = [f"-I{boost_source}"] + [f"-I{directory}" for directory in source_directories]
    common_flags = [
        "-std=gnu++14",
        "-stdlib=libc++",
        "-O2",
        "-DNDEBUG",
        "-DFUEGO_NDEBUG",
        "-DBOOST_AC_USE_PTHREADS",
        "-DBOOST_SP_USE_PTHREADS",
        "-fvisibility=hidden",
        "-fvisibility-inlines-hidden",
        "-Wno-deprecated-builtins",
        "-Wno-deprecated-declarations",
        "-Wno-deprecated-increment-bool",
        *include_flags,
    ]
    variants = [
        ("iphoneos-arm64", "iphoneos", "arm64", f"-miphoneos-version-min={DEPLOYMENT_TARGET}"),
        ("iphonesimulator-arm64", "iphonesimulator", "arm64", f"-mios-simulator-version-min={DEPLOYMENT_TARGET}"),
        ("iphonesimulator-x86_64", "iphonesimulator", "x86_64", f"-mios-simulator-version-min={DEPLOYMENT_TARGET}"),
    ]
    compilers = {sdk: xcrun(sdk, "--find", "clang++") for _, sdk, _, _ in variants}
    sdk_paths = {sdk: xcrun(sdk, "--show-sdk-path") for _, sdk, _, _ in variants}

    if OBJECTS.exists():
        shutil.rmtree(OBJECTS)
    tasks = []
    for variant, sdk, architecture, minimum_flag in variants:
        directory = OBJECTS / variant
        directory.mkdir(parents=True)
        platform_flags = ["-arch", architecture, "-isysroot", sdk_paths[sdk], minimum_flag]
        for source in sources:
            tasks.append(
                (compilers[sdk], source, directory / f"{source.stem}.o", common_flags, platform_flags, environment)
            )

    workers = min(8, os.cpu_count() or 1)
    print(f"Compiling Fuego {FUEGO['version']} for iPhone and Simulator with {workers} workers")
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(compile_one, *task) for task in tasks]
        for future in as_completed(futures):
            future.result()

    archives = {}
    for variant, sdk, _, _ in variants:
        directory = OBJECTS / variant
        archive = directory / "libfuego.a"
        objects = sorted(directory.glob("*.o"))
        run(["xcrun", "libtool", "-static", "-o", str(archive), *map(str, objects)], env=environment)
        archives[variant] = archive
    return archives


def create_frameworks(fuego_source, archives):
    if PRODUCTS.exists():
        shutil.rmtree(PRODUCTS)
    headers = sorted(
        path
        for name in ("go", "gouct", "gtpengine", "smartgame")
        for path in (fuego_source / name).glob("*.h")
    )
    if len(headers) != 136 or len({path.name for path in headers}) != len(headers):
        raise RuntimeError("The pinned Fuego header manifest changed")

    device = PRODUCTS / "iphoneos/fuego.framework"
    simulator = PRODUCTS / "iphonesimulator/fuego.framework"
    for framework in (device, simulator):
        header_directory = framework / "Headers"
        header_directory.mkdir(parents=True)
        for header in headers:
            shutil.copy2(header, header_directory / header.name)

    shutil.copy2(archives["iphoneos-arm64"], device / "fuego")
    run(
        [
            "xcrun",
            "lipo",
            "-create",
            str(archives["iphonesimulator-arm64"]),
            str(archives["iphonesimulator-x86_64"]),
            "-output",
            str(simulator / "fuego"),
        ]
    )


def write_manifest():
    environment = os.environ.copy()
    environment.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")
    xcode = run(["xcodebuild", "-version"], env=environment, capture_output=True).stdout.strip().splitlines()
    manifest = {
        "deployment_target": DEPLOYMENT_TARGET,
        "recipe_sha256": sha256(Path(__file__)),
        "xcode": xcode,
        "fuego": {key: FUEGO[key] for key in ("version", "url", "sha256")},
        "boost": {key: BOOST[key] for key in ("version", "url", "sha256")},
        "products": {
            "iphoneos": sha256(PRODUCTS / "iphoneos/fuego.framework/fuego"),
            "iphonesimulator": sha256(PRODUCTS / "iphonesimulator/fuego.framework/fuego"),
        },
    }
    (BUILD / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")


def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    fuego_source = prepare_sources(FUEGO, SOURCES / FUEGO["root"], patch_fuego)
    boost_source = prepare_sources(BOOST, SOURCES / BOOST["root"])
    recipe = sha256(Path(__file__))
    recipe_stamp = PRODUCTS / ".recipe-sha256"
    product_binaries = [
        PRODUCTS / "iphoneos/fuego.framework/fuego",
        PRODUCTS / "iphonesimulator/fuego.framework/fuego",
        BUILD / "manifest.json",
    ]
    if (
        recipe_stamp.exists()
        and recipe_stamp.read_text() == recipe
        and all(path.is_file() for path in product_binaries)
    ):
        print("Pinned Fuego device and simulator frameworks are already built")
        return
    archives = build_archives(fuego_source, boost_source)
    create_frameworks(fuego_source, archives)
    write_manifest()
    recipe_stamp.write_text(recipe)
    print(f"Built Fuego frameworks under {PRODUCTS}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Fuego build failed: {error}", file=sys.stderr)
        raise SystemExit(1)
