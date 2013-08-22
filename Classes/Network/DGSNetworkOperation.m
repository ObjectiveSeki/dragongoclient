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

NSString * const kDGSErrorDomain = @"DGSNetworkErrorDomain";

@interface DGSNetworkOperation ()
@property (nonatomic, readonly) NSString *lossyResponseString;
@end

// Encapsulates the error and success handling behavior of DGS
@implementation DGSNetworkOperation

// Disable MKNetworkKit's request matching, because it expects our completion
// blocks to be idempotent. Which they're not. Maybe someday.
-(BOOL) isEqual:(id)object {
    return self == object;
}

// Is the user currently logged in through their cookie? YES if so,
// NO if not.
- (BOOL)isLoggedIn {
    NSString *originalUrlString = [self.readonlyRequest.URL absoluteString];
	NSString *urlString = [self.readonlyResponse.URL absoluteString];
    if (!urlString) {
        urlString = originalUrlString;
    }
    NSString *responseString = self.responseString;
    
	// Use a simple heuristic here. If we are hitting a normal HTML page, we
	// can figure out if the user is logged in by checking if we ended up on index.php
	// or error.php (in the case where the error is not_logged_in)
	BOOL onErrorPageOrIndex = (NSNotFound != [urlString rangeOfString:@"error.php?err=not_logged_in"].location || NSNotFound != [urlString rangeOfString:@"index.php"].location);
    BOOL noUserData = (nil == [Player currentPlayer] && (NSNotFound == [urlString rangeOfString:@"obj=user&cmd=info"].location) && (NSNotFound == [originalUrlString rangeOfString:@"login.php"].location));
    
    if (onErrorPageOrIndex || noUserData) {
        return NO;
    }
    
	// If we're using the DGS api, it will return the string 'Error: no_uid' or 'Error: not_logged_in' if we aren't logged in.
    if (responseString) {
        BOOL noUID = (NSNotFound != [responseString rangeOfString:@"#Error: no_uid"].location);
        BOOL notLoggedIn = (NSNotFound != [responseString rangeOfString:@"#Error: not_logged_in"].location);
        BOOL invalidUser = (NSNotFound != [responseString rangeOfString:@"#Error: invalid_user"].location);
        BOOL unknownUser = (NSNotFound != [responseString rangeOfString:@"#Error: unknown_user"].location);
    
        if (noUID || notLoggedIn || invalidUser || unknownUser) {
            return NO;
        }
    }
	return YES;
}

// Checks the request body to see if it contains an error. If so,
// return the error. Otherwise, returns nil.
- (NSError *)dgsError {
	NSString *urlString = [self.readonlyResponse.URL absoluteString];
    NSString *responseString = self.responseString;
	NSError *error = nil;
    
    if (![self isLoggedIn]) {
        error = [self errorWithDGSErrorString:NSLocalizedStringFromTable(@"not_logged_in", @"DGSErrors", nil) code:kDGSErrorCodeLoginError];
    } else if (NSNotFound != [urlString rangeOfString:@"error.php"].location) {
        // HTML error
		NSError *htmlError;
		GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithHTMLString:responseString options:0 error:&htmlError];
		NSArray *bodyElements = [doc nodesForXPath:@"//td[@id='pageBody']" error:&htmlError];
		if ([bodyElements count] > 0) {
			error = [self errorWithDGSErrorString:[[bodyElements objectAtIndex:0] stringValue] code:kDGSErrorCodeGenericError];
		}
	} else if (NSNotFound != [responseString rangeOfString:@"#Error:"].location) {
        // quick_status.php error
        NSString *errorKey;
        NSScanner *scanner = [[NSScanner alloc] initWithString:responseString];
        [scanner scanUpToString:@"[#Error:" intoString:NULL];
        [scanner scanString:@"[#Error: " intoString:NULL];
        [scanner scanUpToString:@";" intoString:&errorKey];
        
        error = [self errorWithDGSErrorString:NSLocalizedStringFromTable(errorKey, @"DGSErrors", nil) code:kDGSErrorCodeGenericError];
    } else if (NSNotFound != [responseString rangeOfString:@"\"error\":"].location) {
        // JSON error
        NSString *errorKey;
        NSScanner *scanner = [[NSScanner alloc] initWithString:responseString];
        [scanner scanUpToString:@"\"error\":\"" intoString:NULL];
        [scanner scanString:@"\"error\":\"" intoString:NULL];
        [scanner scanUpToString:@"\"," intoString:&errorKey];

        if (errorKey) {
            error = [self errorWithDGSErrorString:NSLocalizedStringFromTable(errorKey, @"DGSErrors", nil) code:kDGSErrorCodeGenericError];
        }
    }
    
	return error;
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

- (NSError *)errorWithDGSErrorString:(NSString *)dgsErrorString code:(NSInteger)code {
    return [[NSError alloc] initWithDomain:kDGSErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey:dgsErrorString }];
}

// Called when a request finishes. Handles being logged out,
// error messages, and successes.
- (void)operationSucceeded {
	NSError *error = [self dgsError];
    
	if (error) {
        [super operationFailedWithError:error];
	} else {
        [super operationSucceeded];
    }
}
@end
