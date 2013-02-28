//
//  DGS.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameServerProtocol.h"
#import "MKNetworkKit.h"

typedef void (^DGSResponseBlock)(MKNetworkOperation *operation, NSString *responseString);

@interface DGS : MKNetworkEngine <GameServerProtocol>

- (NSDictionary *)defaultCustomHeaderFields;

@end
