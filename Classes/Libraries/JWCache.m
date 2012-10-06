//
//  JWCache.m
//  DGSPhone
//
//  Created by Justin Weiss on 10/5/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import "JWCache.h"
#import "JWCacheEntry.h"

@interface JWCache ()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation JWCache

- (id)init
{
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _cache.delegate = self;
    }
    return self;
}

#pragma mark - Caching methods


- (id)objectForKey:(NSString *)key {
    JWCacheEntry *entry = [self entryForKey:key];
    if (entry && ![entry hasExpired]) {
        return entry.value;
    } else {
        return nil;
    }
}

- (JWCacheEntry *)entryForKey:(NSString *)key {
    JWCacheEntry *entry = [self.cache objectForKey:key];
    return entry;
}

- (void)setObject:(id)object forKey:(NSString *)key ttl:(NSTimeInterval)ttl {
    JWCacheEntry *entry = [[JWCacheEntry alloc] initWithKey:key value:object ttl:ttl];
    [self.cache setObject:entry forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    [self.cache removeObjectForKey:key];
}

- (void)removeAllObjects {
    [self.cache removeAllObjects];
}

// Try to retrieve the object with a key from the cache. If the object hasn't
// been cached, fetch the new data using fetchBlock. fetchBlock is responsible
// for returning the value that should be returned from this method.
// gotObjectBlock (passed to fetchBlock) is a thunk that should be used to cache
// the value after retrieval. completionBlock can be called twice -- once with
// stale data, and again with the freshly fetched data.
- (id)fetchObjectForKey:(NSString *)key
                    ttl:(NSTimeInterval)ttl
             fetchBlock:(CacheFetchBlock)fetchBlock
             completion:(CacheCompletionBlock)completion {
    id returnValue;
    JWCacheEntry *cachedEntry = [self entryForKey:key];
    id cachedObject = cachedEntry.value;
    BOOL needsRefresh = YES;
    
    if (cachedObject) {
        completion(cachedObject);
        
        if ([cachedEntry hasExpired]) {
            [self removeObjectForKey:key];
            needsRefresh = YES;
        } else {
            needsRefresh = NO;
        }
    }
    
    if (needsRefresh) {
        CacheCallbackBlock gotObjectBlock = ^(id object) {
            if (object) {
                [self setObject:object forKey:key ttl:ttl];
            }
            completion(object);
        };
        
        returnValue = fetchBlock(self, gotObjectBlock);
    }
    
    return returnValue;
}

#pragma mark - NSCacheDelegate methods

- (void)cache:(NSCache *)cache willEvictObject:(id)obj {
    // ignore evictions for now -- we'll just be an in-memory cache
}

@end
