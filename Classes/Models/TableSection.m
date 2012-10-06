
#import "TableSection.h"


@implementation TableSection

- (void)addRow:(TableRow *)row {
	NSMutableArray *rows;
	if (self.tableRows) {
		rows = [self.tableRows mutableCopy];
	} else {
		rows = [[NSMutableArray alloc] init];
	}
	[rows addObject:row];
	self.tableRows = rows;
}


@end
