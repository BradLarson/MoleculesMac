//
//  NSData+Gzip.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/1/2008.
//
//  This extension is adapted from the examples present at the CocoaDevWiki at http://www.cocoadev.com/index.pl?NSDataCategory

#import <Foundation/Foundation.h>


@interface NSData (Gzip)
- (id)initWithGzippedData: (NSData *)gzippedData;
- (NSData *) gzipDeflate;

@end