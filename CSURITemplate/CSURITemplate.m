//
//  CSURITemplate.m
//  CSURITemplate
//
//  Created by Will Harris on 26/02/2013.
//  Copyright (c) 2013 Cogenta Systems Ltd. All rights reserved.
//

#import "CSURITemplate.h"


@protocol CSURITemplateTerm <NSObject>

- (NSString *)expandWithVariables:(NSDictionary *)variables;

@end

@protocol CSURITemplateEscaper <NSObject>

- (NSString *)escapeItem:(id)item;

@end

@protocol CSURITemplateVariable <NSObject>

@property (readonly) NSString *key;
- (NSArray *)valuesWithVariables:(NSDictionary *)variables escaper:(id<CSURITemplateEscaper>)escaper;
- (void)enumerateKeyValuesWithVariables:(NSDictionary *)variables
                                escaper:(id<CSURITemplateEscaper>)escaper
                                  block:(void (^)(NSString *key, NSString *value))block;

@end

@interface CSURITemplateEscaping : NSObject

+ (NSObject<CSURITemplateEscaper> *)uriEscaper;
+ (NSObject<CSURITemplateEscaper> *)fragmentEscaper;

@end

@interface CSURITemplateURIEscaper : NSObject <CSURITemplateEscaper>

@end

@interface CSURITemplateFragmentEscaper : NSObject <CSURITemplateEscaper>

@end

@implementation CSURITemplateEscaping

+ (NSObject<CSURITemplateEscaper> *)uriEscaper
{
    return [[CSURITemplateURIEscaper alloc] init];
}

+ (NSObject<CSURITemplateEscaper> *)fragmentEscaper
{
    return [[CSURITemplateFragmentEscaper alloc] init];
}

@end

@interface NSObject (URITemplateAdditions)

- (NSString *)stringEscapedForURI;
- (NSString *)stringEscapedForFragment;
- (NSString *)basicString;
- (NSArray *)explodedItems;
- (NSArray *)explodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper;
- (NSString *)escapeWithEscaper:(id<CSURITemplateEscaper>)escaper;
- (void)enumerateExplodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
                                      defaultKey:(NSString *)key
                                           block:(void (^)(NSString *key, NSString *value))block;
- (BOOL)isInvalidForPrefixVariable;

@end

@implementation CSURITemplateURIEscaper

- (NSString *)escapeItem:(NSObject *)item
{
    return [item stringEscapedForURI];
}

@end

@implementation CSURITemplateFragmentEscaper

- (NSString *)escapeItem:(NSObject *)item
{
    return [item stringEscapedForFragment];
}

@end

@implementation NSObject (URITemplateAdditions)

- (NSString *)escapeWithEscaper:(id<CSURITemplateEscaper>)escaper
{
    return [escaper escapeItem:self];
}

- (NSString *)stringEscapedForURI
{
    return [[self basicString] stringEscapedForURI];
}

- (NSString *)stringEscapedForFragment
{
    return [[self basicString] stringEscapedForFragment];
}

- (NSString *)basicString
{
    return [self description];
}

- (NSArray *)explodedItems
{
    return [NSArray arrayWithObject:self];
}

- (NSArray *)explodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
{
    NSMutableArray *result = [NSMutableArray array];
    for (id value in [self explodedItems]) {
        [result addObject:[value escapeWithEscaper:escaper]];
    }
    return [NSArray arrayWithArray:result];
}

- (void)enumerateExplodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
                                      defaultKey:(NSString *)key
                                           block:(void (^)(NSString *, NSString *))block
{
    for (NSString *value in [self explodedItemsEscapedWithEscaper:escaper]) {
        block(key, value);
    }
}

- (BOOL)isInvalidForPrefixVariable
{
    return YES;
}

@end

@implementation NSString (URITemplateAdditions)

- (NSString *)stringEscapedForURI
{
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (__bridge CFStringRef) self,
                                                              NULL,
                                                              CFSTR("!*'();:@&=+$,/?%#[]"),
                                                              kCFStringEncodingUTF8));
}

- (NSString *)stringEscapedForFragment
{
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (__bridge CFStringRef) self,
                                                              NULL,
                                                              CFSTR(" "),
                                                              kCFStringEncodingUTF8));
}

