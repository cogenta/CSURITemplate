//
//  CSURITemplate.h
//  CSURITemplate
//
//  Created by Will Harris on 26/02/2013.
//  Copyright (c) 2013 Cogenta Systems Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The domain of errors returned by `CSURITemplate` objects.
 */
extern NSString *const CSURITemplateErrorDomain;

typedef NS_ENUM(NSInteger, CSURITemplateError) {
    // Parsing Errors
    CSURITemplateErrorExpressionClosedButNeverOpened    = 100,
    CSURITemplateErrorExpressionOpenedButNeverClosed    = 101,
    CSURITemplateErrorInvalidOperator                   = 102,
    CSURITemplateErrorUnknownOperator                   = 103,
    CSURITemplateErrorInvalidVariableKey                = 104,
    CSURITemplateErrorInvalidVariableModifier           = 105,
    
    // Expansion Errors
    CSURITemplateErrorNoVariables                       = 200,
    CSURITemplateErrorInvalidExpansionValue             = 201
};

/**
 An `NSNumber` value in the `userInfo` dictionary of errors returned while parsing a URI template that indicates the position in the string at which the error was encountered.
 */
extern NSString *const CSURITemplateErrorScanLocationErrorKey;

/**
 Expand URI Templates.
 
 This class implements Level 4 of the URI Template specification, defined by
 [RFC6570: URI Template](http://tools.ietf.org/html/rfc6570). URI Templates are
 a compact string representation of a set of URIs.
 
 Each CSURITemplate instance has a single URI Template. The URI template can be
 expanded into a URI reference by invoking the instance's URIWithVariables: with
 a dictionary of variables.
 
 For example:
 
     NSError *error = nil;
     CSURITemplate *template = [CSURITemplate URITemplateWithString:@"/search{?q}" error:&error];
     NSString *uri1 = [template relativeStringWithVariables:@{@"q": @"hateoas"}];
     NSString *uri2 = [template relativeStringWithVariables:@{@"q": @"hal"}];
     assert([uri1 isEqualToString:@"/search?q=hateoas"]);
     assert([uri2 isEqualToString:@"/search?q=hal"]);
 
 */
@interface CSURITemplate : NSObject

///---------------------------------
/// @name Initializing URI Templates
///---------------------------------

/**
 Creates and returns a URI template object initialized with the given template string.
 
 @param templateString The RFC6570 conformant string with which to initialize the URI template object.
 @param error A pointer to an `NSError` object. If parsing the URI template string fails then the error will be set to an instance of `NSError` that describes the problem.
 @return A new URI template object, or `nil` if the template string could not be parsed.
 */
+ (instancetype)URITemplateWithString:(NSString *)templateString error:(NSError **)error;

/**
 The URI template string that was used to initialize the receiver.
 */
@property (nonatomic, copy, readonly) NSString *templateString;

///--------------------------------------------
/// @name Expanding the Template with Variables
///--------------------------------------------

/** 
 Expands the template with the given variables.
 
 This method expands the URI template using the variables provided, normally
 returning a string, but will return nil if the URI template has a syntax error,
 or if the URI template is valid but has no valid expansion for the given
 variables. For example, if the URI template is `"{keys:1}"` and `variables` is
 `{@"semi":@";",@"dot":@".",@"comma":@","}`, this method will return nil
 because the prefix modifier is not applicable to composite values.
 
 @param variables a dictionary of variables to use when expanding the template.
 @param error A pointer to an `NSError` object. If an error occurs while expanding the template then the error will be set to an instance of `NSError` that describes the problem.
 @returns A string containing the expanded URI reference, or nil if an error was encountered.
 */
- (NSString *)relativeStringWithVariables:(NSDictionary *)variables error:(NSError **)error;

@end
