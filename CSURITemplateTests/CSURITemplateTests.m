//
//  CSURITemplateTests.m
//  CSURITemplateTests
//
//  Created by Will Harris on 26/02/2013.
//  Copyright (c) 2013 Cogenta Systems Ltd. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "CSURITemplate.h"

@implementation NSObject (CSURITemplateTestsAdditions)

- (BOOL)matchesURI:(NSString *)actualURI
{
    return NO;
}

- (NSString *)failureMessageWithTemplate:(NSString *)template
                            actualResult:(NSString *)result
{
    return [NSString stringWithFormat:
            @"Expectation %@ is not an array or a string",
            self];
}

@end

@implementation NSString (CSURITemplateTestsAdditions)

- (BOOL)matchesURI:(NSString *)actualURI
{
    return [self isEqualToString:actualURI];
}

- (NSString *)failureMessageWithTemplate:(NSString *)template
                            actualResult:(NSString *)result
{
    return [NSString stringWithFormat:
            @"%@ expands to '%@' instead of '%@'",
            [template description], [result description], [self description]];
}

@end

@implementation NSArray (CSURITemplateTestsAdditions)

- (BOOL)matchesURI:(NSString *)actualURI
{
    for (NSString *expectation in self) {
        if ([expectation isEqualToString:actualURI]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)failureMessageWithTemplate:(NSString *)template
                            actualResult:(NSString *)result
{
    return [NSString stringWithFormat:
            @"%@ expands to '%@' instead of something in %@",
            [template description], [result description], [self description]];
}


@end

@implementation NSNumber (CSURITemplateTestsAdditions)

- (BOOL)matchesURI:(NSString *)actualURI
{
    if ([self boolValue]) {
        return NO;
    }
    
    return actualURI == nil;
}

- (NSString *)failureMessageWithTemplate:(NSString *)template
                            actualResult:(NSString *)result
{
    if ([self boolValue]) {
        return [NSString stringWithFormat:
                @"Expected result for %@ was a number (%@) but not false",
                [template description], [self description]];
    }
    
    return [NSString stringWithFormat:
            @"Expected error for %@ but got %@",
            [template description], [result description]];
}

@end

@interface CSURITemplateTests : SenTestCase

@end

NSData *
dataForTest(NSString *testFile, NSError **error)
{
    static NSMutableDictionary *results = nil;
    NSData *result = results[testFile];
    
    if (result) {
        return result;
    }
    
    NSString *thisPath = @"" __FILE__;
    NSURL *thisURL = [NSURL fileURLWithPath:thisPath];
    NSURL *fixturesURL = [NSURL URLWithString:@"uritemplate-test/"
                                relativeToURL:thisURL];
    NSURL *dataURL = [NSURL URLWithString:testFile
                            relativeToURL:fixturesURL];
    result = [NSData dataWithContentsOfURL:dataURL
                                   options:0
                                     error:error];

    if (results) {
        return nil;
    }
    
    return result;
}

NSDictionary *
objectForSpecFilename(NSString *specFilename, NSError **error)
{
    NSData *data = dataForTest(specFilename, error);
    if ( ! data) {
        return nil;
    }
    
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:0
                                             error:error];
}

@implementation CSURITemplateTests

- (void)executeSpecFilename:(NSString *)specFilename
{
    NSError *error = nil;
    NSDictionary *spec = objectForSpecFilename(specFilename, &error);
    STAssertNil(error, @"%@", error);
    STAssertTrue([spec isKindOfClass:[NSDictionary class]],
                 @"The test spec should be a JSON object.");
    
    [spec enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        STAssertTrue([obj isKindOfClass:[NSDictionary class]],
                     @"The test suite should be a JSON object.");
        NSDictionary *variables = obj[@"variables"];
        
        for (NSArray *testCase in obj[@"testcases"]) {
            NSString *templateString = testCase[0];
            CSURITemplate *template = [CSURITemplate URITemplateWithString:templateString error:nil];
            
            if ([templateString isEqualToString:@"{?keys*}"]) {
                NSLog(@"DEBUG");
            }
            
            id expectation = testCase[1];
            NSError *error = nil;
            NSString *actualResult = [template relativeStringWithVariables:variables error:&error];
            if ( ! [expectation matchesURI:actualResult]) {
                STFail(@"%@", [expectation failureMessageWithTemplate:templateString
                                                         actualResult:actualResult]);
            }
        }
        
    }];
}

