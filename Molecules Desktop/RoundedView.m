//
//  RoundedView.m
//  RoundedFloatingPanel
//
//  Created by Matt Gemmell on Thu Jan 08 2004.
//  <http://iratescotsman.com/>
//


#import "RoundedView.h"

@implementation RoundedView


- (void)drawRect:(NSRect)rect
{
    NSRect bgRect = rect;
    int minX = NSMinX(bgRect);
    int maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect);
    int maxY = NSMaxY(bgRect);

    float radius = 25.0;

    NSGraphicsContext    *graphicsContext = [NSGraphicsContext currentContext];
    CGContextRef context = (CGContextRef) [graphicsContext graphicsPort];
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();

    CGFloat values[4] = {0.0, 0.0, 0.0, 0.85};
    CGColorRef greyForBackground = CGColorCreate(space, values);

    CGContextSetFillColorWithColor(context, greyForBackground);
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, minX + radius, minY);
    CGContextAddArc(context, maxX - radius, minY + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, maxX - radius, maxY - radius, radius, 0, M_PI / 2, 0);
    CGContextAddArc(context, minX + radius, maxY - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, minX + radius, minY + radius, radius, M_PI, 3 * M_PI / 2, 0);
    CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathFill);
    
    CGColorRelease(greyForBackground);
    CGColorSpaceRelease(space);
}


@end
