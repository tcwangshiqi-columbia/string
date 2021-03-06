(***********************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team    *)
(* <O___,, *        INRIA-Rocquencourt  &  LRI-CNRS-Orsay              *)
(*   \VV/  *************************************************************)
(*    //   *      This file is distributed under the terms of the      *)
(*         *       GNU Lesser General Public License Version 2.1       *)
(***********************************************************************)

open Pp
open Util
open Names
open Pcoq
open Libnames
open Globnames
open Topconstr
open G_local_ascii_syntax
open Glob_term

exception Non_closed_string

(* make a string term from the string s *)

let string_module = ["String"; "String"]

let string_path = make_path string_module "string"

let string_kn = make_kn string_module "string"
let glob_string  = IndRef (string_kn,0)
let path_of_EmptyString  = ((string_kn,0),1)
let glob_EmptyString  = ConstructRef path_of_EmptyString
let path_of_String  = ((string_kn,0),2)
let glob_String  = ConstructRef path_of_String

let interp_string dloc s =
  let le = String.length s in
  let rec aux n =
     if n = le then GRef (dloc, glob_EmptyString,None) else
     GApp (dloc,GRef (dloc, glob_String,None),
       [interp_ascii dloc (int_of_char s.[n]); aux (n+1)])
  in aux 0

let uninterp_string r =
  try
    let b = Buffer.create 16 in
    let rec aux = function
    | GApp (_,GRef (_,k,_),[a;s]) when eq_gr k glob_String ->
	(match uninterp_ascii a with
	  | Some c -> Buffer.add_char b (Char.chr c); aux s
	  | _ -> raise Non_closed_string)
    | GRef (_,z,_) when eq_gr z glob_EmptyString ->
	Some (Buffer.contents b)
    | _ ->
	raise Non_closed_string
    in aux r
  with
   Non_closed_string -> None

let _ =
  Notation.declare_string_interpreter "local_string_scope"
    (string_path,["String"])
    interp_string
    ([GRef (Loc.ghost,glob_String,None); GRef (Loc.ghost,glob_EmptyString,None)],
     uninterp_string, true)
