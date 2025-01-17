import Ipld.Cid
import Ipld.Multihash
import Ipld.Utils
import Std.Data.RBTree

open Std (RBNode)

inductive Ipld where
  | null
  | bool (b : Bool)
  | number (n : UInt64)
  | string (s : String)
  | bytes (b : ByteArray)
  | array (elems : Array Ipld)
  | object (kvPairs : RBNode String (fun _ => Ipld))
  | link (cid: Cid)
  deriving BEq, Inhabited

partial def Ipld.toString : Ipld → String
  | .null     => "Ipld.null"
  | .bool   b => s!"(Ipld.bool {b})"
  | .number n => s!"(Ipld.number {n})"
  | .string s => s!"(Ipld.string {s})"
  | .bytes  b => s!"(Ipld.bytes {b})"
  | .link cid => s!"(Ipld.link {cid})"
  | .array as => s!"(Ipld.array {as.map toString})"
  | .object o =>
    let s := o.fold (init := []) fun acc s i => (s, toString i) :: acc
    s!"(Ipld.object {s.reverse})"

instance : ToString Ipld where
  toString := Ipld.toString

instance : Repr Ipld where
  reprPrec := fun i prec => Repr.addAppParen i.toString prec

def Ipld.mkObject (o : List (String × Ipld)) : Ipld :=
  object $ o.foldl (init := RBNode.leaf)
    fun acc (k, v) => acc.insert compare k v
