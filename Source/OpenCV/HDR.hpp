

#ifndef HDR_hpp
#define HDR_hpp

#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

cv::Mat mergeToHDR (vector<Mat>& images, vector<float>& times);
cv::Mat stitch (std::vector <cv::Mat> & images);

#endif /* HDR_hpp */
