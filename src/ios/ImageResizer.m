#import "ImageResizer.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPluginResult.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define PROTONET_PHOTO_PREFIX @"protonet_"

static NSInteger count = 0;

@implementation ImageResizer {
    UIImage* sourceImage;
}

- (void) resize:(CDVInvokedUrlCommand*)command
{
    __block PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];

    imageRequestOptions.synchronous = YES;

    NSLog(@"IMAGE RESIZER START ----------------------------------------------------------------------------");

    // get the arguments and the stuff inside of it
    NSDictionary* arguments = [command.arguments objectAtIndex:0];
    NSString* imageUrlString = [arguments objectForKey:@"uri"];
    NSLog(@"Image Resizer Image URL : %@",imageUrlString);

    NSString* quality = [arguments objectForKey:@"quality"];
    CGSize frameSize = CGSizeMake([[arguments objectForKey:@"width"] floatValue], [[arguments objectForKey:@"height"] floatValue]);
    NSString* fileName = [arguments objectForKey:@"fileName"];

    //    //Get the image from the path
    NSURL* imageURL = [NSURL URLWithString:imageUrlString];

    sourceImage = [UIImage imageWithData: [NSData dataWithContentsOfURL: imageURL]];

    PHFetchResult *savedAssets = [PHAsset fetchAssetsWithLocalIdentifiers:@[fileName] options:nil];
    [savedAssets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        //this gets called for every asset from its localIdentifier you saved

        [[PHImageManager defaultManager]
         requestImageDataForAsset:asset
         options:imageRequestOptions
         resultHandler:^(NSData *imageData, NSString *dataUTI,
                         UIImageOrientation orientation,
                         NSDictionary *info)
         {
             sourceImage  = [UIImage imageWithData:imageData];
         }];

    }];

    // NSLog(@"image resizer:%@",  (sourceImage  ? @"image exsist" : @"null" ));

    // UIImage *tempImage = nil;
    // CGSize targetSize = frameSize;
    // UIGraphicsBeginImageContext(targetSize);

    // CGRect thumbnailRect = CGRectMake(0, 0, 0, 0);
    // thumbnailRect.origin = CGPointMake(0.0,0.0);
    // thumbnailRect.size.width  = targetSize.width;
    // thumbnailRect.size.height = targetSize.height;

    // [sourceImage drawInRect:thumbnailRect];

    // tempImage = UIGraphicsGetImageFromCurrentImageContext();
    // NSLog(@"image resizer:%@",  (tempImage  ? @"image exsist" : @"null" ));

    NSLog(@"image resizer:%@ to %f, %f",  (sourceImage  ? @"image exist" : @"null" ), frameSize.width, frameSize.height);
    NSLog(@"image org size: %f, %f",  sourceImage.size.width, sourceImage.size.height);

    /* keep aspect ratio */
    CGSize imageSize = sourceImage.size;
    CGSize viewSize = CGSizeMake(frameSize.width, frameSize.height); // size in which you want to draw
    float hfactor = imageSize.width / viewSize.width;
    float vfactor = imageSize.height / viewSize.height;
    float factor = fmax(hfactor, vfactor);
    float newWidth = imageSize.width / factor;
    float newHeight = imageSize.height / factor;
    CGRect thumbnailRect = CGRectMake(0, 0, newWidth, newHeight);

    NSLog(@"image new size: %f, %f",  newWidth, newHeight);

    // prepare context
    UIImage *tempImage = nil;
    CGSize targetSize = frameSize;
    targetSize.width = newWidth;
    targetSize.height = newHeight;
    UIGraphicsBeginImageContext(targetSize);

    // draw in new
    [sourceImage drawInRect:thumbnailRect];

    tempImage = UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"image resizer:%@",  (tempImage  ? @"image exsist" : @"null" ));

    UIGraphicsEndImageContext();
    NSData *imageData = UIImageJPEGRepresentation(tempImage, [quality floatValue] / 100.0f );
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"img%d.jpg",count]];
    count++;
    CDVPluginResult* result = nil;

    if (![imageData writeToFile:imagePath atomically:NO])
    {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:@"error save image"];
    }
    else
    {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[NSURL fileURLWithPath:imagePath] absoluteString]];
    }

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

@end
