//
//  Game.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Game : NSObject {
	int gameId;
	NSString * sgfUrl;
	NSString * opponent;
}

@property(nonatomic, retain) NSString * sgfUrl;
@property(nonatomic, retain) NSString * opponent;
@property(nonatomic) int gameId;

- (NSString *)sgfString;

@end
