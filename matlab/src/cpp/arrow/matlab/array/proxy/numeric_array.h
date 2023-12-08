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

#pragma once

#include "arrow/array.h"
#include "arrow/array/data.h"
#include "arrow/array/util.h"

#include "arrow/type_traits.h"

#include "arrow/matlab/array/proxy/array.h"
#include "arrow/matlab/error/error.h"
#include "arrow/matlab/bit/pack.h"
#include "arrow/matlab/bit/unpack.h"

#include "libmexclass/proxy/Proxy.h"

namespace arrow::matlab::array::proxy {

template<typename CType>
class NumericArray : public arrow::matlab::array::proxy::Array {
    public:
        NumericArray(const std::shared_ptr<arrow::Array> numeric_array)
            : arrow::matlab::array::proxy::Array() {
                array = numeric_array;
            }

        static libmexclass::proxy::MakeResult make(const libmexclass::proxy::FunctionArguments& constructor_arguments) {
            using ArrowType = typename arrow::CTypeTraits<CType>::ArrowType;
            using BuilderType = typename arrow::CTypeTraits<CType>::BuilderType;

            ::matlab::data::StructArray opts = constructor_arguments[0];

            // Get the mxArray from constructor arguments
            const ::matlab::data::TypedArray<CType> numeric_mda = opts[0]["MatlabArray"];
            const ::matlab::data::TypedArray<bool> valid_mda = opts[0]["Valid"];
            
            // Get raw pointer of mxArray
            auto it(numeric_mda.cbegin());
            auto dt = it.operator->();

            const auto data_type = arrow::CTypeTraits<CType>::type_singleton();
            const auto length = static_cast<int64_t>(numeric_mda.getNumberOfElements()); // cast size_t to int64_t

            // Do not make a copy when creating arrow::Buffer
            auto data_buffer = std::make_shared<arrow::Buffer>(reinterpret_cast<const uint8_t*>(dt),
                                                          sizeof(CType) * numeric_mda.getNumberOfElements());
            // Pack the validity bitmap values.
            MATLAB_ASSIGN_OR_ERROR(auto packed_validity_bitmap, bit::packValid(valid_mda), error::BITPACK_VALIDITY_BITMAP_ERROR_ID);
            auto array_data = arrow::ArrayData::Make(data_type, length, {packed_validity_bitmap, data_buffer});
            return std::make_shared<arrow::matlab::array::proxy::NumericArray<CType>>(arrow::MakeArray(array_data));
        }

    protected:
        void toMATLAB(libmexclass::proxy::method::Context& context) override {
            using ArrowArrayType = typename arrow::CTypeTraits<CType>::ArrayType;

            const auto num_elements = static_cast<size_t>(array->length());
            const auto numeric_array = std::static_pointer_cast<ArrowArrayType>(array);
            const CType* const data_begin = numeric_array->raw_values();
            const CType* const data_end = data_begin + num_elements;

            ::matlab::data::ArrayFactory factory;

            // Constructs a TypedArray from the raw values. Makes a copy.
            ::matlab::data::TypedArray<CType> result = factory.createArray({num_elements, 1}, data_begin, data_end);
            context.outputs[0] = result;
        }
};

}