- (NSString *)basicString
{
    return self;
}

- (BOOL)isInvalidForPrefixVariable
{
    return NO;
}

@end

@implementation NSArray (URITemplateAdditions)

- (NSString *)stringEscapedForURI
{
    NSMutableArray *result = [NSMutableArray array];
    for (id item in self) {
        [result addObject:[item stringEscapedForURI]];
    }
    return [result componentsJoinedByString:@","];
}


- (NSString *)stringEscapedForFragment
{
    NSMutableArray *result = [NSMutableArray array];
    for (id item in self) {
        [result addObject:[item stringEscapedForFragment]];
    }
    return [result componentsJoinedByString:@","];
}

- (NSString *)basicString
{
    NSMutableArray *result = [NSMutableArray array];
    for (id item in self) {
        [result addObject:[item basicString]];
    }
    return [result componentsJoinedByString:@","];
}

- (NSArray *)explodedItems
{
    return self;
}

@end

@implementation NSDictionary (URITemplateAdditions)

- (NSString *)stringEscapedForURI
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result addObject:[key stringEscapedForURI]];
        [result addObject:[obj stringEscapedForURI]];
    }];
    return [result componentsJoinedByString:@","];
}

- (NSString *)stringEscapedForFragment
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result addObject:[key stringEscapedForFragment]];
        [result addObject:[obj stringEscapedForFragment]];
    }];
    return [result componentsJoinedByString:@","];
}

- (NSString *)basicString
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result addObject:[key basicString]];
        [result addObject:[obj basicString]];
    }];
    return [result componentsJoinedByString:@","];
}

- (NSArray *)explodedItems
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result addObject:key];
        [result addObject:obj];
    }];
    return [NSArray arrayWithArray:result];
}

- (NSArray *)explodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateExplodedItemsEscapedWithEscaper:escaper
                                        defaultKey:nil
                                             block:^(NSString *k, NSString *v)
    {
        [result addObject:[NSString stringWithFormat:@"%@=%@", k, v]];
    }];
    return [NSArray arrayWithArray:result];
}

- (void)enumerateExplodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
                                      defaultKey:(NSString *)defaultKey
                                           block:(void (^)(NSString *, NSString *))block
{
    [self enumerateKeysAndObjectsUsingBlock:^(id k, id obj, BOOL *stop) {
        block([k escapeWithEscaper:escaper],
              [obj escapeWithEscaper:escaper]);
    }];
}

@end

@implementation NSNull (URITemplateDescriptions)

- (NSArray *)explodedItems
{
    return [NSArray array];
}

@end

#pragma mark -

@interface CSURITemplateLiteralTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSString *literal;

- (id)initWithLiteral:(NSString *)literal;

@end

@implementation CSURITemplateLiteralTerm

@synthesize literal;

- (id)initWithLiteral:(NSString *)aLiteral
{
    self = [super init];
    if (self) {
        literal = aLiteral;
    }
    return self;
}

- (NSString *)expandWithVariables:(NSDictionary *)variables
{
    return literal;
}

@end

@interface CSURITemplateInfixExpressionTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSArray *variablesExpression;
- (id)initWithVariables:(NSArray *)variables;
- (NSString *)infix;
- (NSString *)prepend;

@end

@implementation CSURITemplateInfixExpressionTerm

@synthesize variablesExpression;

- (id)initWithVariables:(NSArray *)theVariables
{
    self = [super init];
    if (self) {
        variablesExpression = theVariables;
    }
    return self;
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping uriEscaper];
}

- (NSString *)prepend
{
    return @"";
}

- (NSString *)infix
{
    return @"";
}

- (NSString *)expandWithVariables:(NSDictionary *)variables
{
    BOOL isFirst = YES;
    NSMutableString *result = [NSMutableString string];
    for (NSObject<CSURITemplateVariable> *variable in variablesExpression) {
        NSArray *values = [variable valuesWithVariables:variables
                                                escaper:[self escaper]];
        if ( ! values) {
            // An error was encountered expanding the variable.
            return nil;
        }
        
        for (NSString *value in values) {
            if (isFirst) {
                isFirst = NO;
                [result appendString:[self prepend]];
            } else {
                [result appendString:[self infix]];
            }
            
            [result appendString:value];
        }
    }
    
    return [NSString stringWithString:result];
}

