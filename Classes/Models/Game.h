//
//  Game.h
//  
//	Represents a game, as DGS sees it. This is pretty much a struct, 
//  all of the complicated logic is inside FuegoBoard.
// 
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	"Move.h"

@interface Game : NSObject <NSCoding>

@property(nonatomic, strong) NSURL * sgfUrl;
@property(nonatomic, strong) NSURL * detailUrl;
@property(nonatomic, copy) NSString * sgfString;
@property(nonatomic, copy) NSString * opponent;
@property(nonatomic, copy) NSString * time;
@property(nonatomic, copy) NSString * lastMove;
@property(nonatomic, copy) NSString * opponentRating;
@property(nonatomic) int gameId;
@property(nonatomic) int moveId;
@property(nonatomic) MovePlayer color;
@property(nonatomic, assign) int handicap;
@property(nonatomic, assign) float komi;
@property(nonatomic) BOOL myTurn;

@end
