//
//  NSTimer+Blocks.h
//  DGSPhone
//
//  Created by Justin Weiss on 1/15/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^NSTimerBlock)(NSTimer *timer);

@interface NSTimer (Blocks)

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(NSTimerBlock)block repeats:(BOOL)yesOrNo;
+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti block:(NSTimerBlock)block repeats:(BOOL)yesOrNo;

@end
