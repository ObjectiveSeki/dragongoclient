//
//  SGF.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/4/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SgSystem.h"
#import "SgNode.h"
#import "GoGame.h"

@interface SGF : NSObject {
	GoGame *goGame;
}

- initWithString:(NSString *)sgfString boardSize:(int)boardSize;

@end
