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
- (id)fetchObjectForKey:(NSString *)key
                    ttl:(NSTimeInterval)ttl
             fetchBlock:(CacheFetchBlock)fetchBlock
             completion:(CacheCompletionBlock)completion;
@end
