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
            template, result, self];
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
            NSString *URITemplate = testCase[0];
            CSURITemplate *template = [[CSURITemplate alloc]
                                       initWithURITemplate:URITemplate];
            
            if ([URITemplate isEqualToString:@"{?keys*}"]) {
                NSLog(@"DEBUG");
            }
            
            id expectation = testCase[1];
            NSString *actualResult = [template URIWithVariables:variables];
            if ( ! [expectation matchesURI:actualResult]) {
                STFail(@"%@", [expectation failureMessageWithTemplate:URITemplate
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

@end
