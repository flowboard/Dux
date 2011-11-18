//
//  DuxPHPLanguage.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-16.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPHPLanguage.h"

static NSRegularExpression *keywordsExpression;
static NSIndexSet *keywordIndexSet = nil;

@implementation DuxPHPLanguage

+ (void)initialize
{
  [super initialize];
  
  NSArray *keywords = [NSArray arrayWithObjects:@"abstract", @"and", @"array", @"as", @"break", @"case", @"catch", @"cfunction", @"class", @"clone", @"const", @"continue", @"declare", @"default", @"die", @"do", @"double", @"else", @"elseif", @"empty", @"enddeclare", @"endfor", @"endforeach", @"endif", @"endswitch", @"endwhile", @"eval", @"exit", @"extends", @"false", @"final", @"float", @"for", @"foreach", @"function", @"global", @"goto", @"if", @"implements", @"include", @"instanceof", @"int", @"integer", @"interface", @"isset", @"namespace", @"new", @"null", @"old_function", @"or", @"print"@"private", @"protected", @"public", @"return", @"require", @"require_once", @"string", @"static", @"switch", @"throw", @"true", @"try", @"use", @"var", @"while", @"xor", @"__CLASS__", @"__DIR__", @"__FILE__", @"__FUNCTION__", @"__LINE__", @"__METHOD__", @"__NAMESPACE__", nil];
  
  keywordsExpression = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b(%@)\\b", [keywords componentsJoinedByString:@"|"]] options:NSRegularExpressionCaseInsensitive error:NULL];
}

- (DuxLanguageElement *)baseElement
{
  return [DuxPHPBaseElement sharedInstance];
}

- (void)wrapCommentsAroundRange:(NSRange)commentRange ofTextView:(NSTextView *)textView
{
  NSString *existingString = [textView.textStorage.string substringWithRange:commentRange];
  
  NSString *commentedString= [NSString stringWithFormat:@"// %@", existingString];
  commentedString = [commentedString stringByReplacingOccurrencesOfString:@"(\n)" withString:@"$1// " options:NSRegularExpressionSearch range:NSMakeRange(0, commentedString.length)];
  
  [textView insertText:commentedString replacementRange:commentRange];
  [textView setSelectedRange:NSMakeRange(commentRange.location, commentedString.length)];
}

+ (NSIndexSet *)keywordIndexSet
{
  return keywordIndexSet;
}

- (void)prepareToParseTextStorage:(NSTextStorage *)textStorage
{
  [super prepareToParseTextStorage:textStorage];
  
  NSMutableIndexSet *keywordIndexesMutable = [[NSIndexSet indexSet] mutableCopy];
  [keywordsExpression enumerateMatchesInString:textStorage.string options:0 range:NSMakeRange(0, textStorage.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    [keywordIndexesMutable addIndexesInRange:match.range];
  }];
  
  keywordIndexSet = [keywordIndexesMutable copy];
}

@end