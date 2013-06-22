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

typedef NS_ENUM(NSInteger, MovePlayer) {
	kMovePlayerNone,
	kMovePlayerBlack,
	kMovePlayerWhite
};

typedef NS_ENUM(NSInteger, MoveType) {
	kMoveTypeMove,
	kMoveTypePass,
	kMoveTypeResign
};

@interface Move : NSObject {
};

@property(nonatomic) int row;
@property(nonatomic) int col;
@property(nonatomic) MovePlayer player;
@property(nonatomic) MoveType moveType;
@property(nonatomic) int boardSize;

- (NSUInteger)hash;
- (BOOL)isEqual:(id)other;

@end
