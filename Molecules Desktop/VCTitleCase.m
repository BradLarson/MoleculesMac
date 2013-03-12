//
//  VCTitleCase.m
//  Title Case extension for NSString
//
//  Based on titlecase.pl by:
//    John Gruber
//    http://daringfireball.net/
//    10 May 2008
//
//  Cocoa Foundation version by:
//    Marshall Elfstrand
//    http://vengefulcow.com/
//    24 May 2008
//
//  License: http://www.opensource.org/licenses/mit-license.php
//
//  Modified by Brad Larson to contain all-caps acronyms


#import "VCTitleCase.h"

@implementation NSString (VCTitleCase)

- (NSString *)titlecaseString
{
    static NSArray *shortWords = nil, *shortAcronyms;
    static NSMutableCharacterSet *wordStartCharacterSet;
    static NSMutableCharacterSet *wordMiddleCharacterSet;
    static NSMutableCharacterSet *wordEndCharacterSet;
    static NSMutableCharacterSet *wordIgnoreCharacterSet;
    
    // Initialize the list of "short" words that remain lowercase.
    if (!shortWords) {
        shortWords = [[NSArray alloc] initWithObjects:
            @"a", @"an", @"and", @"as", @"at", @"but", @"by", @"en", @"for",
            @"if", @"in", @"of", @"on", @"or", @"the", @"to", @"v", @"via",
            @"vs", nil];
    }

	if (!shortAcronyms) {
        shortAcronyms = [[NSArray alloc] initWithObjects:
					  @"dna", @"rna", @"trna", @"trnaphe", @"hiv", @"nmr", nil];
    }
	
    // Initialize the set of characters allowed at the start of words.
    if (!wordStartCharacterSet) {
        wordStartCharacterSet = [[NSCharacterSet uppercaseLetterCharacterSet] mutableCopy];
        [wordStartCharacterSet formUnionWithCharacterSet:[NSCharacterSet lowercaseLetterCharacterSet]];
    }
    
    // Initialize the set of characters allowed in the middle of words.
    if (!wordMiddleCharacterSet) {
        wordMiddleCharacterSet = [[NSCharacterSet uppercaseLetterCharacterSet] mutableCopy];
        [wordMiddleCharacterSet formUnionWithCharacterSet:[NSCharacterSet lowercaseLetterCharacterSet]];
        [wordMiddleCharacterSet addCharactersInString:@".&'’"];
    }
    
    // Initialize the set of characters allowed at the end of words.
    if (!wordEndCharacterSet) wordEndCharacterSet = wordStartCharacterSet;
    
    // Initialize the set of characters that cause a word to be ignored
    // when they appear in the middle.
    if (!wordIgnoreCharacterSet) {
        wordIgnoreCharacterSet = [[NSCharacterSet uppercaseLetterCharacterSet] mutableCopy];
        [wordIgnoreCharacterSet addCharactersInString:@"."];
    }

    // Create a mutable copy of the string that we can modify in-place.
    NSMutableString *newString = [self mutableCopy];

    // Create a local autorelease pool for the temporary objects we're making.
    @autoreleasepool{
        
        // Create a scanner that we can use to locate words in the string.
        NSScanner *scanner = [NSScanner scannerWithString:self];
        [scanner setCaseSensitive:YES];
        
        // Begin scanning for words.
        NSRange currentRange;        // Range of word located by scanner
        NSString *word = nil;              // Extracted word
        NSString *lowercaseWord = nil;     // Lowercase version of extracted word
        NSRange ignoreTriggerRange;  // Range of character causing word to be ignored
        BOOL isFirstWord = YES;      // To determine whether to capitalize small word
        while (![scanner isAtEnd]) {
            
            // Locate the beginning of the next word.
            [scanner scanUpToCharactersFromSet:wordStartCharacterSet
                                    intoString:NULL];
            if ([scanner scanLocation] >= [self length]) continue;  // No more words
            currentRange = NSMakeRange([scanner scanLocation], 1);
            
            // Check to see if we stopped on whitespace and advance to the
            // actual beginning of the word.
            if (![wordStartCharacterSet characterIsMember:[self characterAtIndex:[scanner scanLocation]]]) {
                [scanner setScanLocation:[scanner scanLocation] + 1];
                currentRange = NSMakeRange([scanner scanLocation], 1);
            }
            
            // Advance to the next character in the word.
            [scanner scanString:[self substringWithRange:currentRange]
                     intoString:NULL];
            if ([scanner scanLocation] >= [self length]) continue;  // No more words
            
            // See if the next character is a valid word character, and if so,
            // scan through the end of the word.
            if ([wordMiddleCharacterSet characterIsMember:[self characterAtIndex:[scanner scanLocation]]]) {
                [scanner scanCharactersFromSet:wordMiddleCharacterSet
                                    intoString:NULL];
                currentRange.length = [scanner scanLocation] - currentRange.location;
            }
            
            // Back off the word until it ends with a valid character.
            unichar lastCharacter = [self characterAtIndex:(NSMaxRange(currentRange) - 1)];
            while (![wordEndCharacterSet characterIsMember:lastCharacter]) {
                [scanner setScanLocation:[scanner scanLocation] - 1];
                currentRange.length -= 1;
                lastCharacter = [self characterAtIndex:(NSMaxRange(currentRange) - 1)];
            }
            
            // We have now located a word.
            word = [self substringWithRange:currentRange];
            lowercaseWord = [word lowercaseString];
            
            // Check to see if the word needs to be capitalized.
            // Words that have dots in the middle or that already contain
            // capitalized letters in the middle (e.g. "iTunes") are ignored.
            ignoreTriggerRange = [self
                                  rangeOfCharacterFromSet:wordIgnoreCharacterSet
                                  options:NSLiteralSearch
                                  range:NSMakeRange(currentRange.location + 1, currentRange.length - 1)
                                  ];
            if (ignoreTriggerRange.location == NSNotFound) {
                if ([word rangeOfString:@"&"].location != NSNotFound) {
                    // Uppercase words that contain ampersands.
                    [newString replaceCharactersInRange:currentRange
                                             withString:[word uppercaseString]];
                } else {
                    if ((!isFirstWord) && [shortWords containsObject:lowercaseWord]) {
                        // Lowercase small words.
                        [newString replaceCharactersInRange:currentRange
                                                 withString:lowercaseWord];
                    } else if ([shortAcronyms containsObject:lowercaseWord]) {
                        [newString replaceCharactersInRange:currentRange 
                                                 withString:[word uppercaseString]];
                    } else {
                        // Capitalize word.
                        [newString replaceCharactersInRange:currentRange
                                                 withString:[word capitalizedString]];
                    }
                }
            }
            
            isFirstWord = NO;
        }
        
        // Make sure the last word is capitalized, even if it is a small word.
        if (lowercaseWord && [shortWords containsObject:lowercaseWord]) {
            [newString replaceCharactersInRange:currentRange
                                     withString:[lowercaseWord capitalizedString]];
        }
        
    };

    NSString *resultString = [newString copy];

    return resultString;
}

@end
