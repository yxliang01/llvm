//==------- test_interop_get_native.cpp - SYCL CUDA get_native tests -------==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "gtest/gtest.h"

#include <CL/sycl.hpp>
#include <CL/sycl/backend/cuda.hpp>
#include <cuda.h>
#include <iostream>

using namespace cl::sycl;

struct DISABLED_CudaInteropGetNativeTests : public ::testing::Test {

protected:
  queue syclQueue_;
  context syclContext_;
  device syclDevice_;

  static bool isCudaDevice(const device &dev) {
    const platform platform = dev.get_info<info::device::platform>();
    const std::string platformVersion =
        platform.get_info<info::platform::version>();
    // If using PI_CUDA, don't accept a non-CUDA device
    return platformVersion.find("CUDA") != std::string::npos;
  }

  class cuda_device_selector : public device_selector {
  public:
    int operator()(const device &dev) const {
      return isCudaDevice(dev) ? 1 : -1;
    }
  };

  void SetUp() override {
    syclQueue_ = queue{cuda_device_selector()};
    context syclContext_ = syclQueue_.get_context();
    device syclDevice_ = syclQueue_.get_device();
    ASSERT_TRUE(isCudaDevice(syclDevice_));
  }

  void TearDown() override {}
};

TEST_F(DISABLED_CudaInteropGetNativeTests, getNativeDevice) {
  CUdevice cudaDevice = get_native<backend::cuda>(syclDevice_);
  char cudaDeviceName[2] = {0, 0};
  CUresult result = cuDeviceGetName(cudaDeviceName, 2, cudaDevice);
  ASSERT_EQ(result, CUDA_SUCCESS);
  ASSERT_NE(cudaDeviceName[0], 0);
}

TEST_F(DISABLED_CudaInteropGetNativeTests, getNativeContext) {
  CUcontext cudaContext = get_native<backend::cuda>(syclContext_);
  ASSERT_NE(cudaContext, nullptr);
}

TEST_F(DISABLED_CudaInteropGetNativeTests, getNativeQueue) {
  CUstream cudaStream = get_native<backend::cuda>(syclQueue_);
  ASSERT_NE(cudaStream, nullptr);

  CUcontext streamContext = nullptr;
  CUresult result = cuStreamGetCtx(cudaStream, &streamContext);
  ASSERT_EQ(result, CUDA_SUCCESS);

  CUcontext cudaContext = get_native<backend::cuda>(syclContext_);
  ASSERT_EQ(streamContext, cudaContext);
}

TEST_F(DISABLED_CudaInteropGetNativeTests, interopTaskGetMem) {
  buffer<int, 1> syclBuffer(range<1>{1});
  syclQueue_.submit([&](handler &cgh) {
    auto syclAccessor = syclBuffer.get_access<access::mode::read>(cgh);
    cgh.interop_task([=](interop_handler ih) {
      CUdeviceptr cudaPtr = ih.get_mem<backend::cuda>(syclAccessor);
      CUdeviceptr cudaPtrBase;
      size_t cudaPtrSize = 0;
      cuMemGetAddressRange(&cudaPtrBase, &cudaPtrSize, cudaPtr);
      ASSERT_EQ(cudaPtrSize, sizeof(int));
    });
  });
}

TEST_F(DISABLED_CudaInteropGetNativeTests, interopTaskGetBufferMem) {
  CUstream cudaStream = get_native<backend::cuda>(syclQueue_);
  syclQueue_.submit([&](handler &cgh) {
    cgh.interop_task([=](interop_handler ih) {
      CUstream cudaInteropStream = ih.get_queue<backend::cuda>();
      ASSERT_EQ(cudaInteropStream, cudaStream);
    });
  });
}
