//
//  UIDevice+ExtraDeviceDetails.m
//  DGSPhone
//
//  Created by Justin Weiss on 1/19/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "UIDevice+ExtraDeviceDetails.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation UIDevice (ExtraDeviceDetails)

- (NSString *) platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = @(machine);
    free(machine);
    return platform;
}
@end
