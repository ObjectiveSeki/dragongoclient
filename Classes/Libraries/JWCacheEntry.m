//
//  JWCacheEntry.m
//  DGSPhone
//
//  Created by Justin Weiss on 10/5/12.
//  Copyright (c) 2012 Justin Weiss. All rights reserved.
//

#import "JWCacheEntry.h"

@implementation JWCacheEntry

+ (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:@"DGSCache"];
}

+ (void)flushCache {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self cacheDirectory] error:nil];
}

+ (NSString *)cachedFilenameForKey:(NSString *)key {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDirectory = [self cacheDirectory];
    [fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    
    return [cacheDirectory stringByAppendingPathComponent:S(@"%@.cache", key)];
}

- (id)initWithKey:(NSString*)aKey value:(id)aValue ttl:(NSTimeInterval)ttl {
    self = [super init];
    if (self) {
        _key = aKey;
        _value = aValue;
        _expiresAt = [NSDate dateWithTimeIntervalSinceNow:ttl];
        _shouldPersist = YES;
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.key forKey:@"key"];
    [encoder encodeObject:self.value forKey:@"value"];
    [encoder encodeObject:self.expiresAt forKey:@"expiresAt"];
    [encoder encodeBool:self.shouldPersist forKey:@"shouldPersist"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.key = [decoder decodeObjectForKey:@"key"];
        self.value = [decoder decodeObjectForKey:@"value"];
        self.expiresAt = [decoder decodeObjectForKey:@"expiresAt"];
        self.shouldPersist = [decoder decodeBoolForKey:@"shouldPersist"];
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

- (void)removeFromDisk {
    NSString *path = [[self class] cachedFilenameForKey:self.key];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:path error:nil];
}

- (void)writeToDisk {
    if (self.shouldPersist) {
        NSString *path = [[self class] cachedFilenameForKey:self.key];
        [NSKeyedArchiver archiveRootObject:self toFile:path];
    } else {
        [self removeFromDisk];
    }
}

+ (JWCacheEntry *)readFromDisk:(NSString *)key {
    JWCacheEntry *entry = [NSKeyedUnarchiver unarchiveObjectWithFile:[self cachedFilenameForKey:key]];
    return entry;
}

@end
