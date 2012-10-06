//
//  Move.m
//
//  A simple data structure representing the placement 
//  (or not) of a stone on the board. Also represents 
//  pass and resign moves.
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "Move.h"


@implementation Move

- (NSUInteger) hash {
	int prime = 31;
	
	int result = prime + self.row;
	result = prime * result + self.col;
	result = prime * result + self.player;
	result = prime * result + self.moveType;
	result = prime * result + self.boardSize;

	return result;
}

- (BOOL)isEqualToMove:(Move *)move {
	return move.row == self.row && 
	move.col == self.col && 
	move.player == self.player && 
	move.moveType == self.moveType && 
	move.boardSize == self.boardSize;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToMove:other];
}


@end