- (void)testSpecExamplesBySection
{
    [self executeSpecFilename:@"spec-examples-by-section.json"];
}

- (void)testSpecExamples
{
    [self executeSpecFilename:@"spec-examples.json"];
}

- (void)testExtendedTests
{
    [self executeSpecFilename:@"extended-tests.json"];
}

- (void)testNegativeTests
{
    [self executeSpecFilename:@"negative-tests.json"];
}

#pragma mark - Parsing Errors

- (void)testErrorIsReturnedOnAttemptToParseTemplateWithUnclosedCurlyBrace
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{invalid" error:&error];
    STAssertNil(URITemplate, nil);
    STAssertNotNil(error, nil);
    STAssertEquals(CSURITemplateErrorExpressionOpenedButNeverClosed, error.code, nil);
    STAssertEqualObjects(@"An expression was opened but never closed.", [error localizedDescription], nil);
    STAssertEqualObjects(@"An opening '{' character was never terminated by  '{' character.", [error localizedFailureReason], nil);
}

- (void)testErrorIsReturnedOnAttemptToParseTemplateWithClosedBraceThatWasNotOpened
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"invalid}" error:&error];
    STAssertNil(URITemplate, nil);
    STAssertNotNil(error, nil);
    STAssertEquals(CSURITemplateErrorExpressionClosedButNeverOpened, error.code, nil);
    STAssertEqualObjects(@"An expression was closed that was never opened.",[error localizedDescription], nil);
    STAssertEqualObjects(@"A closing '}' character was encountered that was not preceeded by an opening '{' character.", [error localizedFailureReason], nil);
}

- (void)testErrorIsReturnedOnAttemptToParseVariableWithInvalidOperator
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{++var}" error:&error];
    STAssertNil(URITemplate, nil);
    STAssertNotNil(error, nil);
    STAssertEquals(CSURITemplateErrorInvalidOperator, error.code, nil);
    STAssertEqualObjects(@"An invalid operator was encountered.", [error localizedDescription], nil);
    STAssertEqualObjects(@"An operator was encountered with a length greater than 1 character ('++').", [error localizedFailureReason], nil);
}

- (void)testErrorIsReturnedOnAttemptToParseVariableWithUnknownOperator
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{^whatever}" error:&error];
    STAssertNil(URITemplate, nil);
    STAssertNotNil(error, nil);
    STAssertEquals(CSURITemplateErrorInvalidVariableKey, error.code, nil);
    STAssertEqualObjects(@"The template contains an invalid variable key.", [error localizedDescription], nil);
    STAssertEqualObjects(@"The variable key '^whatever' is invalid.", [error localizedFailureReason], nil);
}

- (void)testErrorIsReturnedOnAttemptToParseVariableWithTrailingCharactersAfterExplodeModifier
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{whatever*fdfsdf}" error:&error];
    STAssertNil(URITemplate, nil);
    STAssertNotNil(error, nil);
    STAssertEquals(CSURITemplateErrorInvalidVariableModifier, error.code, nil);
    STAssertEqualObjects(@"The template contains an invalid variable modifier.", [error localizedDescription], nil);
    STAssertEqualObjects(@"Extra characters were found after the explode modifier ('*') for the variable 'whatever'.", [error localizedFailureReason], nil);
}

