//
//  NSTimer+Blocks.m
//  DGSPhone
//
//  Created by Justin Weiss on 1/15/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "NSTimer+Blocks.h"

@interface NSTimer (PrivateBlocks)
- (void)executeBlock:(NSTimerBlock)block;
@end

@implementation NSTimer (Blocks)

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti block:(NSTimerBlock)block repeats:(BOOL)yesOrNo {
    NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:[self instanceMethodSignatureForSelector:@selector(executeBlock:)]];
    NSTimer * timer = [NSTimer timerWithTimeInterval:ti
                                          invocation:invocation
                                             repeats:yesOrNo];
    NSTimerBlock copiedBlock = [block copy];
    
    [invocation setTarget:timer];
    [invocation setSelector:@selector(executeBlock:)];
    [invocation setArgument:&copiedBlock atIndex:2];
    
    return timer;
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(NSTimerBlock)block repeats:(BOOL)yesOrNo {
    NSTimer *timer = [self timerWithTimeInterval:ti block:block repeats:yesOrNo];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    return timer;
}

- (void)executeBlock:(NSTimerBlock)block {
    block(self);
}

@end
