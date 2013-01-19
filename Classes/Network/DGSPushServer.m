//
//  DGSPushServer.m
//  DGSPhone
//
//  Created by Justin Weiss on 1/19/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "DGSPushServer.h"
#import "Player.h"
#import "UIDevice+ExtraDeviceDetails.h"

#define APNSDeviceIdUserDefaultsKey @"APNSDeviceId"

@implementation DGSPushServer

- (id)init
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSDictionary *headerFields = @{ @"X-client-identifier": @"Dragon Go Client iOS",
                                    @"X-bundle-identifier": [infoDictionary objectForKey:@"CFBundleIdentifier"],
                                    @"X-client-version": S(@"Version %@ (%@)", [infoDictionary objectForKey:@"CFBundleShortVersionString"], [infoDictionary objectForKey:@"CFBundleVersion"]),
                                    @"X-ios-platform": [[UIDevice currentDevice] platform],
                                    @"X-ios-version": [[UIDevice currentDevice] systemVersion]};
    
    self = [super initWithHostName:PUSH_HOST customHeaderFields:headerFields];
    if (self) {
    }
    return self;
}

# pragma mark - Push management methods

- (void)registerForRemoteNotifications {
    if ([Player currentPlayer].userId) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
}

- (void)setDeviceIdFromResponse:(NSDictionary *)response {
    NSNumber *deviceId = response[@"id"];
    [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:APNSDeviceIdUserDefaultsKey];
}

# pragma mark - Push Server methods


// Updates the push token, creating it if we don't already hold a reference to one.
- (MKNetworkOperation *)updateAPNSDeviceToken:(NSData *)token completion:(EmptyBlock)completion error:(MKNKErrorBlock)error {
    static NSString *updateDeviceTokenPathFormat = @"/players/%@/devices/%@.json";
    NSNumber *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:APNSDeviceIdUserDefaultsKey];
    NSLog(@"apns token: %@", [token description]);
    
    if (deviceId) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[token base64EncodedString], @"device[device_token]", nil];

        MKNetworkOperation *op = [self operationWithPath:S(updateDeviceTokenPathFormat, [Player currentPlayer].userId, deviceId) params:params httpMethod:@"PUT"];
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
            [self setDeviceIdFromResponse:[completedOperation responseJSON]];
            completion();
        } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
            error(theError);
        }];

        [self enqueueOperation:op];
        return op;
    } else {
        return [self createAPNSDeviceToken:token completion:completion error:error];
    }
}

- (MKNetworkOperation *)createAPNSDeviceToken:(NSData *)token completion:(EmptyBlock)completion error:(MKNKErrorBlock)error {
    static NSString *createDeviceTokenPathFormat = @"/players/%@/devices.json";
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[token base64EncodedString], @"device[device_token]", nil];
        
    MKNetworkOperation *op = [self operationWithPath:S(createDeviceTokenPathFormat, [Player currentPlayer].userId) params:params httpMethod:@"POST"];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        [self setDeviceIdFromResponse:[completedOperation responseJSON]];
        completion();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
        error(theError);
    }];
    
    [self enqueueOperation:op];
    return op;
}

- (MKNetworkOperation *)deleteAPNSDeviceTokenForPlayerId:(NSNumber *)playerId completion:(EmptyBlock)completion error:(MKNKErrorBlock)error {
    if (!playerId) {
        return nil;
    }
    
    static NSString *deleteDeviceTokenPathFormat = @"/players/%@/devices/%@.json";
    NSNumber *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:APNSDeviceIdUserDefaultsKey];
    
    if (deviceId) {
        // Remove the token regardless of whether this call succeeds, because we can always get it back later if we need it.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:APNSDeviceIdUserDefaultsKey];
        MKNetworkOperation *op = [self operationWithPath:S(deleteDeviceTokenPathFormat, [Player currentPlayer].userId, deviceId) params:nil httpMethod:@"DELETE"];
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
            completion();
        } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
            error(theError);
        }];
        
        [self enqueueOperation:op];
        return op;
    } else {
        // pretend success
        completion();
        return nil;
    }
}


@end
