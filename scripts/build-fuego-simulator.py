#!/usr/bin/env python3
"""Rebuild pinned Fuego 1.1 for Apple Silicon simulators (requires installed Pods)."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import urllib.request

root = Path(__file__).resolve().parents[1]
work = root / '.build'
work.mkdir(exist_ok=True)
source = work / 'fuego-source'
revision = 'e9d16cf9818fef896b92af702aaeafcf2aafac2d'
if not source.exists():
    subprocess.run(['git', 'clone', 'https://github.com/justinweiss/fuego-framework.git', str(source)], check=True)
subprocess.run(['git', 'checkout', '--detach', revision], cwd=source, check=True)
archive = work / 'fuego-1.1.tar.gz'
if not archive.exists():
    urllib.request.urlretrieve('https://downloads.sourceforge.net/project/fuego/fuego/1.1/fuego-1.1.tar.gz', archive)
assert hashlib.sha256(archive.read_bytes()).hexdigest() == 'c61d18293670c3cde8cc8b7b28ae037a85a4b8018827f2a0f93e34b165bc16ce', 'Fuego archive checksum mismatch'
if not (source / 'fuego').exists():
    with tarfile.open(archive) as tar:
        for member in tar.getmembers():
            assert not member.name.startswith('/') and '..' not in Path(member.name).parts
            assert not member.issym() and not member.islnk()
        tar.extractall(source)
    (source / 'fuego-1.1').rename(source / 'fuego')
    for name, strip in [('fuego_boost_1_46.diff', 2), ('fuego_boost_1_51.diff', 2), ('fuego_llvm.diff', 2), ('fuego_clang.diff', 1), ('fuego_ndebug.diff', 1)]:
        with (source / 'patches' / name).open() as patch:
            subprocess.run(['patch', f'-p{strip}', '--forward'], cwd=source, stdin=patch, check=True)
    path = source / 'fuego/smartgame/SgGtpCommands.cpp'
    path.write_text(path.read_text().replace('int retval = system(s.str().c_str());', 'throw GtpFailure("External debuggers are unavailable on iOS");\n    int retval = 0;'))
env = os.environ.copy()
env.setdefault('DEVELOPER_DIR', '/Applications/Xcode.app/Contents/Developer')
subprocess.run(['xcodebuild', '-project', str(source / 'fuego.xcodeproj'), '-target', 'fuego', '-configuration', 'Release', '-sdk', 'iphonesimulator', 'ARCHS=arm64 x86_64', 'IPHONEOS_DEPLOYMENT_TARGET=15.0', f'FRAMEWORK_SEARCH_PATHS={root}/Pods/boost-framework', 'CLANG_CXX_LANGUAGE_STANDARD=gnu++14', 'CODE_SIGNING_ALLOWED=NO', 'build'], env=env, check=True)
framework = work / 'simulator-frameworks/fuego.framework'
framework.mkdir(parents=True, exist_ok=True)
shutil.copytree(source / 'build/Release-iphonesimulator/Headers', framework / 'Headers', dirs_exist_ok=True)
shutil.copy2(source / 'build/Release-iphonesimulator/libfuego.a', framework / 'fuego')
print('Built Fuego for arm64 and x86_64 iOS simulators')