@end

@interface CSURITemplateCommaExpressionTerm : CSURITemplateInfixExpressionTerm

@end

@implementation CSURITemplateCommaExpressionTerm

- (NSString *)infix
{
    return @",";
}

@end

@interface CSURITemplatePrependExpressionTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSArray *variablesExpression;

- (id)initWithVariables:(NSArray *)variables;

@end

@implementation CSURITemplatePrependExpressionTerm

@synthesize variablesExpression;

- (id)initWithVariables:(NSArray *)theVariables
{
    self = [super init];
    if (self) {
        variablesExpression = theVariables;
    }
    return self;
}

- (NSString *)prepend
{
    return @"";
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping uriEscaper];
}

- (NSString *)expandWithVariables:(NSDictionary *)variables
{
    NSMutableString *result = [NSMutableString string];
    for (NSObject<CSURITemplateVariable> *variable in variablesExpression) {
        for (NSString *value in [variable valuesWithVariables:variables
                                                      escaper:[self escaper]]) {
            [result appendString:[self prepend]];
            [result appendString:value];
        }
    }
    
    return [NSString stringWithString:result];
}


@end

@interface CSURITemplateSolidusExpressionTerm : CSURITemplatePrependExpressionTerm

@end

@implementation CSURITemplateSolidusExpressionTerm

- (NSString *)prepend
{
    return @"/";
}

@end


@interface CSURITemplateDotExpressionTerm : CSURITemplatePrependExpressionTerm

@end

@implementation CSURITemplateDotExpressionTerm

- (NSString *)prepend
{
    return @".";
}

@end


@interface CSURITemplateHashExpressionTerm : CSURITemplateCommaExpressionTerm

@end

@implementation CSURITemplateHashExpressionTerm

- (NSString *)prepend
{
    return @"#";
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping fragmentEscaper];
}

@end

@interface CSURITemplateQueryExpressionTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSArray *variablesExpression;
- (id)initWithVariables:(NSArray *)variables;
- (NSString *)prepend;

@end

@implementation CSURITemplateQueryExpressionTerm

@synthesize variablesExpression;

- (id)initWithVariables:(NSArray *)theVariables
{
    self = [super init];
    if (self) {
        variablesExpression = theVariables;
    }
    return self;
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping uriEscaper];
}

- (NSString *)prepend
{
    return @"?";
}

- (NSString *)expandWithVariables:(NSDictionary *)variables
{
    __block BOOL isFirst = YES;
    NSMutableString *result = [NSMutableString string];
    __block BOOL hasError = NO;
    for (NSObject<CSURITemplateVariable> *variable in variablesExpression) {
        [variable enumerateKeyValuesWithVariables:variables
                                          escaper:[self escaper]
                                            block:^(NSString *k, NSString *v)
        {
            if ( ! k && ! v) {
                // An error ocurred enumerating key values.
                hasError = YES;
                return;
            }
            
            if (isFirst) {
                isFirst = NO;
                [result appendString:[self prepend]];
            } else {
                [result appendString:@"&"];
            }
            
            [result appendString:k];
            [result appendString:@"="];
            [result appendString:v];
        }];
    }
    
    if (hasError) {
        return nil;
    }
    
    return [NSString stringWithString:result];
}

@end

@interface CSURITemplateParameterExpressionTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSArray *variablesExpression;
- (id)initWithVariables:(NSArray *)variables;

@end

@implementation CSURITemplateParameterExpressionTerm

@synthesize variablesExpression;

- (id)initWithVariables:(NSArray *)theVariables
{
    self = [super init];
    if (self) {
        variablesExpression = theVariables;
    }
    return self;
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping uriEscaper];
}

