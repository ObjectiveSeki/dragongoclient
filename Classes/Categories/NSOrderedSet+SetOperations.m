//
//  NSOrderedSet+SetOperations.m
//  DGSPhone
//
//  Created by Justin Weiss on 1/7/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "NSOrderedSet+SetOperations.h"

@implementation NSOrderedSet (SetOperations)

- (NSOrderedSet *)orderedSetMinusOrderedSet:(NSOrderedSet *)otherSet {
    NSMutableOrderedSet *minusSet = [self mutableCopy];
    [minusSet minusOrderedSet:otherSet];
    return minusSet;
}

- (NSIndexSet *)indexesOfObjectsIntersectingSet:(NSOrderedSet *)otherSet {
    return [self indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [otherSet containsObject:obj];
    }];
}

@end
