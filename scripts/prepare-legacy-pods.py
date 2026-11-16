#!/usr/bin/env python3
"""Apply repeatable SDK compatibility and security fixes after pod install."""
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
# MKNetworkKit accepts recoverable trust failures (including mismatched hosts).
# Both DGS and push requests must instead use Apple's default TLS validation.
# Otherwise an invalid certificate could permit interception of authenticated traffic.
# Patch here so reinstalling Pods cannot silently restore the unsafe trust handler.
challenge_method = '- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {'
secure_start = challenge_method + '''
  // Always validate server certificates using the system trust policy.
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
    [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    return;
  }
'''
if secure_start not in text:
    # Keep the generated marker stable: a second run must recognize the patched delegate.
    start = text.index('    else if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {')
    end = text.index('    else if (self.authHandler)', start)
    text = text[:start] + text[end:]
    if text.count(challenge_method) != 1:
        raise RuntimeError('Unexpected MKNetworkKit authentication implementation')
    text = text.replace(challenge_method, secure_start)
if 'kSecTrustResultRecoverableTrustFailure' in text:
    # Refuse to prepare a build if the known certificate-validation bypass remains.
    raise RuntimeError('Unsafe MKNetworkKit server trust override remains')
operation.chmod(operation.stat().st_mode | 0o200)
operation.write_text(text)
