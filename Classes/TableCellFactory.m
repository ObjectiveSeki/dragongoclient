//
//  TableCellFactory.m
//  BACEstimator
//
//  Created by Justin Weiss on 7/18/08.
//  Copyright 2008 Avvo. All rights reserved.
//

#import "TableCellFactory.h"

@implementation TableCellFactory

- (TextCell *) newTextCell{
    [[NSBundle mainBundle] loadNibNamed:@"TableCells" owner:self options:nil];
    return textCell;
}

+ (TextCell *) textCell
{
    TableCellFactory *tcf = [[TableCellFactory alloc] init];
    TextCell *textCell = [tcf newTextCell];
    [tcf release];
    return textCell;
}

- (void)dealloc {
    [textCell release];
    [super dealloc];
}


@end
