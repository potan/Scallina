
(*
From the Coq Parametricity plugin:
https://github.com/coq-community/paramcoq/blob/v8.9/test-suite/ListQueue.v

Download the latest version of the Parametricity plugin for Coq v8.9 here:
https://github.com/coq-community/paramcoq/tree/v8.9


Changes to the original code required by Scallina's coding conventions:
- Add type information to all function parameters.
- Add function return types.
- Add parenthesis to enforce a given precedence where needed.
- Remove the type coercion from "t :> Type".
- Replace "cons" by "::".
- Inline all used-defined Coq notations.
- Implement the "loop" function: a non-depdently typed version of "nat_rect".
- Split the implementation and its proof into two distinct files.

Changes done to the original code not required by Scallina:
- Implement record attributes using anynomous functions.
Scallina only requires that record instance attributes be implemented
using the same signature with which they were defined in the Record.
- Inline all monadic operators on Option.
This was done for the readability of the source Coq code.
*)

Require Import List.
Require Import Nat.


Record Queue := {
  t : Type;
  empty : t;
  push : nat -> t -> t;
  pop : t -> option (nat * t)
}.


(*
This method pops two elements from the queue q and
then pushes their sum back into the queue.
*)
Definition sumElems(Q : Queue)(q: option Q.(t)) : option Q.(t) :=
match q with
| Some q1 =>
  match (Q.(pop) q1) with
  | Some (x, q2) =>
    match (Q.(pop) q2) with
    | Some (y, q3) => Some (Q.(push) (x + y) q3)
    | None => None
    end
  | None => None
  end
| None => None
end.

(*
A non-dependently typed version of nat_rect.
*)
Fixpoint loop {P : Type}
  (n : nat) (op : nat -> P -> P) (x : P) : P :=
  match n with
  | 0 => x
  | S n0 => op n0 (loop n0 op x)
  end.

(*
This programs creates a queue of n+1 consecutive numbers (from 0 to n)
and then returns the sum of all the elements of this queue.
*)
Definition program (Q : Queue) (n : nat) : option nat :=
(* q := 0::1::2::...::n *)
let q :=
  loop (S n) Q.(push) Q.(empty)
in
let q0 :=
  loop
  n
  (fun _ (q0: option Q.(t)) => sumElems Q q0)
  (Some q)
in
match q0 with
| Some q1 =>
  match (Q.(pop) q1) with
  | Some (x, q2) => Some x
  | None => None
  end
| None => None
end
.

Definition ListQueue : Queue := {|
  t := list nat;
  empty := nil;
  push := fun x l => x :: l;
  pop := fun l =>
    match rev l with
      | nil => None
      | hd :: tl => Some (hd, rev tl) end
|}.

Definition DListQueue : Queue := {|
  t := (list nat) * (list nat);
  empty := (nil, nil);
  push := fun x l =>
    let (back, front) := l in
    (x :: back,front);
  pop := fun l =>
    let (back, front) := l in
    match front with
      | nil =>
         match rev back with
            | nil => None
            | hd :: tl => Some (hd, (nil, tl))
         end
      | hd :: tl => Some (hd, (back, tl))
    end
|}.
