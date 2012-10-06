//
//  JWCacheEntry.h
//  DGSPhone
//
//  Created by Justin Weiss on 10/5/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWCacheEntry : NSObject<NSCoding>

@property(nonatomic, strong) NSString *key;
@property(nonatomic, strong) id value;
@property(nonatomic, strong) NSDate *expiresAt;

- (id)initWithKey:(NSString *)key value:(id)value ttl:(NSTimeInterval)ttl;
- (BOOL)hasExpired;

@end
