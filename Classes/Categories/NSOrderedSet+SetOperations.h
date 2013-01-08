//
//  NSOrderedSet+SetOperations.h
//  DGSPhone
//
//  Created by Justin Weiss on 1/7/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOrderedSet (SetOperations)

// Returns an NSIndexSet of the indexes of the objects in this set that are also
// in otherSet.
- (NSIndexSet *)indexesOfObjectsIntersectingSet:(NSOrderedSet *)otherSet;

// Returns a new set of all the objects in this set that are not in otherSet.
- (NSOrderedSet *)orderedSetMinusOrderedSet:(NSOrderedSet *)otherSet;

@end
