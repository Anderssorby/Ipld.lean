-- TODO:
-- Fix errors
-- Add error handling
-- Add testing

import Ipld.Ipld
import Ipld.Cid
import Ipld.Utils
import Std.Data.RBTree

open Std (RBNode)

structure Serializer where
  bytes : ByteArray
     
def serialize (self : Serializer) (ipld : Ipld) : Serializer :=
  match ipld with
  | Ipld.null => serialize_null self
  | Ipld.bool b => serialize_bool self b
  | Ipld.number n => serialize_u64 self n
  | Ipld.string s => serialize_string self s
  | Ipld.byte b => serialize_bytes self b
  | Ipld.array a => serialize_array self a
  | Ipld.object o => serialize_object self o
  | Ipld.link cid => serialize_link self cid

def serialize_bool (self : Serializer) (bool : Bool) : Serializer :=
  match bool with
  | true => self.bytes.push 0xf5
  | false => self.bytes.push 0xf4

def serialize_u8 (self : Serializer) (major : UInt8) (n : UInt8) : Serializer :=
  if n <= 0x17
  then self.bytes.push ((major.toNat.shiftLeft 5).lor n.toNat).toUInt8
  else self.bytes.append { data := #[((major.toNat.shiftLeft 5).lor 24).toUInt8, n] }
  
def serialize_u16 (self : Serializer) (major : UInt8) (n : UInt16) : Serializer :=
  --if n <= UInt8.max
  if n <= 255
  then serialize_u8 self major n.toUInt8
  else
    let buf : ByteArray := { data := #[((major.toNat.shiftLeft 5).lor 25).toUInt8] }
    let bytes : ByteArray := Utils.toByteArrayBE n.toNat
    buf.append bytes
    self.bytes.append buf


def serialize_u32 (self : Serializer) (major: UInt8) (n : UInt32) : Serializer :=
  --if n <= UInt16.max
  if n <= 65535
  then serialize_u16 self major n.toUInt16
  else
    let buf := { data := #[((major.toNat.shiftLeft 5).lor 26).toUInt8] }
    let bytes := toByteArrayBE n.toNat
    buf.append bytes
    self.bytes.append buf

def serialize_u64 (self : Serializer) (major: UInt8) (n : UInt64) : Serializer :=
  --if n < UInt32.max
  if n <= 4294967295
  then serialize_u32 self major n.toUInt32
  else do
    let buf := { data := #[((major.toNat.shiftLeft 5).lor 27).toUInt8] }
    let bytes := toByteArrayBE n.toNat
    buf.append bytes
    self.bytes.append buf

def serialize_string (self : Serializer) (s: String) : Serializer := do
  serialize_u64 self 3 s.length.toUInt64
  self.bytes.append s.toUTF8

def serialize_bytes (self : Serializer) (b: ByteArray) : Serializer := do
  serialize_u64 self 2 b.length.toUInt64
  self.bytes.append b

def serialize_array (self : Serializer) (a: Array Ipld) : Serializer := do
  serialize_u64 self 4 a.length.toUInt64
  for i in a do
    serialize self i

def serialize_object (self : Serializer) (o: RBNode String (fun _ => Ipld)) : Serializer := do
  serialize_u64 self 5 o.size.toUInt64
  for i in o do
    serialize_string self i.0
    serialize self i.1
        
def serialize_link (self : Serializer) (l: link) : Serializer := do
  serialize_u64 self 6 42
  let cid := Cid.toBytes l
  serialize_bytes cid cid.length
 