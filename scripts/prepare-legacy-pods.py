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

operation = root / 'Pods/MKNetworkKit/MKNetworkKit/MKNetworkOperation.m'
text = operation.read_text().replace('DLog(@"%@, [%@]", self, [self.error localizedDescription]);', 'DLog(@"Request failed: %@", [self.error localizedDescription]);')
operation.chmod(operation.stat().st_mode | 0o200)
operation.write_text(text)
