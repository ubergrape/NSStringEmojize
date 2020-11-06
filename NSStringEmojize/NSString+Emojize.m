//
//  NSString+Emojize.m
//  Field Recorder
//
//  Created by Jonathan Beilin on 11/5/12.
//  Copyright (c) 2014 DIY. All rights reserved.
//

#import "NSString+Emojize.h"
#import "emojis.h"

BOOL NSRangeIntersectsRange(NSRange range1, NSRange range2) {
    if (range1.location > range2.location + range2.length) return NO;
    if (range2.location > range1.location + range1.length) return NO;
    return YES;
}

@implementation NSString (Emojize)

- (NSString *)emojizedString
{
    return [NSString emojizedStringWithString:self];
}

+ (NSString *)emojizedStringWithString:(NSString *)text
{
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex = nil;
    static dispatch_once_t dDetector = 0;
    static NSDataDetector *urlDetector = nil;
    dispatch_once(&onceToken, ^{
        regex = [[NSRegularExpression alloc] initWithPattern:@"(:[a-z0-9-+_]+:)" options:NSRegularExpressionCaseInsensitive error:NULL];
    });
    
    dispatch_once(&dDetector, ^{
        urlDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
    });
    
    __block NSString *resultText = text;
    NSRange matchingRange = NSMakeRange(0, [resultText length]);
    NSArray<NSTextCheckingResult *> *urlMatches = [urlDetector matchesInString:text options:NSMatchingReportCompletion range:matchingRange];
    [regex enumerateMatchesInString:resultText options:NSMatchingReportCompletion range:matchingRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         if (result && ([result resultType] == NSTextCheckingTypeRegularExpression) && !(flags & NSMatchingInternalError)) {
             NSRange range = result.range;
             if (range.location != NSNotFound) {
                 BOOL rangesIntersects = NO;
                 for (NSTextCheckingResult *urlMatch in urlMatches) {
                     rangesIntersects = NSRangeIntersectsRange(urlMatch.range, range);
                     if (rangesIntersects) {
                         break;
                     }
                 }
                 NSString *code = [text substringWithRange:range];
                 NSString *unicode = self.emojiAliases[code];
                 if (unicode && !rangesIntersects) {
                     resultText = [resultText stringByReplacingOccurrencesOfString:code withString:unicode];
                 }
             }
         }
     }];
    
    return resultText;
}

+ (NSDictionary *)emojiAliases {
    static NSDictionary *_emojiAliases;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emojiAliases = EMOJI_HASH;
    });
    return _emojiAliases;
}

@end