- (NSString *)expandWithVariables:(NSDictionary *)variables
{
    NSMutableString *result = [NSMutableString string];
    __block BOOL hasError = NO;
    for (NSObject<CSURITemplateVariable> *variable in variablesExpression) {
        [variable enumerateKeyValuesWithVariables:variables
                                          escaper:[self escaper]
                                            block:^(NSString *k, NSString *v)
         {
             if ( ! k && ! v) {
                 // An error ocurred enumerating key values.
                 hasError = YES;
                 return;
             }
             
             [result appendString:@";"];
             
             [result appendString:k];
             
             if ( ! [v isEqualToString:@""]) {
                 [result appendString:@"="];
                 [result appendString:v];
             }
         }];
    }
    
    if (hasError) {
        return nil;
    }
    
    return [NSString stringWithString:result];
}

@end

@interface CSURITemplateReservedExpressionTerm : CSURITemplateCommaExpressionTerm

@end

@implementation CSURITemplateReservedExpressionTerm

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping fragmentEscaper];
}

@end

@interface CSURITemplateQueryContinuationExpressionTerm : CSURITemplateQueryExpressionTerm

@end

@implementation CSURITemplateQueryContinuationExpressionTerm

- (NSString *)prepend
{
    return @"&";
}

@end

#pragma mark -

@interface CSURITemplateUnmodifiedVariable : NSObject <CSURITemplateVariable>

- (id)initWithKey:(NSString *)key;

@end

@implementation CSURITemplateUnmodifiedVariable

@synthesize key;

- (id)initWithKey:(NSString *)aKey
{
    self = [super init];
    if (self) {
        key = aKey;
    }
    return self;
}

- (NSArray *)valuesWithVariables:(NSDictionary *)variables escaper:(id<CSURITemplateEscaper>)escaper
{
    id value = [variables objectForKey:key];
    if ( ! value || (NSNull *) value == [NSNull null]) {
        return [NSArray array];
    }
    
    if ([value isKindOfClass:[NSArray class]] && [value count] == 0) {
        return [NSArray array];
    }
    
    NSMutableArray *result = [NSMutableArray array];
    NSString *escaped = [value escapeWithEscaper:escaper];
    [result addObject:escaped];
    
    return [NSArray arrayWithArray:result];
}

- (void)enumerateKeyValuesWithVariables:(NSDictionary *)variables
                                escaper:(id<CSURITemplateEscaper>)escaper
                                  block:(void (^)(NSString *key, NSString *value))block
{
    id value = [variables objectForKey:key];
    if ( ! value || (NSNull *) value == [NSNull null]) {
        return;
    }
    
    if ([value isEqual:@[]]) {
        block(key, @"");
        return;
    }
    
    NSString *escaped = [value escapeWithEscaper:escaper];
    block(key, escaped);
}


@end

@interface CSURITemplateExplodedVariable : NSObject <CSURITemplateVariable>

- (id)initWithKey:(NSString *)key;

@end

@implementation CSURITemplateExplodedVariable

@synthesize key;

- (id)initWithKey:(NSString *)aKey
{
    self = [super init];
    if (self) {
        key = aKey;
    }
    return self;
}

- (NSArray *)valuesWithVariables:(NSDictionary *)variables escaper:(id<CSURITemplateEscaper>)escaper
{
    id values = [variables objectForKey:key];
    if ( ! values) {
        return [NSArray array];
    }
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (id value in [values explodedItemsEscapedWithEscaper:escaper]) {
        [result addObject:value];
    }
    
    return [NSArray arrayWithArray:result];
}

- (void)enumerateKeyValuesWithVariables:(NSDictionary *)variables
                                escaper:(id<CSURITemplateEscaper>)escaper
                                  block:(void (^)(NSString *key, NSString *value))block
{
    id values = [variables objectForKey:key];
    if ( ! values) {
        return;
    }
    
    [values enumerateExplodedItemsEscapedWithEscaper:escaper
                                          defaultKey:key
                                               block:block];
}

@end

@interface CSURITemplatePrefixedVariable : NSObject <CSURITemplateVariable>

@property (nonatomic, assign) NSUInteger maxLength;

- (id)initWithKey:(NSString *)key maxLength:(NSUInteger)maxLength;

@end

@implementation CSURITemplatePrefixedVariable

@synthesize key;
@synthesize maxLength;

- (id)initWithKey:(NSString *)aKey maxLength:(NSUInteger)aMaxLength
{
    self = [super init];
    if (self) {
        key = aKey;
        maxLength = aMaxLength;
    }
    return self;
}

