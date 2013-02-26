//
//  CSURITemplate.h
//  CSURITemplate
//
//  Created by Will Harris on 26/02/2013.
//  Copyright (c) 2013 Cogenta Systems Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSURITemplate : NSObject

- (id)initWithURITemplate:(NSString *)URITemplate;
- (NSString *)URIWithVariables:(NSDictionary *)variables;

@end
