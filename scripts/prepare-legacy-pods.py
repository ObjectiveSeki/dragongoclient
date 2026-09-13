#!/usr/bin/env python3
"""Apply repeatable SDK compatibility fixes after pod install."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
project = root / 'Pods/Pods.xcodeproj/project.pbxproj'
text = project.read_text()
text = re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = [^;]+;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;', text)
project.write_text(text)
header = root / 'Pods/Reachability/Reachability.h'
text = header.read_text().replace('#import <netinet6/in6.h>', '// IPv6 types come from the public netinet/in.h header.')
header.chmod(header.stat().st_mode | 0o200)
header.write_text(text)

# Only header-only Boost APIs are used by the client's board and SGF code.
# The old boost binary contains an iOS arm64 slice, not an arm64 simulator slice.
for config in (root / 'Pods/Target Support Files/Pods-DGS').glob('*.xcconfig'):
    config.write_text(config.read_text().replace('-framework "boost"', ''))

operation = root / 'Pods/MKNetworkKit/MKNetworkKit/MKNetworkOperation.m'
text = operation.read_text().replace('DLog(@"%@, [%@]", self, [self.error localizedDescription]);', 'DLog(@"Request failed: %@", [self.error localizedDescription]);')
operation.chmod(operation.stat().st_mode | 0o200)
operation.write_text(text)
