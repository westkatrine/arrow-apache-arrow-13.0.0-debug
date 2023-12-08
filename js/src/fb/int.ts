// automatically generated by the FlatBuffers compiler, do not modify

import * as flatbuffers from 'flatbuffers';

export class Int {
  bb: flatbuffers.ByteBuffer|null = null;
  bb_pos = 0;
  __init(i:number, bb:flatbuffers.ByteBuffer):Int {
  this.bb_pos = i;
  this.bb = bb;
  return this;
}

static getRootAsInt(bb:flatbuffers.ByteBuffer, obj?:Int):Int {
  return (obj || new Int()).__init(bb.readInt32(bb.position()) + bb.position(), bb);
}

static getSizePrefixedRootAsInt(bb:flatbuffers.ByteBuffer, obj?:Int):Int {
  bb.setPosition(bb.position() + flatbuffers.SIZE_PREFIX_LENGTH);
  return (obj || new Int()).__init(bb.readInt32(bb.position()) + bb.position(), bb);
}

bitWidth():number {
  const offset = this.bb!.__offset(this.bb_pos, 4);
  return offset ? this.bb!.readInt32(this.bb_pos + offset) : 0;
}

isSigned():boolean {
  const offset = this.bb!.__offset(this.bb_pos, 6);
  return offset ? !!this.bb!.readInt8(this.bb_pos + offset) : false;
}

static startInt(builder:flatbuffers.Builder) {
  builder.startObject(2);
}

static addBitWidth(builder:flatbuffers.Builder, bitWidth:number) {
  builder.addFieldInt32(0, bitWidth, 0);
}

static addIsSigned(builder:flatbuffers.Builder, isSigned:boolean) {
  builder.addFieldInt8(1, +isSigned, +false);
}

static endInt(builder:flatbuffers.Builder):flatbuffers.Offset {
  const offset = builder.endObject();
  return offset;
}

static createInt(builder:flatbuffers.Builder, bitWidth:number, isSigned:boolean):flatbuffers.Offset {
  Int.startInt(builder);
  Int.addBitWidth(builder, bitWidth);
  Int.addIsSigned(builder, isSigned);
  return Int.endInt(builder);
}
}