- (NSArray *)valuesWithVariables:(NSDictionary *)variables escaper:(id<CSURITemplateEscaper>)escaper
{
    id value = [variables objectForKey:key];
    
    if ([value isInvalidForPrefixVariable]) {
        // Only simple strings may be prefixed.
        return nil;
    }
    
    if ( ! value || (NSNull *) value == [NSNull null]) {
        return [NSArray array];
    }

    NSMutableArray *result = [NSMutableArray array];
    NSString *description = [value basicString];
    if (maxLength <= [description length]) {
        description = [description substringToIndex:maxLength];
    }
    
    [result addObject:[description escapeWithEscaper:escaper]];
    
    return [NSArray arrayWithArray:result];
}

- (void)enumerateKeyValuesWithVariables:(NSDictionary *)variables
                                escaper:(id<CSURITemplateEscaper>)escaper
                                  block:(void (^)(NSString *key, NSString *value))block
{
    NSArray *values = [self valuesWithVariables:variables escaper:escaper];
    if ( ! values) {
        // An error was encountered expanding the variables.
        block(nil, nil);
        return;
    }
    
    for (NSString *value in values) {
        block(key, value);
    }
}

@end

#pragma mark -

@interface CSURITemplate ()

@property (nonatomic, strong) NSString *URITemplate;
@property (nonatomic, strong) NSMutableArray *terms;
@property (readonly) BOOL hasError;

@end

@implementation CSURITemplate

@synthesize URITemplate;
@synthesize terms;
@synthesize hasError;

- (id)initWithURITemplate:(NSString *)aURITemplate
{
    self = [super init];
    if (self) {
        URITemplate = aURITemplate;
    }
    
    return self;
}

- (NSObject<CSURITemplateVariable> *)variableWithVarspec:(NSString *)varspec
{
    if ([varspec rangeOfString:@"$"].location != NSNotFound) {
        // Varspec contains a forbidden character.
        return nil;
    }
    NSMutableCharacterSet *varchars = [NSMutableCharacterSet alphanumericCharacterSet];
    [varchars addCharactersInString:@"._%"];
                                
    NSCharacterSet *modifierStartCharacters = [NSCharacterSet characterSetWithCharactersInString:@":*"];
    NSScanner *scanner = [NSScanner scannerWithString:varspec];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    NSString *key = nil;
    [scanner scanCharactersFromSet:varchars intoString:&key];
    
    NSString *modifierStart = nil;
    [scanner scanCharactersFromSet:modifierStartCharacters intoString:&modifierStart];
    
    if ([modifierStart isEqualToString:@"*"]) {
        // Modifier is explode.

        if ( ! [scanner isAtEnd]) {
            // There were extra characters after the explode modifier.
            return nil;
        }
        
        return [[CSURITemplateExplodedVariable alloc] initWithKey:key];
    } else if ([modifierStart isEqualToString:@":"]) {
        // Modifier is prefix.
        NSCharacterSet *oneToNine = [NSCharacterSet characterSetWithCharactersInString:@"123456789"];
        NSCharacterSet *zeroToNine = [NSCharacterSet decimalDigitCharacterSet];
        NSString *firstDigit = @"";
        if ( ! [scanner scanCharactersFromSet:oneToNine intoString:&firstDigit]) {
            // The max-chars does not start with a valid digit.
            return nil;
        }
        NSString *restDigits = @"";
        [scanner scanCharactersFromSet:zeroToNine intoString:&restDigits];
        NSString *digits = [firstDigit stringByAppendingString:restDigits];
        
        if ( ! [scanner isAtEnd]) {
            // The max-chars is not entirely digits.
            return nil;
        }

        NSUInteger maxLength = [digits integerValue];
        return [[CSURITemplatePrefixedVariable alloc] initWithKey:key
                                                        maxLength:maxLength];
    } else {
        // No modifier.
        
        if ( ! [scanner isAtEnd]) {
            // There were extra characters after the key.
            return nil;
        }
        
        return [[CSURITemplateUnmodifiedVariable alloc] initWithKey:key];
    }
    
    return nil;
}

