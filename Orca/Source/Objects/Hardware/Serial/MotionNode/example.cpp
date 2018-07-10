/**
  @file    example.cpp
  @version 1.2

  (C) Copyright GLI Interactive LLC 2009. All rights reserved.

  UNPUBLISHED -- Rights reserved under the copyright laws of the United States.
  Use of a copyright notice is precautionary only and does not imply
  publication or disclosure.

  THE CONTENT OF THIS WORK CONTAINS CONFIDENTIAL AND PROPRIETARY INFORMATION OF
  GLI INTERACTIVE LLC. ANY DUPLICATION, MODIFICATION, DISTRIBUTION, OR
  DISCLOSURE IN ANY FORM, IN WHOLE, OR IN PART, IS STRICTLY PROHIBITED WITHOUT
  THE PRIOR EXPRESS WRITTEN PERMISSION OF GLI INTERACTIVE LLC.
*/
#include "MotionNodeAccelAPI.hh"
#include <iostream>


int run_example(int n)
{
  // Another option is to use dlopen/dlsym to load the
  // library and get an instance of the API class. 
  MotionNodeAccel * node = MotionNodeAccel::Factory();
  if (NULL != node) {

    // Detect the number of available devices.
    //unsigned count = 0;
    //node->get_num_device(count);

    // Set the G range. Default is 2.
    //node->set_gselect(2.0);

    // Maximum delay, sample at 50 Hz.
    //node->set_delay(1.0);
    // Minimum delay for compatibility with all
    // sensors. Sample at 100 Hz.
    //node->set_delay(0.375);


    // Connect to the first available device.
    if (node->connect()) {
      if (node->start()) {

        // Sampling loop. Read 100 times then stop.
        for (int i=0; i<n; i++) {
          float a[3] = {0, 0, 0};
          if (node->sample() && node->get_sensor(a)) {
            std::cout
              << "a = ["
              << a[0] << ", "
              << a[1] << ", "
              << a[2] << "] g"
              << std::endl;
          }
        }

        node->stop();
      } else {
        std::cerr << "Failed to start reading" << std::endl;
      }

      node->close();
    } else {
      std::cerr << "Failed to connect" << std::endl;
    }

    // Clean up.
    node->destroy();
    node = NULL;

  } else {
    std::cerr << "API version mismatch" << std::endl;
  }

  return 0;
}

/*
int main(int argc, char * argv[])
{
  // This includes blocking I/O. Likely requires a dedicated
  // thread.
  return run_example(10);
}
*/
