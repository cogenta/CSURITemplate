CSURITemplate
=============

CSURITemplate is an Objective-C implementation of
[RFC6570: URI Template](http://tools.ietf.org/html/rfc6570) up to Level 4 of
the spec.

Example usage:

    CSURITemplate *template = [[CSURITemplate alloc]
                               initWithURITemplate:@"{?list*}"];
    NSDictionary *variables = @{@"list": @[@"red", @"green", @"blue"]};
    NSString *uri = [template URIWithVariables:variables];
    assert([uri isEqualToString:@"?list=red&list=green&list=blue"]);

Installation
------------

[CocoaPods](http://cocoapods.org/) is the easiest way to use CSURITemplate.

    platform :ios, '6.0'
    pod 'CSURITemplate', :git => 'https://github.com/cogenta/CSURITemplate.git'
