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

import XCTest
import FlatBuffers
@testable import Arrow

@discardableResult
func checkBoolRecordBatch(_ result: Result<ArrowReader.ArrowReaderResult, ArrowError>) throws -> [RecordBatch] {
    let recordBatches: [RecordBatch]
    switch result {
    case .success(let result):
        recordBatches = result.batches
    case .failure(let error):
        throw error
    }
    
    XCTAssertEqual(recordBatches.count, 1)
    for recordBatch in recordBatches {
        XCTAssertEqual(recordBatch.length, 5)
        XCTAssertEqual(recordBatch.columns.count, 2)
        XCTAssertEqual(recordBatch.schema.fields.count, 2)
        XCTAssertEqual(recordBatch.schema.fields[0].name, "one")
        XCTAssertEqual(recordBatch.schema.fields[0].type.info, ArrowType.ArrowBool)
        XCTAssertEqual(recordBatch.schema.fields[1].name, "two")
        XCTAssertEqual(recordBatch.schema.fields[1].type.info, ArrowType.ArrowString)
        for index in 0..<recordBatch.length {
            let column = recordBatch.columns[0]
            let str = column.array as! AsString
            let val = "\(str.asString(index))"
            if index == 0 || index == 4 {
                XCTAssertEqual(val, "true")
            } else if index == 2 {
                XCTAssertEqual(val, "")
            } else {
                XCTAssertEqual(val, "false")
            }
        }
    }
    
    return recordBatches
}

func currentDirectory(path: String = #file) -> URL {
    return URL(fileURLWithPath: path).deletingLastPathComponent()
}

final class IPCFileReaderTests: XCTestCase {
    func testFileReader_double() throws {
        let fileURL = currentDirectory().appendingPathComponent("../../testdata_double.arrow")
        let arrowReader = ArrowReader()
        let result = arrowReader.fromFile(fileURL)
        let recordBatches: [RecordBatch]
        switch result {
        case .success(let result):
            recordBatches = result.batches
        case .failure(let error):
            throw error
        }
        XCTAssertEqual(recordBatches.count, 1)
        for recordBatch in recordBatches {
            XCTAssertEqual(recordBatch.length, 5)
            XCTAssertEqual(recordBatch.columns.count, 2)
            XCTAssertEqual(recordBatch.schema.fields.count, 2)
            XCTAssertEqual(recordBatch.schema.fields[0].name, "one")
            XCTAssertEqual(recordBatch.schema.fields[0].type.info, ArrowType.ArrowDouble)
            XCTAssertEqual(recordBatch.schema.fields[1].name, "two")
            XCTAssertEqual(recordBatch.schema.fields[1].type.info, ArrowType.ArrowString)
            for index in 0..<recordBatch.length {
                let column = recordBatch.columns[1]
                let str = column.array as! AsString
                let val = "\(str.asString(index))"
                if index != 1 {
                    XCTAssertNotEqual(val, "")
                } else {
                    XCTAssertEqual(val, "")
                }
            }
        }
    }
    
    func testFileReader_bool() throws {
        let fileURL = currentDirectory().appendingPathComponent("../../testdata_bool.arrow")
        let arrowReader = ArrowReader()
        try checkBoolRecordBatch(arrowReader.fromFile(fileURL))
    }

    func testFileWriter_bool() throws {
        //read existing file
        let fileURL = currentDirectory().appendingPathComponent("../../testdata_bool.arrow")
        let arrowReader = ArrowReader()
        let fileRBs = try checkBoolRecordBatch(arrowReader.fromFile(fileURL))
        let arrowWriter = ArrowWriter()
        //write data from file to a stream
        let writerInfo = ArrowWriter.Info(.recordbatch, schema: fileRBs[0].schema, batches: fileRBs)
        switch arrowWriter.toStream(writerInfo) {
        case .success(let writeData):
            //read stream back into recordbatches
            try checkBoolRecordBatch(arrowReader.fromStream(writeData))
        case .failure(let error):
            throw error
        }
        //write file record batches to another file
        let outputUrl = currentDirectory().appendingPathComponent("../../testfilewriter_bool.arrow")
        switch arrowWriter.toFile(outputUrl, info: writerInfo) {
        case .success(_):
            try checkBoolRecordBatch(arrowReader.fromFile(outputUrl))
        case .failure(let error):
            throw error
        }
    }
    func makeSchema() -> ArrowSchema {
        let schemaBuilder = ArrowSchema.Builder();
        return schemaBuilder.addField("col1", type: ArrowType(ArrowType.ArrowUInt8), isNullable: true)
            .addField("col2", type: ArrowType(ArrowType.ArrowString), isNullable: false)
            .addField("col3", type: ArrowType(ArrowType.ArrowDate32), isNullable: false)
            .finish()
    }
    func makeRecordBatch() throws -> RecordBatch {
        let uint8Builder: NumberArrayBuilder<UInt8> = try ArrowArrayBuilders.loadNumberArrayBuilder();
        uint8Builder.append(10)
        uint8Builder.append(22)
        uint8Builder.append(33)
        uint8Builder.append(44)
        let stringBuilder = try ArrowArrayBuilders.loadStringArrayBuilder();
        stringBuilder.append("test10")
        stringBuilder.append("test22")
        stringBuilder.append("test33")
        stringBuilder.append("test44")
        let date32Builder = try ArrowArrayBuilders.loadDate32ArrayBuilder();
        let date2 = Date(timeIntervalSinceReferenceDate: 86400 * 1)
        let date1 = Date(timeIntervalSinceReferenceDate: 86400 * 5000 + 352)
        date32Builder.append(date1)
        date32Builder.append(date2)
        date32Builder.append(date1)
        date32Builder.append(date2)
        let intHolder = ArrowArrayHolder(try uint8Builder.finish())
        let stringHolder = ArrowArrayHolder(try stringBuilder.finish())
        let date32Holder = ArrowArrayHolder(try date32Builder.finish())
        let result = RecordBatch.Builder()
            .addColumn("col1", arrowArray: intHolder)
            .addColumn("col2", arrowArray: stringHolder)
            .addColumn("col3", arrowArray: date32Holder)
            .finish()
        switch result {
        case .success(let recordBatch):
            return recordBatch
        case .failure(let error):
            throw error
        }
    }
    
