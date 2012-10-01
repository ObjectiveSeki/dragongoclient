//
// Holds data on a section in a TableView
//

#import <Foundation/Foundation.h>
#import "TableRow.h"


@interface TableSection : NSObject {
	NSString *headerString;
	NSArray *tableRows;
}

@property (nonatomic, copy) NSString *headerString;
@property (nonatomic, strong) NSArray *tableRows;

- (void)addRow:(TableRow *)row;

@end
