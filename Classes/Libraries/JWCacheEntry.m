//
//  JWCacheEntry.m
//  DGSPhone
//
//  Created by Justin Weiss on 10/5/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import "JWCacheEntry.h"

@implementation JWCacheEntry

- (id)initWithKey:(NSString*)aKey value:(id)aValue ttl:(NSTimeInterval)ttl {
    self = [super init];
    if (self) {
        _key = aKey;
        _value = aValue;
        _expiresAt = [NSDate dateWithTimeIntervalSinceNow:ttl];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.key forKey:@"key"];
    [encoder encodeObject:self.value forKey:@"value"];
    [encoder encodeObject:self.expiresAt forKey:@"expiresAt"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.key = [decoder decodeObjectForKey:@"key"];
        self.value = [decoder decodeObjectForKey:@"value"];
        self.expiresAt = [decoder decodeObjectForKey:@"expiresAt"];
    }
    return self;
}

- (BOOL)hasExpired {
    if (self.expiresAt) {
        return ([self.expiresAt compare:[NSDate date]] == NSOrderedAscending);
    } else {
        return NO;
    }
}

@end
