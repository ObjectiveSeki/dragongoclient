//
//  JWCache.h
//  DGSPhone
//
//  Created by Justin Weiss on 10/5/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JWCache;

typedef void (^CacheCompletionBlock)(id object);
typedef void (^CacheCallbackBlock)(id object);
typedef id (^CacheFetchBlock)(JWCache *cache, CacheCallbackBlock gotObject);

@interface JWCache : NSObject<NSCacheDelegate>

- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key ttl:(NSTimeInterval)ttl;
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

// Try to retrieve the object with a key from the cache. If the object hasn't
// been cached, fetch the new data using fetchBlock. fetchBlock is responsible
// for returning the value that should be returned from this method.
// gotObjectBlock (passed to fetchBlock) is a thunk that should be used to cache
// the value after retrieval. completionBlock can be called twice -- once with
// stale data, and again with the freshly fetched data.
- (id)fetchObjectForKey:(NSString *)key
                    ttl:(NSTimeInterval)ttl
             fetchBlock:(CacheFetchBlock)fetchBlock
             completion:(CacheCompletionBlock)completion;
@end
