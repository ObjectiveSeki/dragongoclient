
#import "TableSection.h"


@implementation TableSection

@synthesize tableRows;
@synthesize headerString;

- (void)addRow:(TableRow *)row {
	NSMutableArray *rows;
	if (self.tableRows) {
		rows = [self.tableRows mutableCopy];
	} else {
		rows = [[NSMutableArray alloc] init];
	}
	[rows addObject:row];
	self.tableRows = rows;
	[rows release];
}

- (void)dealloc {
	self.tableRows = nil;
	self.headerString = nil;
	[super dealloc];
}

@end
