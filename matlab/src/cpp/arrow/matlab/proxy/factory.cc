// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

#include "arrow/matlab/array/proxy/boolean_array.h"
#include "arrow/matlab/array/proxy/numeric_array.h"
#include "arrow/matlab/array/proxy/string_array.h"
#include "arrow/matlab/array/proxy/timestamp_array.h"
#include "arrow/matlab/tabular/proxy/record_batch.h"
#include "arrow/matlab/error/error.h"

#include "factory.h"

namespace arrow::matlab::proxy {

libmexclass::proxy::MakeResult Factory::make_proxy(const ClassName& class_name, const FunctionArguments& constructor_arguments) {
    REGISTER_PROXY(arrow.array.proxy.Float32Array  , arrow::matlab::array::proxy::NumericArray<float>);
    REGISTER_PROXY(arrow.array.proxy.Float64Array  , arrow::matlab::array::proxy::NumericArray<double>);
    REGISTER_PROXY(arrow.array.proxy.UInt8Array    , arrow::matlab::array::proxy::NumericArray<uint8_t>);
    REGISTER_PROXY(arrow.array.proxy.UInt16Array   , arrow::matlab::array::proxy::NumericArray<uint16_t>);
    REGISTER_PROXY(arrow.array.proxy.UInt32Array   , arrow::matlab::array::proxy::NumericArray<uint32_t>);
    REGISTER_PROXY(arrow.array.proxy.UInt64Array   , arrow::matlab::array::proxy::NumericArray<uint64_t>);
    REGISTER_PROXY(arrow.array.proxy.Int8Array     , arrow::matlab::array::proxy::NumericArray<int8_t>);
    REGISTER_PROXY(arrow.array.proxy.Int16Array    , arrow::matlab::array::proxy::NumericArray<int16_t>);
    REGISTER_PROXY(arrow.array.proxy.Int32Array    , arrow::matlab::array::proxy::NumericArray<int32_t>);
    REGISTER_PROXY(arrow.array.proxy.Int64Array    , arrow::matlab::array::proxy::NumericArray<int64_t>);
    REGISTER_PROXY(arrow.array.proxy.BooleanArray  , arrow::matlab::array::proxy::BooleanArray);
    REGISTER_PROXY(arrow.array.proxy.StringArray   , arrow::matlab::array::proxy::StringArray);
    REGISTER_PROXY(arrow.array.proxy.TimestampArray, arrow::matlab::array::proxy::TimestampArray);
    REGISTER_PROXY(arrow.tabular.proxy.RecordBatch , arrow::matlab::tabular::proxy::RecordBatch);
    return libmexclass::error::Error{error::UNKNOWN_PROXY_ERROR_ID, "Did not find matching C++ proxy for " + class_name};
};

}
