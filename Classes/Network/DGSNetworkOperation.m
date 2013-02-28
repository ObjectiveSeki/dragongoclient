//
//  DGSNetworkOperation.m
//  DGSPhone
//
//  Created by Justin Weiss on 2/26/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "DGSNetworkOperation.h"
#import "Player.h"
#import "GDataXMLNode.h"

static NSString * const DGSErrorDomain = @"DGSNetworkErrorDomain";

@interface DGSNetworkOperation ()
@property (nonatomic, readonly) NSString *lossyResponseString;
@end

// Encapsulates the error and success handling behavior of DGS
@implementation DGSNetworkOperation

// Is the user currently logged in through their cookie? YES if so,
// NO if not.
- (BOOL)isLoggedIn {
    NSString *originalUrlString = [self.readonlyRequest.URL absoluteString];
	NSString *urlString = [self.readonlyResponse.URL absoluteString];
    NSString *responseString = self.responseString;
    
	// Use a simple heuristic here. If we are hitting a normal HTML page, we
	// can figure out if the user is logged in by checking if we ended up on index.php
	// or error.php (in the case where the error is not_logged_in)
	BOOL onErrorPageOrIndex = (NSNotFound != [urlString rangeOfString:@"error.php?err=not_logged_in"].location || NSNotFound != [urlString rangeOfString:@"index.php"].location);
    
	// If we're using the DGS api, it will return the string 'Error: no_uid' or 'Error: not_logged_in' if we aren't logged in.
	BOOL noUID = (NSNotFound != [responseString rangeOfString:@"#Error: no_uid"].location);
	BOOL notLoggedIn = (NSNotFound != [responseString rangeOfString:@"#Error: not_logged_in"].location);
    BOOL invalidUser = (NSNotFound != [responseString rangeOfString:@"#Error: invalid_user"].location);
    BOOL unknownUser = (NSNotFound != [responseString rangeOfString:@"#Error: unknown_user"].location);
    BOOL noUserData = (nil == [Player currentPlayer] && (NSNotFound == [urlString rangeOfString:@"obj=user&cmd=info"].location) && (NSNotFound == [originalUrlString rangeOfString:@"login.php"].location));
    
	if (onErrorPageOrIndex || noUID || notLoggedIn || invalidUser || unknownUser || noUserData) {
		return NO;
	}
	return YES;
}

// Checks the request body to see if it contains an error. If so,
// return the error string. Otherwise, returns nil.
- (NSString *)dgsError {
	NSString *urlString = [self.readonlyResponse.URL absoluteString];
    NSString *responseString = self.responseString;
	NSString *errorString = nil;
    
	if (NSNotFound != [urlString rangeOfString:@"error.php"].location) {
		NSError *error;
		GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithHTMLString:responseString options:0 error:&error];
		NSArray *bodyElements = [doc nodesForXPath:@"//td[@id='pageBody']" error:&error];
		if ([bodyElements count] > 0) {
			errorString = [[bodyElements objectAtIndex:0] stringValue];
		}
	} else if (NSNotFound != [responseString rangeOfString:@"#Error:"].location) {
        NSString *errorKey;
        NSScanner *scanner = [[NSScanner alloc] initWithString:responseString];
        [scanner scanUpToString:@"[#Error:" intoString:NULL];
        [scanner scanString:@"[#Error: " intoString:NULL];
        [scanner scanUpToString:@";" intoString:&errorKey];
        
        errorString = NSLocalizedStringFromTable(errorKey, @"DGSErrors", nil);
    }
    
	return errorString;
}

- (NSString *)lossyStringFromData:(NSData *)data encoding:(NSStringEncoding)encoding replaceString:(NSString *)replacement {
	NSMutableString *output = [NSMutableString stringWithCapacity:[data length]];
	int pos = 0;
	int lookahead = 1;
	while (pos + lookahead <= [data length]) {
		NSRange currentRange = NSMakeRange(pos, lookahead);
		NSData *possibleChar = [data subdataWithRange:currentRange];
		NSString *str = [[NSString alloc] initWithData:possibleChar encoding:encoding];
		if (str) {
			[output appendString:str];
			pos += lookahead;
			lookahead = 1;
		} else {
			lookahead += 1;
			if (lookahead > 4) {
				[output appendString:replacement];
				// skip to the next possible char
				lookahead = 1;
				pos += 1;
			}
		}
	}
	return output;
}

- (NSString *)strictResponseString {
    return [super responseString];
}

- (NSString *)responseString {
    if (self.strictResponseString) {
        return self.strictResponseString;
    }
    
    @synchronized(self) {
        if (!_lossyResponseString) {
            // If there are invalid characters in the encoding we're given,
            // [request responseString] returns nil. We still want to get the
            // data that's valid out of the page, though, and Apple doesn't
            // expose that functionality publicly. So instead, we'll call my
            // brain-dead dumb slow function to extract as much data as we can.
            // Hopefully it's not too bad.
            _lossyResponseString = [self lossyStringFromData:self.responseData encoding:self.stringEncoding replaceString:@"?"];
        }
    }
            
    return _lossyResponseString;
}

- (NSError *)errorWithDGSError:(NSString *)dgsError {
    return [[NSError alloc] initWithDomain:DGSErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey:dgsError }];
}

// Called when a request finishes. Handles being logged out,
// error messages, and successes.
- (void)operationSucceeded {
	NSString *errorString = [self dgsError];
    
	if (errorString) {
        [super operationFailedWithError:[self errorWithDGSError:errorString]];
	} else {
        [super operationSucceeded];
    }
}
@end
