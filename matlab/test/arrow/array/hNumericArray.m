% Licensed to the Apache Software Foundation (ASF) under one or more
% contributor license agreements.  See the NOTICE file distributed with
% this work for additional information regarding copyright ownership.
% The ASF licenses this file to you under the Apache License, Version
% 2.0 (the "License"); you may not use this file except in compliance
% with the License.  You may obtain a copy of the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
% implied.  See the License for the specific language governing
% permissions and limitations under the License.

classdef hNumericArray < matlab.unittest.TestCase
% Test class containing shared tests for numeric arrays.

    properties (Abstract)
        ArrowArrayClassName(1, 1) string
        ArrowArrayConstructor
        MatlabArrayFcn
        MatlabConversionFcn
        MaxValue (1, 1)
        MinValue (1, 1)
        NullSubstitutionValue(1, 1)
        ArrowType(1, 1)
    end

    methods(TestClassSetup)
        function verifyOnMatlabPath(tc)
        % Verify the arrow array class is on the MATLAB Search Path.
            tc.assertTrue(~isempty(which(tc.ArrowArrayClassName)), ...
                """" + tc.ArrowArrayClassName + """must be on the MATLAB path. " + ...
                "Use ""addpath"" to add folders to the MATLAB path.");
        end
    end

    methods(Test)
        function BasicTest(tc)
            A = tc.ArrowArrayConstructor(tc.MatlabArrayFcn([1 2 3]));
            className = string(class(A));
            tc.verifyEqual(className, tc.ArrowArrayClassName);
        end

        function ShallowCopyTest(tc)
        % NumericArrays stores a shallow copy of the array keep the
        % memory alive.
            A = tc.ArrowArrayConstructor(tc.MatlabArrayFcn([1, 2, 3]));
            tc.verifyEqual(A.MatlabArray, tc.MatlabArrayFcn([1, 2, 3]));
            tc.verifyEqual(toMATLAB(A), tc.MatlabArrayFcn([1 2 3]'));
        end

        function ToMATLAB(tc)
            % Create array from a scalar
            A1 = tc.ArrowArrayConstructor(tc.MatlabArrayFcn(100));
            data = toMATLAB(A1);
            tc.verifyEqual(data, tc.MatlabArrayFcn(100));

            % Create array from a vector
            A2 = tc.ArrowArrayConstructor(tc.MatlabArrayFcn([1 2 3]));
            data = toMATLAB(A2);
            tc.verifyEqual(data, tc.MatlabArrayFcn([1 2 3]'));

            % Create a Float64Array from an empty double vector
            A3 = tc.ArrowArrayConstructor(tc.MatlabArrayFcn([]));
            data = toMATLAB(A3);
            tc.verifyEqual(data, tc.MatlabArrayFcn(reshape([], 0, 1)));
        end

        function MatlabConversion(tc)
        % Tests the type-specific conversion methods, e.g. single for
        % arrow.array.Float32Array, double for array.array.Float64Array

            % Create array from a scalar
            A1 = tc.ArrowArrayConstructor(tc.MatlabArrayFcn(100));
            data = tc.MatlabConversionFcn(A1);
            tc.verifyEqual(data, tc.MatlabArrayFcn(100));

            % Create array from a vector
            A2 = tc.ArrowArrayConstructor(tc.MatlabArrayFcn([1 2 3]));
            data = tc.MatlabConversionFcn(A2);
            tc.verifyEqual(data, tc.MatlabArrayFcn([1 2 3]'));

            % Create an array from an empty vector
            A3 = tc.ArrowArrayConstructor(tc.MatlabArrayFcn([]));
            data = tc.MatlabConversionFcn(A3);
            tc.verifyEqual(data, tc.MatlabArrayFcn(reshape([], 0, 1)));
        end

        function MinValueTest(tc)
            A = tc.ArrowArrayConstructor(tc.MinValue);
            tc.verifyEqual(toMATLAB(A), tc.MinValue);
        end

        function MaxValueTest(tc)
            A1 = tc.ArrowArrayConstructor(tc.MaxValue);
            tc.verifyEqual(toMATLAB(A1), tc.MaxValue);
        end

        function ErrorIfComplex(tc)
            fcn = @() tc.ArrowArrayConstructor(tc.MatlabArrayFcn([10 + 1i, 4]));
            tc.verifyError(fcn, "MATLAB:expectedReal");
        end

        function ErrorIfNonVector(tc)
            data = tc.MatlabArrayFcn([1 2 3 4 5 6 7 8 9]);
            data = reshape(data, 3, 1, 3);
            fcn = @() tc.ArrowArrayConstructor(tc.MatlabArrayFcn(data));
            tc.verifyError(fcn, "MATLAB:expectedVector");
        end

        function ErrorIfEmptyArrayIsNotTwoDimensional(tc)
            data = tc.MatlabArrayFcn(reshape([], [1 0 0]));
            fcn = @() tc.ArrowArrayConstructor(data);
            tc.verifyError(fcn, "MATLAB:expected2D");
        end

        function LogicalValidNVPair(tc)
            % Verify the expected elements are treated as null when Valid
            % is provided as a logical array
            data = tc.MatlabArrayFcn([1 2 3 4]);
            arrowArray = tc.ArrowArrayConstructor(data, Valid=[false true true false]);
        
            expectedData = data';
            expectedData([1 4]) = tc.NullSubstitutionValue;
            tc.verifyEqual(tc.MatlabConversionFcn(arrowArray), expectedData);
            tc.verifyEqual(toMATLAB(arrowArray), expectedData);
            tc.verifyEqual(arrowArray.Valid, [false; true; true; false]);
        end

        function NumericValidNVPair(tc)
            % Verify the expected elements are treated as null when Valid
            % is provided as a array of indices
            data = tc.MatlabArrayFcn([1 2 3 4]);
            arrowArray = tc.ArrowArrayConstructor(data, Valid=[2 4]);
        
            expectedData = data';
            expectedData([1 3]) = tc.NullSubstitutionValue;
            tc.verifyEqual(tc.MatlabConversionFcn(arrowArray), expectedData);
            tc.verifyEqual(toMATLAB(arrowArray), expectedData);
            tc.verifyEqual(arrowArray.Valid, [false; true; false; true]);

            % Make sure the optimization where the valid-bitmap is stored
            % as a nullptr works as expected.
            expectedData = data';
            arrowArray = tc.ArrowArrayConstructor(data, Valid=[1, 2, 3, 4]);
            tc.verifyEqual(tc.MatlabConversionFcn(arrowArray), expectedData);
            tc.verifyEqual(toMATLAB(arrowArray), expectedData);
            tc.verifyEqual(arrowArray.Valid, [true; true; true; true]);
        end

        function TestArrowType(tc)
        % Verify the array has the expected arrow.type.Type object
            data = tc.MatlabArrayFcn([1 2 3 4]);
            arrowArray = tc.ArrowArrayConstructor(data);
            tc.verifyEqual(arrowArray.Type, tc.ArrowType);
        end
    end
end