- (NSArray *)variablesWithVariableList:(NSString *)variableList
{
    NSMutableArray *variables = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:variableList];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    while ( ! [scanner isAtEnd]) {
        NSString *varspec = nil;
        [scanner scanUpToString:@"," intoString:&varspec];
        [scanner scanString:@"," intoString:NULL];
        NSObject<CSURITemplateVariable> *variable = [self variableWithVarspec:varspec];
        if ( ! variable) {
            // An error was encountered parsing the varspec.
            return nil;
        }
        [variables addObject:variable];
    }
    return variables;
}

- (NSObject<CSURITemplateTerm> *)termWithOperator:(NSString *)operator
                                     variableList:(NSString *)variableList
{
    if ([operator length] > 1) {
        // The term has an invalid operator.
        return nil;
    }
    
    NSArray *variables = [self variablesWithVariableList:variableList];
    if ( ! variables) {
        // An error was encountered parsing a variable.
        return nil;
    }
    
    if ([operator isEqualToString:@"/"]) {
        return [[CSURITemplateSolidusExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"."]) {
        return [[CSURITemplateDotExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"#"]) {
        return [[CSURITemplateHashExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"?"]) {
        return [[CSURITemplateQueryExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@";"]) {
        return [[CSURITemplateParameterExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"+"]) {
        return [[CSURITemplateReservedExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"&"]) {
        return [[CSURITemplateQueryContinuationExpressionTerm alloc] initWithVariables:variables];
    } else if ( ! operator) {
        return [[CSURITemplateCommaExpressionTerm alloc] initWithVariables:variables];
    } else {
        // The operator is unknown or reserved.
        return nil;
    }
}

- (NSObject<CSURITemplateTerm> *)termWithExpression:(NSString *)expression
{
    NSCharacterSet *operators = [NSCharacterSet characterSetWithCharactersInString:@"+#./;?&=,!@|"];
    NSScanner *scanner = [NSScanner scannerWithString:expression];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    NSString *operator = nil;
    [scanner scanCharactersFromSet:operators intoString:&operator];
    return [self termWithOperator:operator
                     variableList:[expression substringFromIndex:scanner.scanLocation]];
}

- (void)loadTerms
{
    if (terms || hasError) {
        return;
    }
    
    terms = [NSMutableArray array];
    
    NSScanner *scanner = [NSScanner scannerWithString:URITemplate];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    while ( ! [scanner isAtEnd]) {
        NSCharacterSet *curlyBrackets = [NSCharacterSet
                                         characterSetWithCharactersInString:@"{}"];
        NSString *literal = nil;
        if ([scanner scanUpToCharactersFromSet:curlyBrackets
                                    intoString:&literal]) {
            CSURITemplateLiteralTerm *term = [[CSURITemplateLiteralTerm alloc]
                                                 initWithLiteral:literal];
            [terms addObject:term];
        }
        
        NSString *curlyBracket = nil;
        [scanner scanCharactersFromSet:curlyBrackets intoString:&curlyBracket];
        if ([curlyBracket isEqualToString:@"}"]) {
            // An expression was closed but not opened.
            hasError = YES;
            return;
        }
        
        NSString *expression = nil;
        if ([scanner scanUpToString:@"}" intoString:&expression]) {
            if ( ! [scanner scanString:@"}" intoString:NULL]) {
                // An expression was opened not closed.
                hasError = YES;
                return;
            }
            
            NSObject<CSURITemplateTerm> *term = [self termWithExpression:expression];
            if ( ! term) {
                // An error was encountered parsing the term expression.
                hasError = YES;
                return;
            }
            
            [terms addObject:term];
        }
    }
}

- (NSString *)URIWithVariables:(NSDictionary *)variables
{
    [self loadTerms];
    if (hasError) {
        // An error was encountered parsing the template.
        return nil;
    }
    
    NSMutableString *result = [NSMutableString string];
    for (NSObject<CSURITemplateTerm> *term in terms) {
        NSString *value = [term expandWithVariables:variables];
        if ( ! value) {
            // An error was encountered expanding the term.
            hasError = YES;
            return nil;
        }
        [result appendString:value];
    }
    return [NSString stringWithString:result];
}

@end
