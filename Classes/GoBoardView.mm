//
//  GoBoardView.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "GoBoardView.h"
#import "Move.h"
#import "DGSPhoneAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#define MARGIN_X 40
#define MARGIN_Y 40

@implementation GoBoardView

@synthesize board;
@synthesize delegate;

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

- (CGPoint)pointForBoardRow:(int)row column:(int)col {
	
	float pointDelta = [self pointDistance];
	float pointX = (col - 1) * pointDelta + [self minX];
	float pointY = [self maxY] - ((row - 1) * pointDelta);
	
	return CGPointMake(pointX, pointY);
}

- (CGPoint)boardPositionForPoint:(CGPoint)point {
	float pointDelta = [self pointDistance];
	float boardX = round((point.x - [self minX]) / pointDelta + 1);
	float boardY = round(([self maxY] - point.y) / pointDelta + 1);
	
	return CGPointMake(boardX, boardY);
}

- (void)drawBoardGrid:(CGContextRef)context boardSize:(int)boardSize {
	
	[[(DGSPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] boardImage] drawInRect:[self bounds]];
	
	CGContextSetLineWidth(context, 1.0);
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);

	// draw all the lines on the X axis
	for(int i = 1; i <= boardSize; i++) {
		CGContextBeginPath(context);
		CGPoint startPoint = [self pointForBoardRow:1 column:i];
		CGPoint endPoint = [self pointForBoardRow:boardSize column:i];
		CGContextMoveToPoint(context, startPoint.x, startPoint.y);
		CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
		CGContextStrokePath(context);
	}
	
	// draw all the lines on the Y axis
	for(int i = 1; i <= boardSize; i++) {
		CGContextBeginPath(context);
		CGPoint startPoint = [self pointForBoardRow:i column:1];
		CGPoint endPoint = [self pointForBoardRow:i column:boardSize];
		CGContextMoveToPoint(context, startPoint.x, startPoint.y);
		CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
		CGContextStrokePath(context);
	}
}

- (void)drawStones:(CGContextRef)context {
	NSArray *moves = [board moves];
	float boardRadius = [self pointDistance] * 0.52;
	UIImage *stoneImage;
	for (Move *move in moves) {
		
		if ([move moveType] == kMoveTypeMove) {

			if ([move player] == kMovePlayerBlack) {
				stoneImage = [(DGSPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] blackStone];
			} else {
				stoneImage = [(DGSPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] whiteStone];
			}

			CGPoint coords = [self pointForBoardRow:[move row] column:[move col]];
			
			CGRect stoneRect = CGRectMake(coords.x - boardRadius, coords.y - boardRadius, boardRadius * 2, boardRadius * 2);
			[stoneImage drawInRect:stoneRect];
		}
	}
}

- (void)drawLastMoveIndicator:(CGContextRef)context {
	Move *move = [board currentMove];
	
	if ([move moveType] != kMoveTypeMove) {
		return;
	}
	
	CGContextSetLineWidth(context, 2.0);
	
	if ([move player] == kMovePlayerBlack) {
		CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	} else {
		CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
	}	
	
	CGPoint coords = [self pointForBoardRow:[move row] column:[move col]];
	CGContextBeginPath(context);
	CGContextAddArc(context, coords.x, coords.y, [self pointDistance] * 0.25, 0, 2*3.14159, 0);
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

- (bool)playStoneAtPoint:(CGPoint)point {
	CGPoint boardPoint = [self boardPositionForPoint:point];
	return [[self board] playStoneAtRow:(int)boardPoint.y column:(int)boardPoint.x];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	[delegate performSelector:@selector(handleGoBoardTouch:inView:) withObject:touch withObject:self];
}


- (void)dealloc {
	[board release];
    [super dealloc];
}


@end
