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

@interface Game : NSObject {
	int gameId;
	NSURL * sgfUrl;
	NSString * sgfString;
	NSString * opponent;
	NSString * time;
	MovePlayer color;
}

@property(nonatomic, retain) NSURL * sgfUrl;
@property(nonatomic, copy) NSString * sgfString;
@property(nonatomic, copy) NSString * opponent;
@property(nonatomic, copy) NSString * time;
@property(nonatomic) int gameId;
@property(nonatomic) MovePlayer color;

@end
