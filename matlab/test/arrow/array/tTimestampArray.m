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

classdef tTimestampArray < matlab.unittest.TestCase
% Tests for arrow.array.TimestampArray

    properties(TestParameter)
        TimeZone = {"" "America/New_York"}
        TimeUnit = {arrow.type.TimeUnit.Second arrow.type.TimeUnit.Millisecond
                    arrow.type.TimeUnit.Microsecond arrow.type.TimeUnit.Nanosecond}
    end

    methods(Test)
        function Basic(tc, TimeZone)
            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);
            arrowArray = arrow.array.TimestampArray(dates);
            className = string(class(arrowArray));
            tc.verifyEqual(className, "arrow.array.TimestampArray");
        end

        function TestLength(testCase, TimeZone)
        % Verify the Length property.
            import arrow.array.TimestampArray

            dates = datetime.empty(0, 1);
            dates.TimeZone = TimeZone;
            arrowArray = TimestampArray(dates);
            testCase.verifyEqual(arrowArray.Length, int64(0));

            dates = datetime(2023, 6, 22, TimeZone=TimeZone);
            arrowArray = TimestampArray(dates);
            testCase.verifyEqual(arrowArray.Length, int64(1));

            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);
            arrowArray = TimestampArray(dates);
            testCase.verifyEqual(arrowArray.Length, int64(5));
        end

        function TestDefaultTimestampType(testCase, TimeZone)
        % Verify the TimestampArray's units is Microsecond by default and
        % its TimeZone value is taken from the input datetime.
            import arrow.array.TimestampArray

            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);
            arrowArray = TimestampArray(dates);
            testCase.verifyTimestampType(arrowArray.Type, arrow.type.TimeUnit.Microsecond, TimeZone);
        end

        function TestSupplyTimeUnit(testCase, TimeZone)
        % Supply the TimeUnit name-value pair at construction.
            import arrow.array.TimestampArray

            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);

            arrowArray = TimestampArray(dates, TimeUnit="Second");
            testCase.verifyTimestampType(arrowArray.Type, arrow.type.TimeUnit.Second, TimeZone);

            arrowArray = TimestampArray(dates, TimeUnit="Millisecond");
            testCase.verifyTimestampType(arrowArray.Type, arrow.type.TimeUnit.Millisecond, TimeZone);

            arrowArray = TimestampArray(dates, TimeUnit="Microsecond");
            testCase.verifyTimestampType(arrowArray.Type, arrow.type.TimeUnit.Microsecond, TimeZone);

            arrowArray = TimestampArray(dates, TimeUnit="Nanosecond");
            testCase.verifyTimestampType(arrowArray.Type, arrow.type.TimeUnit.Nanosecond, TimeZone);
        end

        function TestToMATLAB(testCase, TimeUnit, TimeZone)
        % Verify toMATLAB() round-trips the original datetime array.
            import arrow.array.TimestampArray

            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);

            arrowArray = arrow.array.TimestampArray(dates, TimeUnit=TimeUnit);
            values = toMATLAB(arrowArray);
            testCase.verifyEqual(values, dates');
        end

        function TestDatetime(testCase, TimeUnit, TimeZone)
        % Verify datetime() round-trips the original datetime array.
            import arrow.array.TimestampArray

            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);
            arrowArray = arrow.array.TimestampArray(dates, TimeUnit=TimeUnit);
            values = datetime(arrowArray);
            testCase.verifyEqual(values, dates');
        end

        function TestValid(testCase, TimeZone)
        % Verify the Valid property returns the expected logical vector.
            import arrow.array.TimestampArray
            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);
            dates([2 4]) = NaT;
            arrowArray = arrow.array.TimestampArray(dates);
            testCase.verifyEqual(arrowArray.Valid, [true; false; true; false; true]);
            testCase.verifyEqual(toMATLAB(arrowArray), dates');
            testCase.verifyEqual(datetime(arrowArray), dates');
        end

        function TestInferNulls(testCase, TimeUnit, TimeZone)
            import arrow.array.TimestampArray

            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);
            dates([2 4]) = NaT;

            % Verify NaT is treated as a null value if InferNulls=true.
            expectedDates = dates';
            arrowArray = arrow.array.TimestampArray(dates, TimeUnit=TimeUnit, InferNulls=true);
            testCase.verifyEqual(arrowArray.Valid, [true; false; true; false; true]);
            testCase.verifyEqual(toMATLAB(arrowArray), expectedDates);

            % Verify NaT is not treated as a null value if InferNulls=false.
            % The NaT values are mapped to int64(0).
            arrowArray = arrow.array.TimestampArray(dates, TimeUnit=TimeUnit, InferNulls=false);
            testCase.verifyEqual(arrowArray.Valid, [true; true; true; true; true]);
            
            % If the TimestampArray is zoned, int64(0) may not correspond
            % to Jan-1-1970. getFillValue takes into account the TimeZone.
            fill = getFillValue(TimeZone);
            expectedDates([2 4]) = fill;
            testCase.verifyEqual(toMATLAB(arrowArray), expectedDates);
        end

        function TestValidNVPair(testCase, TimeUnit, TimeZone)
            import arrow.array.TimestampArray

            dates = datetime(2023, 6, 22, TimeZone=TimeZone) + days(0:4);
            dates([2 4]) = NaT;
            
            % Supply the Valid name-value pair as vector of indices.
            arrowArray = arrow.array.TimestampArray(dates, TimeUnit=TimeUnit, Valid=[1 2 5]);
            testCase.verifyEqual(arrowArray.Valid, [true; true; false; false; true]);
            expectedDates = dates';
            expectedDates(2) = getFillValue(TimeZone);
            expectedDates([3 4]) = NaT;
            testCase.verifyEqual(toMATLAB(arrowArray), expectedDates);

            % Supply the Valid name-value pair as a logical scalar.
            arrowArray = arrow.array.TimestampArray(dates, TimeUnit=TimeUnit, Valid=false);
            testCase.verifyEqual(arrowArray.Valid, [false; false; false; false; false]);
            expectedDates(:) = NaT;
            testCase.verifyEqual(toMATLAB(arrowArray), expectedDates);
        end

        function ErrorIfNonVector(testCase)
            import arrow.array.TimestampArray

            dates = datetime(2023, 6, 2) + days(0:11);
            dates = reshape(dates, 2, 6);
            fcn = @() TimestampArray(dates);
            testCase.verifyError(fcn, "MATLAB:expectedVector");

            dates = reshape(dates, 3, 2, 2);
            fcn = @() TimestampArray(dates);
            testCase.verifyError(fcn, "MATLAB:expectedVector");
        end

        function EmptyDatetimeVector(testCase)
            import arrow.array.TimestampArray

            dates = datetime.empty(0, 0);
            arrowArray = TimestampArray(dates);
            testCase.verifyEqual(arrowArray.Length, int64(0));
            testCase.verifyEqual(arrowArray.Valid, logical.empty(0, 1));
            testCase.verifyEqual(toMATLAB(arrowArray), datetime.empty(0, 1));
        end
    end

    methods 
        function verifyTimestampType(testCase, type, timeUnit, timeZone)
            testCase.verifyTrue(isa(type, "arrow.type.TimestampType"));
            testCase.verifyEqual(type.TimeUnit, timeUnit);
            testCase.verifyEqual(type.TimeZone, timeZone);
        end
    end
end

function fill = getFillValue(timezone)
    fill = datetime(1970, 1, 1, TimeZone=timezone);
    offset = tzoffset(fill);
    if ~isnan(offset)
        fill = fill + offset;
    end
end