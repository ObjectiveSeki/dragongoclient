#!/usr/bin/env python3
"""Run actual registration callbacks against in-memory doubles on macOS.

No app account, Keychain, network, simulator, or project changes are required.
"""
import os
import re
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'Classes/Network/DGSPushServer.m').read_text()
names = ['isCurrentRegistration:', 'beginQueueingRequestsRequiringLogin',
         'clearQueueingRequestsRequiringLogin', 'createLoginCookies:',
         'createAPNSDeviceToken:', 'updateAPNSDeviceToken:',
         'deleteAPNSDeviceTokenForPlayerId:']
methods = []
for name in names:
    # Find the declaration, not a call to it.
    match = re.search(r'^- \([^\n]+\)' + re.escape(name), source, re.M)
    start = match.start()
    end = source.index('\n}', start) + 2
    methods.append(source[start:end])

prefix = r'''
#import <Foundation/Foundation.h>
#define S(...) [NSString stringWithFormat:__VA_ARGS__]
#define APNSDeviceIdUserDefaultsKey @"PushRegistrationTestUnused"
typedef void (^EmptyBlock)(void);
typedef void (^MKNKErrorBlock)(NSError *);
@interface Player : NSObject
@property NSNumber *userId;
+ (Player *)currentPlayer;
@end
@implementation Player
+ (Player *)currentPlayer { static Player *p; if (!p) p=[Player new]; return p; }
@end
@interface NSData (TestEncoding)
- (NSString *)base64EncodedString;
@end
@implementation NSData (TestEncoding)
- (NSString *)base64EncodedString { return [self base64EncodedStringWithOptions:0]; }
@end
@interface MKNetworkOperation : NSObject
@property NSDictionary *responseJSON;
@property(copy) void (^success)(MKNetworkOperation *);
@property(copy) void (^failure)(MKNetworkOperation *, NSError *);
- (void)addCompletionHandler:(void (^)(MKNetworkOperation *))success errorHandler:(void (^)(MKNetworkOperation *, NSError *))failure;
@end
@implementation MKNetworkOperation
- (void)addCompletionHandler:(void (^)(MKNetworkOperation *))s errorHandler:(void (^)(MKNetworkOperation *, NSError *))f { self.success=s; self.failure=f; }
@end
@interface Harness : NSObject
@property NSUInteger registrationGeneration;
@property BOOL registrationReady;
@property NSOperationQueue *delayedNetworkOperationQueue;
@property NSString *pushToken;
@property NSNumber *fakeDeviceId;
@property NSUInteger writes;
@property NSUInteger failures;
'''
declarations = '\n'.join(m.split(' {', 1)[0] + ';' for m in methods)
mocks = r'''
- (NSNumber *)deviceId;
- (void)enqueueOperation:(MKNetworkOperation *)op;
- (void)setDeviceIdFromResponse:(NSDictionary *)response;
- (void)didFailToRetrieveDeviceId;
- (void)storePushToken:(NSString *)token forPlayerId:(NSNumber *)player;
- (NSMutableDictionary *)paramsFromLoginCookies:(NSArray *)cookies;
- (MKNetworkOperation *)operationWithPath:(NSString *)path params:(NSDictionary *)params httpMethod:(NSString *)method;
@end
@implementation Harness
- (NSNumber *)deviceId { return self.fakeDeviceId; }
- (void)enqueueOperation:(MKNetworkOperation *)op {}
- (void)setDeviceIdFromResponse:(NSDictionary *)response { self.writes++; self.registrationReady=YES; }
- (void)didFailToRetrieveDeviceId { self.failures++; [self clearQueueingRequestsRequiringLogin]; }
- (void)storePushToken:(NSString *)token forPlayerId:(NSNumber *)player { self.writes++; self.pushToken=token; }
- (NSMutableDictionary *)paramsFromLoginCookies:(NSArray *)cookies { return [NSMutableDictionary new]; }
- (MKNetworkOperation *)operationWithPath:(NSString *)path params:(NSDictionary *)params httpMethod:(NSString *)method { return [MKNetworkOperation new]; }
'''
tests = r'''
@end
int main(void) { @autoreleasepool {
  for (int kind=0; kind<3; kind++) for (int failure=0; failure<2; failure++) for (int transition=0; transition<3; transition++) {
    Harness *h=[Harness new]; [Player currentPlayer].userId=@42;
    [h beginQueueingRequestsRequiringLogin];
    EmptyBlock done=^{}; MKNKErrorBlock error=^(NSError *e){};
    MKNetworkOperation *op;
    if (kind==0) op=[h createLoginCookies:@[@1] completionHandler:done errorHandler:error];
    else if (kind==1) op=[h createAPNSDeviceToken:[NSData data] completionHandler:done errorHandler:error];
    else { h.fakeDeviceId=@1; op=[h updateAPNSDeviceToken:[NSData data] completionHandler:done errorHandler:error]; }
    if (transition) {
      h.fakeDeviceId=nil; // Exercise logout before device registration completes.
      [h deleteAPNSDeviceTokenForPlayerId:@42 completionHandler:done errorHandler:error];
      [Player currentPlayer].userId=transition==1 ? @43 : @42;
      [h beginQueueingRequestsRequiringLogin];
    }
    op.responseJSON=@{@"token":@"test", @"id":@1};
    if (failure) op.failure(op, [NSError errorWithDomain:@"test" code:1 userInfo:nil]); else op.success(op);
    NSCAssert(h.writes==(transition || failure ? 0 : 1), @"Unexpected stale success mutation");
    NSCAssert(h.failures==(!transition && failure ? 1 : 0), @"Unexpected stale failure mutation");
    [h clearQueueingRequestsRequiringLogin];
  }
  puts("18 registration callback cases passed (session/POST/PUT, success/failure, current/different/same-account login).");
} }
'''
with tempfile.TemporaryDirectory(prefix='dgs-registration-tests-') as directory:
    path = Path(directory)
    (path / 'test.m').write_text(prefix + declarations + mocks + '\n'.join(methods) + tests)
    env = os.environ.copy()
    env.setdefault('DEVELOPER_DIR', '/Applications/Xcode.app/Contents/Developer')
    subprocess.run(['xcrun', '--sdk', 'macosx', 'clang', '-fobjc-arc', '-fblocks',
                    '-framework', 'Foundation', str(path / 'test.m'), '-o', str(path / 'test')], env=env, check=True)
    subprocess.run([str(path / 'test')], check=True)
