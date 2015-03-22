Require Import Coq.Lists.List.
Require Import Io.All.

Import ListNotations.
Import C.Notations.

Fixpoint map_seq {E : Effect.t} {A B : Type} (f : A -> C.t E B) (l : list A)
  : C.t E (list B) :=
  match l with
  | [] => ret []
  | x :: l =>
    let! y := f x in
    let! l := map_seq f l in
    ret (y :: l)
  end.

Fixpoint iter_seq {E : Effect.t} {A : Type} (f : A -> C.t E unit) (l : list A)
  : C.t E unit :=
  match l with
  | [] => ret tt
  | x :: l =>
    do! f x in
    iter_seq f l
  end.

Fixpoint iter_par {E : Effect.t} {A : Type} (f : A -> C.t E unit) (l : list A)
  : C.t E unit :=
  match l with
  | [] => ret tt
  | x :: l =>
    let! _ : unit * unit := join (f x) (iter_par f l) in
    ret tt
  end.

Module Spec.
  Fixpoint map_seq {E : Effect.t} {A B C : Type} {f : A -> C.t E B}
    (l : list C) (x : C -> A) (y : C -> B)
    (run_f : forall (v : C), Run.t (f (x v)) (y v)) {struct l}
    : Run.t (map_seq f (List.map x l)) (List.map y l).
    destruct l as [|v l].
    - apply Run.Ret.
    - apply (Run.Let (run_f v)).
      apply (Run.Let (map_seq _ _ _ _ _ l x y run_f)).
      apply Run.Ret.
  Defined.

  Definition map_seq_id {E : Effect.t} {A B : Type} {f : A -> C.t E B}
    (l : list B) (x : B -> A) (run_f : forall (v : B), Run.t (f (x v)) v)
    : Run.t (List.map_seq f (List.map x l)) l.
    rewrite <- List.map_id.
    now apply map_seq.
  Defined.
End Spec.
