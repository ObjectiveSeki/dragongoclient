//
// Holds data on a section in a TableView
//

#import <Foundation/Foundation.h>
#import "TableRow.h"


@interface TableSection : NSObject {
}

@property (nonatomic, copy) NSString *headerString;
@property (nonatomic, strong) NSArray *tableRows;

- (void)addRow:(TableRow *)row;

@end
