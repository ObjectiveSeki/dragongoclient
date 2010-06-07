//
//  GoBoardView.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "GoBoardView.h"
#import "Stone.h"
#import <QuartzCore/QuartzCore.h>

#define MARGIN_X 20
#define MARGIN_Y 20

@implementation GoBoardView

@synthesize board;

// Initialize the layer by setting
// the levelsOfDetailBias of bias and levelsOfDetail
// of the tiled layer
-(id)initWithFrame:(CGRect)r
{
    self = [super initWithFrame:r];
    if(self) {
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

- (float)pointDistance {
	return (float)([self maxX] - [self minX]) / ([[self board] size] - 1);
}

- (CGPoint)pointForBoardX:(int)x Y:(int)y {
	
	float pointDelta = [self pointDistance];
	float pointX = (x - 1) * pointDelta + [self minX];
	float pointY = [self maxY] - ((y - 1) * pointDelta);
	
	return CGPointMake(pointX, pointY);
}

- (void)drawBoardGrid:(CGContextRef)context boardSize:(int)boardSize {
	
	CGContextSetLineWidth(context, 1.0);
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);

	// draw all the lines on the X axis
	for(int i = 1; i <= boardSize; i++) {
		CGContextBeginPath(context);
		CGPoint startPoint = [self pointForBoardX:i Y:1];
		CGPoint endPoint = [self pointForBoardX:i Y:boardSize];
		CGContextMoveToPoint(context, startPoint.x, startPoint.y);
		CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
		CGContextStrokePath(context);
	}
	
	// draw all the lines on the Y axis
	for(int i = 1; i <= boardSize; i++) {
		CGContextBeginPath(context);
		CGPoint startPoint = [self pointForBoardX:1 Y:i];
		CGPoint endPoint = [self pointForBoardX:boardSize Y:i];
		CGContextMoveToPoint(context, startPoint.x, startPoint.y);
		CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
		CGContextStrokePath(context);
	}
}

- (void)drawStones:(CGContextRef)context {
	NSArray *stones = [board stones];
	float boardRadius = [self pointDistance] * 0.5;
	for (Stone *stone in stones) {
		if ([stone player] == kStonePlayerBlack) {
			CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
			CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
		} else {
			CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
			CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
		}

		CGPoint coords = [self pointForBoardX:[stone x] Y:[stone y]];
		CGContextBeginPath(context);
		CGContextAddArc(context, coords.x, coords.y, boardRadius, 0, 2*3.14159, 0);
		CGContextDrawPath(context, kCGPathFillStroke);
	}
}

- (void)drawLastMoveIndicator:(CGContextRef)context {
	Stone *stone = [board lastMove];

	if ([stone player] == kStonePlayerBlack) {
		CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	} else {
		CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
	}	
	
	CGPoint coords = [self pointForBoardX:[stone x] Y:[stone y]];
	CGContextBeginPath(context);
	CGContextAddArc(context, coords.x, coords.y, [self pointDistance] * 0.3, 0, 2*3.14159, 0);
	CGContextStrokePath(context);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	// Drawing code
	[self drawBoardGrid:context boardSize:[[self board] size]];
	[self drawStones:context];
	[self drawLastMoveIndicator:context];
}


- (void)dealloc {
	[board release];
    [super dealloc];
}


@end
