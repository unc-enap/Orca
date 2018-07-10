//
//  MultiStateBox.m
//  Orca
//
//  Created by Benjamin Land on 1/18/16.
//
//

#import <Foundation/Foundation.h>
#import "ORMultiStateBox.h"

@implementation ORMultiStateBox

void freeBMPData(void *info, const void *data, size_t size) {
    free((void*)data);
}

+ (NSImage*) splitBox:(int)sz pad:(int)bd bevel:(int)bev upLeft:(NSColor*)ul botRight:(NSColor*)br
{
    int dim = sz;
    sz = sz - 2*bd;
    
    ul = [ul colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    br = [br colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if (!ul || !br) {
        NSLog(@"Failed to convert colors!");
        return nil;
    }
    uint32_t ulint = 0xFF000000|(((int)([ul blueComponent]*0xFF))<<16)|(((int)([ul greenComponent]*0xFF))<<8)|(((int)([ul redComponent]*0xFF))<<0);
    uint32_t brint = 0xFF000000|(((int)([br blueComponent]*0xFF))<<16)|(((int)([br greenComponent]*0xFF))<<8)|(((int)([br redComponent]*0xFF))<<0);

    
    uint32_t *bmp = malloc(dim*dim*sizeof(uint32_t));
    for (int x = 0; x < dim; x++) {
        for (int y = 0; y < dim; y++) {
            if ((x < bd || x-bd > sz) || (y < bd || y-bd > sz)) {
                bmp[y*dim+x] = 0x0;
            } else {
                if (x+y-2*bd > sz && (x-bd > sz-bev || y-bd > sz-bev)) {
                    int val = (x+y-2*bd < sz) ? ulint : brint;
                    int a = x-bd-sz+bev;
                    int b = y-bd-sz+bev;
                    float fact = (1.0 - (a > b ? a : b)/(double)bev) * 0.3 + 0.7;
                    val = 0xFF000000 | (((int)(((val>>16)&0xFF)*fact))<<16) | (((int)(((val>>8)&0xFF)*fact))<<8) | (((int)(((val>>0)&0xFF)*fact))<<0);
                    bmp[y*dim+x] = val;
                } else {
                    bmp[y*dim+x] = (x+y-2*bd < sz) ? ulint : brint;
                }
            }
        }
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bmp, dim*dim*sizeof(uint32_t), &freeBMPData);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * dim;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB	();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(dim, dim, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
    
    NSImage *img = [[NSImage alloc] initWithCGImage:iref size:NSMakeSize(dim, dim)];
    CGImageRelease(iref);
    CGColorSpaceRelease(colorSpaceRef);
    return [img autorelease];
}

- (ORMultiStateBox*) initWithStates:(NSDictionary*)stateDictionary size:(int)sz pad:(int)pad bevel:(int)bev
{
    if (self = [super init]) {
        imageDictionary = [[NSMutableDictionary alloc] init];
        for (id ulState in stateDictionary) {
            NSColor *ulColor = [stateDictionary objectForKey:ulState];
            NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
            for (id brState in stateDictionary) {
                NSColor *brColor = [stateDictionary objectForKey:brState];
                NSImage *img = [ORMultiStateBox splitBox:sz pad:pad bevel:bev upLeft:ulColor botRight:brColor];
                [dict setObject:img forKey:brState];
            }
            [imageDictionary setObject:dict forKey:ulState];
        }
    }
    return self;
}

- (void) dealloc
{
    [imageDictionary release];
    [super dealloc];
}

- (NSImage*) upLeft:(id)ul botRight:(id)br;
{
    return [[imageDictionary objectForKey:ul] objectForKey:br];
}

@end