
#include "HDR.hpp"

#include <opencv2/photo.hpp>
#include "opencv2/imgcodecs.hpp"
#include <opencv2/highgui.hpp>
#include <vector>
#include <iostream>
#include <fstream>
#include "opencv2/stitching.hpp"
#include <iostream>
#include <fstream>
using namespace cv;
using namespace std;

vector<Mat> imgs;
bool try_use_gpu = false;
string result_name = "result.jpg";
void printUsage();
int parseCmdArgs(int argc, char** argv);

cv::Mat mergeToHDR (vector<Mat>& images, vector<float>& times)
{
    imgs = images;
    
    Mat fusion;
    Ptr<MergeMertens> merge_mertens = createMergeMertens();
    merge_mertens->process(images, fusion);
    
    // fusion
    Mat fusion8bit;
    fusion = fusion * 255;
    fusion.convertTo(fusion8bit, CV_8U);
    return fusion8bit;
}

cv::Mat stitch (vector<Mat>& images)
{
    imgs = images;
    Mat pano;
    Stitcher stitcher = Stitcher::createDefault(try_use_gpu);
    Stitcher::Status status = stitcher.stitch(imgs, pano);
    
    if (status != Stitcher::OK)
        {
        cout << "Can't stitch images, error code = " << int(status) << endl;
            //return 0;
        }
    return pano;
}
