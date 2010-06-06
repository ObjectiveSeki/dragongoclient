//
//  GoBoardView.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "GoBoardView.h"
#import "Stone.h"

#define MARGIN_X 20
#define MARGIN_Y 20

@implementation GoBoardView

@synthesize board;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

- (int)maxX {
	return self.bounds.size.width - MARGIN_X;
}


- (int)maxY {
	return self.bounds.size.height - MARGIN_Y;
}

- (int)minX {
	return MARGIN_X;
}

- (int)minY {
	return MARGIN_Y;
}

- (CGPoint)pointForBoardX:(int)x Y:(int)y boardSize:(int)boardSize {
	
	float pointDelta = (float)([self maxX] - [self minX]) / (boardSize - 1);
	float pointX = (x - 1) * pointDelta + [self minX];
	float pointY = [self maxY] - ((y - 1) * pointDelta);
	
	return CGPointMake(pointX, pointY);
}

- (void)drawBoardGrid:(CGRect)rect context:(CGContextRef)context boardSize:(int)boardSize {
	
	CGContextSetLineWidth(context, 1.0);
	[[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1] set];
	
	// draw all the lines on the X axis
	for(int i = 1; i <= boardSize; i++) {
		CGContextBeginPath(context);
		CGPoint startPoint = [self pointForBoardX:i Y:1 boardSize:boardSize];
		CGPoint endPoint = [self pointForBoardX:i Y:boardSize boardSize:boardSize];
		CGContextMoveToPoint(context, startPoint.x, startPoint.y);
		CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
		CGContextStrokePath(context);
	}
	
	// draw all the lines on the Y axis
	for(int i = 1; i <= boardSize; i++) {
		CGContextBeginPath(context);
		CGPoint startPoint = [self pointForBoardX:1 Y:i boardSize:boardSize];
		CGPoint endPoint = [self pointForBoardX:boardSize Y:i boardSize:boardSize];
		CGContextMoveToPoint(context, startPoint.x, startPoint.y);
		CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
		CGContextStrokePath(context);
	}
}

- (void)drawStones:(CGRect)rect context:(CGContextRef)context boardSize:(int)boardSize {
	NSArray *stones = [board stones];
	for (Stone *stone in stones) {
		if ([stone player] == kStonePlayerBlack) {
			[[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1] set];
		} else {
			[[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1] set];
		}

		CGPoint coords = [self pointForBoardX:[stone x] Y:[stone y] boardSize:boardSize];
		CGContextBeginPath(context);
		CGContextAddArc(context, coords.x, coords.y, 7, 0, 2*3.14159, 0);
		CGContextDrawPath(context, kCGPathFillStroke);
	}
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawBoardGrid:rect context:context boardSize:[[self board] size]];
	[self drawStones:rect context:context boardSize:[[self board] size]];
}


- (void)dealloc {
	[board release];
    [super dealloc];
}


@end
