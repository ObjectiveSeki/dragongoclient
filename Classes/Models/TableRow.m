
#import "TableRow.h"


@implementation TableRow

@synthesize cellClass;
@synthesize cellInit;
@synthesize cellSetup;
@synthesize cellTouched;

- (void)dealloc {
	self.cellInit = nil;
	self.cellSetup = nil;
	self.cellTouched = nil;
	[super dealloc];
}

@end
