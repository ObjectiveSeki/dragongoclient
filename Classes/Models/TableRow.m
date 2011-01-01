
#import "TableRow.h"


@implementation TableRow

@synthesize cellClass;
@synthesize cellSetup;

- (void)dealloc {
	self.cellSetup = nil;
	[super dealloc];
}

@end
