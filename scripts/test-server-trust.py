#!/usr/bin/env python3
"""Verify the installed networking delegate defers TLS trust to the OS."""
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'Pods/MKNetworkKit/MKNetworkKit/MKNetworkOperation.m').read_text()
start = source.index('- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:')
method = source[start:source.index('\n}', start) + 2]
prefix = r'''
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#define DLog(...)
OSStatus extractIdentityAndTrust(CFDataRef data, SecIdentityRef *identity, SecTrustRef *trust, CFStringRef password) { return errSecUnimplemented; }
@interface Operation : NSObject
@property NSString *username;
@property NSString *password;
@property NSURLCredentialPersistence credentialPersistence;
@property NSString *clientCertificate;
@property NSString *clientCertificatePassword;
@property SecTrustRef serverTrust;
@property BOOL shouldContinueWithInvalidCertificate;
@property(copy) void (^authHandler)(NSURLAuthenticationChallenge *);
@end
@implementation Operation
'''
tests = r'''
@end
@interface Sender : NSObject<NSURLAuthenticationChallengeSender>
@property NSUInteger defaults;
@property NSUInteger overrides;
@end
@implementation Sender
- (void)performDefaultHandlingForAuthenticationChallenge:(NSURLAuthenticationChallenge *)c { self.defaults++; }
- (void)useCredential:(NSURLCredential *)credential forAuthenticationChallenge:(NSURLAuthenticationChallenge *)c { self.overrides++; }
- (void)continueWithoutCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)c { self.overrides++; }
- (void)cancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)c { self.overrides++; }
- (void)rejectProtectionSpaceAndContinueWithChallenge:(NSURLAuthenticationChallenge *)c { self.overrides++; }
@end
int main(void) { @autoreleasepool {
    // Even repeated challenges and the legacy allow-invalid flag must use system
    // validation. This checks the delegate decision, not a live interception attempt.
    for (NSUInteger failures = 0; failures < 2; failures++) for (int allowInvalid = 0; allowInvalid < 2; allowInvalid++) {
        Sender *sender = [Sender new];
        NSURLProtectionSpace *space = [[NSURLProtectionSpace alloc] initWithHost:@"untrusted.invalid" port:443 protocol:@"https" realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
        NSURLAuthenticationChallenge *challenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:space proposedCredential:nil previousFailureCount:failures failureResponse:nil error:nil sender:sender];
        Operation *operation = [Operation new];
        operation.shouldContinueWithInvalidCertificate = allowInvalid;
        [operation connection:nil willSendRequestForAuthenticationChallenge:challenge];
        NSCAssert(sender.defaults == 1 && sender.overrides == 0, @"TLS trust must always use system validation");
    }
    puts("4 server-trust cases passed: initial/repeated challenges, invalid-certificate override disabled/enabled.");
} }
'''
with tempfile.TemporaryDirectory(prefix='dgs-trust-tests-') as directory:
    path = Path(directory)
    (path / 'test.m').write_text(prefix + method + tests)
    env = os.environ.copy()
    env.setdefault('DEVELOPER_DIR', '/Applications/Xcode.app/Contents/Developer')
    subprocess.run(['xcrun', '--sdk', 'macosx', 'clang', '-fobjc-arc', '-fblocks',
                    '-Wno-deprecated-declarations', '-framework', 'Foundation', '-framework', 'Security',
                    str(path / 'test.m'), '-o', str(path / 'test')], env=env, check=True)
    subprocess.run([str(path / 'test')], check=True)
