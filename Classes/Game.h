//
//  Game.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	"Move.h"

@interface Game : NSObject {
	int gameId;
	NSURL * sgfUrl;
	NSString * opponent;
	NSString * time;
	MovePlayer color;
}

@property(nonatomic, retain) NSURL * sgfUrl;
@property(nonatomic, retain) NSString * opponent;
@property(nonatomic, retain) NSString * time;
@property(nonatomic) int gameId;
@property(nonatomic) MovePlayer color;

- (NSString *)sgfString;
- (void)playMove:(Move *)move lastMove:(Move *)move moveNumber:(int)moveNumber comment:(NSString *)comment;
@end
