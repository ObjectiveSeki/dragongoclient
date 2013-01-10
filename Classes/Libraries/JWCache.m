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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeToDisk) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeToDisk) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    if (!entry) {
        entry = [JWCacheEntry readFromDisk:key];
        if (entry) {
            NSLog(@"Reading %@ from disk", key);
            [self.cache setObject:entry forKey:key];
        }
    }
    return entry;
}


- (void)setObject:(id)object forKey:(NSString *)key ttl:(NSTimeInterval)ttl {
    NSLog(@"Setting %@ to the cache", key);
    JWCacheEntry *entry = [[JWCacheEntry alloc] initWithKey:key value:object ttl:ttl];
    [self.cache setObject:entry forKey:key];
    NSLog(@"Finished setting %@ to the cache.", key);

}

- (void)removeObjectForKey:(NSString *)key {
    JWCacheEntry *entry = [self entryForKey:key];
    NSLog(@"Removing %@ from the cache", key);
    entry.shouldPersist = NO;
    [self.cache removeObjectForKey:key];
}

- (void)removeAllObjects {
    [self.cache removeAllObjects];
    [JWCacheEntry flushCache];
}

- (id)fetchObjectForKey:(NSString *)key
                    ttl:(NSTimeInterval)ttl
             fetchBlock:(CacheFetchBlock)fetchBlock
             completion:(CacheCompletionBlock)completion {
    id returnValue;
    JWCacheEntry *cachedEntry = [self entryForKey:key];
    id cachedObject = cachedEntry.value;
    BOOL needsRefresh = YES;
    
    if (cachedObject) {
        NSLog(@"Found cached object for %@", key);
        completion(cachedObject);
        
        if ([cachedEntry hasExpired]) {
            NSLog(@"%@ has expired, fetching new version", key);
            [self removeObjectForKey:key];
            needsRefresh = YES;
        } else {
            needsRefresh = NO;
        }
    }
    
    if (needsRefresh) {
        NSLog(@"Fetching %@", key);
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
    [obj writeToDisk];
}

- (void)writeToDisk {
    NSLog(@"Writing cache to disk...");
    [self.cache removeAllObjects];
}
@end
