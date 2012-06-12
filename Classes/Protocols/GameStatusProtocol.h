//
//  GameStatusProtocol.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/11/12.
//  Copyright (c) 2012 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"

@protocol GameStatusProtocol <NSObject>

- (void)playedMoveInGame:(Game *)game;

@end
