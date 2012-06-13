//
//  Move.h
//
//  A simple data structure representing the placement 
//  (or not) of a stone on the board. Also represents 
//  pass and resign moves.
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	kMovePlayerNone,
	kMovePlayerBlack,
	kMovePlayerWhite
} MovePlayer;

typedef enum {
	kMoveTypeMove,
	kMoveTypePass,
	kMoveTypeResign
} MoveType;

@interface Move : NSObject {
	int row;
	int col;
	MovePlayer player;
	MoveType moveType;
	int boardSize;
};

@property(nonatomic) int row;
@property(nonatomic) int col;
@property(nonatomic) MovePlayer player;
@property(nonatomic) MoveType moveType;
@property(nonatomic) int boardSize;

- (NSUInteger)hash;
- (BOOL)isEqual:(id)other;

@end
