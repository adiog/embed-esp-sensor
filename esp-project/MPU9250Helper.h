// This file is a part of embed-esp-sensor project.
// Copyright 2018 Aleksander Gajewski <adiog@brainfuck.pl>.

#ifndef MPU9250_HELPER_H
#define MPU9250_HELPER_H

// InternalSampleRate = 1000Hz
// SampleRate = InternalSampleRate / (1 + SampleRateDivider)


enum SampleRateDivider {
  SAMPLE_RATE_1000HZ,
  SAMPLE_RATE_500HZ,
  SAMPLE_RATE_333HZ,
  SAMPLE_RATE_250HZ,
  SAMPLE_RATE_200HZ,
  SAMPLE_RATE_166HZ,
  SAMPLE_RATE_142HZ,
  SAMPLE_RATE_125HZ,
  SAMPLE_RATE_111HZ,
  SAMPLE_RATE_100HZ,
  SAMPLE_RATE_90HZ,
  SAMPLE_RATE_83HZ,
  SAMPLE_RATE_76HZ,
  SAMPLE_RATE_71HZ,
  SAMPLE_RATE_66HZ,
  SAMPLE_RATE_62HZ,
  SAMPLE_RATE_58HZ,
  SAMPLE_RATE_55HZ,
  SAMPLE_RATE_52HZ,
  SAMPLE_RATE_50HZ
};

#endif