    func testRBInMemoryToFromStream() throws {
        //read existing file
        let schema = makeSchema()
        let recordBatch = try makeRecordBatch()
        let arrowWriter = ArrowWriter()
        let writerInfo = ArrowWriter.Info(.recordbatch, schema: schema, batches: [recordBatch])
        switch arrowWriter.toStream(writerInfo) {
        case .success(let writeData):
            let arrowReader = ArrowReader()
            switch arrowReader.fromStream(writeData) {
            case .success(let result):
                let recordBatches = result.batches
                XCTAssertEqual(recordBatches.count, 1)
                for recordBatch in recordBatches {
                    XCTAssertEqual(recordBatch.length, 4)
                    XCTAssertEqual(recordBatch.columns.count, 3)
                    XCTAssertEqual(recordBatch.schema.fields.count, 3)
                    XCTAssertEqual(recordBatch.schema.fields[0].name, "col1")
                    XCTAssertEqual(recordBatch.schema.fields[0].type.info, ArrowType.ArrowUInt8)
                    XCTAssertEqual(recordBatch.schema.fields[1].name, "col2")
                    XCTAssertEqual(recordBatch.schema.fields[1].type.info, ArrowType.ArrowString)
                    XCTAssertEqual(recordBatch.schema.fields[2].name, "col3")
                    XCTAssertEqual(recordBatch.schema.fields[2].type.info, ArrowType.ArrowDate32)
                    let dateVal = "\((recordBatch.columns[2].array as! AsString).asString(0))"
                    XCTAssertEqual(dateVal, "2014-09-10 00:00:00 +0000")
                    let stringVal = "\((recordBatch.columns[1].array as! AsString).asString(1))"
                    XCTAssertEqual(stringVal, "test22")
                    let uintVal = "\((recordBatch.columns[0].array as! AsString).asString(0))"
                    XCTAssertEqual(uintVal, "10")
                    let stringVal2 = "\((recordBatch.columns[1].array as! AsString).asString(3))"
                    XCTAssertEqual(stringVal2, "test44")
                    let uintVal2 = "\((recordBatch.columns[0].array as! AsString).asString(3))"
                    XCTAssertEqual(uintVal2, "44")
                }
            case.failure(let error):
                throw error
            }
        case .failure(let error):
            throw error
        }
    }
    
    func testSchemaInMemoryToFromStream() throws {
        //read existing file
        let schema = makeSchema()
        let arrowWriter = ArrowWriter()
        let writerInfo = ArrowWriter.Info(.schema, schema: schema)
        switch arrowWriter.toStream(writerInfo) {
        case .success(let writeData):
            let arrowReader = ArrowReader()
            switch arrowReader.fromStream(writeData) {
            case .success(let result):
                XCTAssertNotNil(result.schema)
                let schema  = result.schema!
                XCTAssertEqual(schema.fields.count, 3)
                XCTAssertEqual(schema.fields[0].name, "col1")
                XCTAssertEqual(schema.fields[0].type.info, ArrowType.ArrowUInt8)
                XCTAssertEqual(schema.fields[1].name, "col2")
                XCTAssertEqual(schema.fields[1].type.info, ArrowType.ArrowString)
                XCTAssertEqual(schema.fields[2].name, "col3")
                XCTAssertEqual(schema.fields[2].type.info, ArrowType.ArrowDate32)
            case.failure(let error):
                throw error
            }
        case .failure(let error):
            throw error
        }
    }
    
