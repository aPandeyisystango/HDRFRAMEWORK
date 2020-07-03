#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (UIImage*)processHDRWithImageArray:(NSArray*)images andExposures:(NSArray*)exposures;
+ (UIImage*) processStichWithArray:(NSArray*)imageArray;
@end
