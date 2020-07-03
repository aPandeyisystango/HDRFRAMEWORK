#import "OpenCVWrapper.h"
#import "UIImage+OpenCV.h"
#import "UIImage+Rotate.h"
#import "HDR.hpp"
#import "Cropping.h"
#define HIGHT_COMPRESS_RATIO 0.2
#define LOW_COMPRESS_RATIO 0.5

@implementation OpenCVWrapper

+ (UIImage*)processHDRWithImageArray:(NSArray*)images andExposures:(NSArray*)exposures {
    if ([images count] == 0){
        NSLog (@"imageArray is empty");
        return nil;
    }
    std::vector<cv::Mat> matImages;
    std::vector<float> times;

    float ratio = HIGHT_COMPRESS_RATIO;
    UIImage *image = [images firstObject];
    if (image.size.height < 5000) {
        ratio = LOW_COMPRESS_RATIO;
    }

    NSMutableArray* compressedImageArray =[NSMutableArray new];
    for(UIImage *rawImage in images){
        UIImage *compressedImage=[self compressedToRatio:rawImage ratio:ratio];
        [compressedImageArray addObject:compressedImage];
    }
    
    for (id image in compressedImageArray) {
        if ([image isKindOfClass: [UIImage class]]) {
            /*
             All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
             */
            UIImage* rotatedImage = [image rotateToImageOrientation];
            cv::Mat matImage = [rotatedImage CVMat3];
            NSLog (@"matImage: %@",image);
            matImages.push_back(matImage);
        }
    }
    for (id time in exposures) {
             if ([time isKindOfClass: [NSNumber class]]) {
                 times.push_back([time floatValue]);
             }
         }
    NSLog (@"merging to HDR...");

    cv::Mat HDRMat = mergeToHDR(matImages, times);
    UIImage* result = [[UIImage alloc] initWithCVMat:HDRMat];

    return result;
}

+ (UIImage*) processStichWithArray:(NSArray*)imageArray
{
    if ([imageArray count]==0){
        NSLog (@"imageArray is empty");
        return 0;
        }

    float ratio = HIGHT_COMPRESS_RATIO;
    UIImage *image = [imageArray firstObject];
    if (image.size.height < 5000) {
        ratio = 0.5;
    }

    NSMutableArray* compressedImageArray =[NSMutableArray new];
    for(UIImage *rawImage in imageArray){
        UIImage *compressedImage=[self compressedToRatio:rawImage ratio:ratio];
        [compressedImageArray addObject:compressedImage];
    }


    std::vector<cv::Mat> matImages;

    for (id image in compressedImageArray) {
        if ([image isKindOfClass: [UIImage class]]) {
            /*
             All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
             */
            UIImage* rotatedImage = [image rotateToImageOrientation];
            cv::Mat matImage = [rotatedImage CVMat3];
            NSLog (@"matImage: %@",image);
            matImages.push_back(matImage);
        }
    }
    NSLog (@"stitching...");
    UIImage* result;
    cv::Mat stitchedMat = stitch (matImages);
    cv::Mat cropedMat;
    if (stitchedMat.rows == 0) {
        NSLog (@"Got error while stiching...");
        result =  [UIImage imageWithCVMat:stitchedMat];
        return result;
    } else {
        if([Cropping cropWithMat:stitchedMat andResult:cropedMat]){
            result =  [UIImage imageWithCVMat:cropedMat];
            return result;
        } else {
            result =  [UIImage imageWithCVMat:stitchedMat];
            return result;
        }
    }
}


//compress the photo width and height to COMPRESS_RATIO
+ (UIImage *)compressedToRatio:(UIImage *)img ratio:(float)ratio {
    CGSize compressedSize;
    compressedSize.width=img.size.width*ratio;
    compressedSize.height=img.size.height*ratio;
    UIGraphicsBeginImageContext(compressedSize);
    [img drawInRect:CGRectMake(0, 0, compressedSize.width, compressedSize.height)];
    UIImage* compressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return compressedImage;
}

@end
