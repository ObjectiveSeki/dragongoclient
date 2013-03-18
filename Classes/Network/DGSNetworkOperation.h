//
//  DGSNetworkOperation.h
//  DGSPhone
//
//  Created by Justin Weiss on 2/26/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "MKNetworkKit.h"

enum {
    kDGSErrorCodeGenericError,
    kDGSErrorCodeLoginError
};

extern NSString * const kDGSErrorDomain;

@interface DGSNetworkOperation : MKNetworkOperation

@end