- (void)testErrorIsReturnedOnAttemptToParseVariableWithLeadingZeroForMaximumLengthModifier
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{var:0123}" error:&error];
    STAssertNil(URITemplate, nil);
    STAssertNotNil(error, nil);
    STAssertEquals(CSURITemplateErrorInvalidVariableModifier, error.code, nil);
    STAssertEqualObjects(@"The template contains an invalid variable modifier.", [error localizedDescription], nil);
    STAssertEqualObjects(@"The variable 'var' was followed by the maximum length modifier (':'), but the maximum length argument was prefixed with an invalid character.", [error localizedFailureReason], nil);
}

- (void)testErrorIsReturnedOnAttemptToParseVariableWithNonNumericValueForMaximumLengthModifier
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{var:3af}" error:&error];
    STAssertNil(URITemplate, nil);
    STAssertNotNil(error, nil);
    STAssertEquals(CSURITemplateErrorInvalidVariableModifier, error.code, nil);
    STAssertEqualObjects(@"The template contains an invalid variable modifier.", [error localizedDescription], nil);
    STAssertEqualObjects(@"The variable 'var' was followed by the maximum length modifier (':'), but the maximum length argument is not numeric.", [error localizedFailureReason], nil);
}

- (void)testErrorIsReturnedOnAttemptToParseVariableWithInvalidVariableKey
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{var-name}" error:&error];
    STAssertNil(URITemplate, nil);
    STAssertNotNil(error, nil);
    STAssertEquals(CSURITemplateErrorInvalidVariableKey, error.code, nil);
    STAssertEqualObjects(@"The template contains an invalid variable key.", [error localizedDescription], nil);
    STAssertEqualObjects(@"The variable key 'var-name' is invalid.", [error localizedFailureReason], nil);
}

#pragma mark Expansion Errors

- (void)testErrorIsReturnedOnAttemptToExpandVariableWithMaximumLengthModifierWithNonStringValue
{
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{variable}" error:&error];
    STAssertNotNil(URITemplate, nil);
    NSString *expandedString = [URITemplate relativeStringWithVariables:nil error:&error];
    STAssertNil(expandedString, nil);
    STAssertEquals(CSURITemplateErrorNoVariables, error.code, nil);
    STAssertEqualObjects(@"A template cannot be expanded without a dictionary of variables.", [error localizedDescription], nil);
}

- (void)testErrorIsReturnedOnAttemptToExpandVariableWithMaximumLengthModifierUsingValueThatIsNotAString {
    NSError *error = nil;
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{variable:5}" error:&error];
    STAssertNotNil(URITemplate, nil);
    NSDictionary *variables = @{ @"variable": @[ @"one", @"two" ] };
    NSString *expandedString = [URITemplate relativeStringWithVariables:variables error:&error];
    STAssertNil(expandedString, nil);
    STAssertEquals(CSURITemplateErrorInvalidExpansionValue, error.code, nil);
    STAssertEqualObjects(@"An unexpandable value was given for a template variable.", [error localizedDescription], nil);
    STAssertEqualObjects(@"Variables with a maximum length modifier can only be expanded with string values, but a value of type '__NSArrayI' given.", [error localizedFailureReason], nil);
}

#pragma mark - Deprecations

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)testDeprecatedInitializer
{
    CSURITemplate *URITemplate = [[CSURITemplate alloc] initWithURITemplate:@"{variable}"];
    NSDictionary *variables = @{ @"variable": @"value" };
    NSString *expandedString = [URITemplate relativeStringWithVariables:variables error:nil];
    STAssertEqualObjects(@"value", expandedString, nil);
}

- (void)testDeprecatedExpansion
{
    CSURITemplate *URITemplate = [CSURITemplate URITemplateWithString:@"{variable}" error:nil];
    NSDictionary *variables = @{ @"variable": @"value" };
    NSString *expandedString = [URITemplate URIWithVariables:variables];
    STAssertEqualObjects(@"value", expandedString, nil);
}

#pragma clang diagnostic pop

@end