    func makeBinaryDataset() throws -> (ArrowSchema, RecordBatch) {
        let schemaBuilder = ArrowSchema.Builder();
        let schema = schemaBuilder.addField("binary", type: ArrowType(ArrowType.ArrowBinary), isNullable: false)
            .finish()
        
        let binaryBuilder = try ArrowArrayBuilders.loadBinaryArrayBuilder();
        binaryBuilder.append("test10".data(using: .utf8))
        binaryBuilder.append("test22".data(using: .utf8))
        binaryBuilder.append("test33".data(using: .utf8))
        binaryBuilder.append("test44".data(using: .utf8))
        
        let binaryHolder = ArrowArrayHolder(try binaryBuilder.finish())
        let result = RecordBatch.Builder()
            .addColumn("binary", arrowArray: binaryHolder)
            .finish()
        switch result {
        case .success(let recordBatch):
            return (schema, recordBatch)
        case .failure(let error):
            throw error
        }
    }
    
    func makeTimeDataset() throws -> (ArrowSchema, RecordBatch) {
        let schemaBuilder = ArrowSchema.Builder();
        let schema = schemaBuilder.addField("time64", type: ArrowTypeTime64(.Microseconds), isNullable: false)
            .addField("time32", type: ArrowTypeTime32(.Milliseconds), isNullable: false)
            .finish()
        
        let time64Builder = try ArrowArrayBuilders.loadTime64ArrayBuilder(.Nanoseconds);
        time64Builder.append(12345678)
        time64Builder.append(1)
        time64Builder.append(nil)
        time64Builder.append(98765432)
        let time32Builder = try ArrowArrayBuilders.loadTime32ArrayBuilder(.Milliseconds);
        time32Builder.append(1)
        time32Builder.append(2)
        time32Builder.append(nil)
        time32Builder.append(3)
        
        let time64Holder = ArrowArrayHolder(try time64Builder.finish())
        let time32Holder = ArrowArrayHolder(try time32Builder.finish())
        let result = RecordBatch.Builder()
            .addColumn("time64", arrowArray: time64Holder)
            .addColumn("time32", arrowArray: time32Holder)
            .finish()
        switch result {
        case .success(let recordBatch):
            return (schema, recordBatch)
        case .failure(let error):
            throw error
        }
    }
    
    func testBinaryInMemroyToFromStream() throws {
        let dataset = try makeBinaryDataset();
        let writerInfo = ArrowWriter.Info(.recordbatch, schema: dataset.0, batches: [dataset.1])
        let arrowWriter = ArrowWriter()
        switch arrowWriter.toStream(writerInfo) {
        case .success(let writeData):
            let arrowReader = ArrowReader()
            switch arrowReader.fromStream(writeData) {
            case .success(let result):
                XCTAssertNotNil(result.schema)
                let schema  = result.schema!
                XCTAssertEqual(schema.fields.count, 1)
                XCTAssertEqual(schema.fields[0].name, "binary")
                XCTAssertEqual(schema.fields[0].type.info, ArrowType.ArrowBinary)
                XCTAssertEqual(result.batches.count, 1)
                let recordBatch = result.batches[0]
                XCTAssertEqual(recordBatch.length, 4)
                let stringVal = "\((recordBatch.columns[0].array as! AsString).asString(1))"
                XCTAssertEqual(stringVal, "test22")
            case.failure(let error):
                throw error
            }
        case .failure(let error):
            throw error
        }
    }
    
    func testTimeInMemroyToFromStream() throws {
        let dataset = try makeTimeDataset();
        let writerInfo = ArrowWriter.Info(.recordbatch, schema: dataset.0, batches: [dataset.1])
        let arrowWriter = ArrowWriter()
        switch arrowWriter.toStream(writerInfo) {
        case .success(let writeData):
            let arrowReader = ArrowReader()
            switch arrowReader.fromStream(writeData) {
            case .success(let result):
                XCTAssertNotNil(result.schema)
                let schema  = result.schema!
                XCTAssertEqual(schema.fields.count, 2)
                XCTAssertEqual(schema.fields[0].name, "time64")
                XCTAssertEqual(schema.fields[0].type.info, ArrowType.ArrowTime64)
                XCTAssertEqual(schema.fields[1].name, "time32")
                XCTAssertEqual(schema.fields[1].type.info, ArrowType.ArrowTime32)
                XCTAssertEqual(result.batches.count, 1)
                let recordBatch = result.batches[0]
                XCTAssertEqual(recordBatch.length, 4)
                let stringVal = "\((recordBatch.columns[0].array as! AsString).asString(0))"
                XCTAssertEqual(stringVal, "12345678")
                let stringVal2 = "\((recordBatch.columns[1].array as! AsString).asString(3))"
                XCTAssertEqual(stringVal2, "3")
            case.failure(let error):
                throw error
            }
        case .failure(let error):
            throw error
        }
    }
}
