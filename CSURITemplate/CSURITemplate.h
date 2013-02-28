//
//  CSURITemplate.h
//  CSURITemplate
//
//  Created by Will Harris on 26/02/2013.
//  Copyright (c) 2013 Cogenta Systems Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Expand URI Templates.
 
 This class implements Level 4 of the URI Template specification, defined by
 (RFC 6570)[http://tools.ietf.org/html/rfc6570]. URI Templates are a compact
 string representation of a set of URIs.
 
 Each CSURITemplate instance has a single URI Template. The URI template can be
 expanded into a URI reference by invoking the instance's URIWithVariables: with
 a dictionary of variables.
 
 For example:
 
     CSURITemplate *template = [[CSURITemplate alloc]
                                initWithURITemplate:@"/search{?q}"];
     NSString *uri1 = [template URIWithVariables:@{@"q": @"hateoas"}];
     NSString *uri2 = [template URIWithVariables:@{@"q": @"hal"}];
     assert([uri1 isEqualToString:@"/search?q=hateoas"]);
     assert([uri2 isEqualToString:@"/search?q=hal"]);
 
 */
@interface CSURITemplate : NSObject

/** @name Initializing URI Templates */

/** Returns an initialized CSURITemplate object containing for the given URI
 template.
 
 If the URITemplate is invalid, calls to URIWithVariables: will return nil.
 
 @param URITemplate The URI template.
 @returns A CSURITemplate object initialized with the URI template.
 */
- (id)initWithURITemplate:(NSString *)URITemplate;

/** @name Getting URI References */

/** Expands the template with the given variables.
 
 This method expands the URI template using the variables provided, normally
 returning a string, but will return nil if the URI template has a syntax error,
 or if the URI template is valid but has no valid expansion for the given
 variables. For example, if the URI template is `"{keys:1}"` and `variables` is
 `{@"semi":@";",@"dot":@".",@"comma":@","}`, this method will return nil
 because the prefix modifier is not applicable to composite values.
 
 @param variables a dictionary of variables to use when expanding the template.
 @returns A string containing the expanded URI reference, or nil if an error
 was encountered.
 */
- (NSString *)URIWithVariables:(NSDictionary *)variables;

@end
