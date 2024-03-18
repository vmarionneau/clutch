(** * Exact time credit accounting for Coupon collecting *)
From clutch.ert_logic Require Export expected_time_credits ert_weakestpre problang_wp proofmode
  derived_laws.
From clutch.prob_lang Require Import notation tactics metatheory lang.
From iris.proofmode Require Export proofmode.
From Coq Require Export Reals Psatz.
From Coquelicot Require Export Hierarchy.
Require Import Lra.


Set Default Proof Using "Type*".

Section Coupon.
  Variables coupon':nat.
  Notation coupon:= (S coupon').

  Definition coupon_helper : expr :=
    rec: "coupon_helper" "a" "cnt" :=
      if: "cnt" = #0 then #() else
        let: "k" := rand (#coupon') in
        (if: ! ("a" +ₗ "k") 
        then "coupon_helper" "a" "cnt"
         else ("a" +ₗ "k") <- #true ;;
             "coupon_helper" "a" ("cnt"-#1)).

  Definition coupon_collection : expr :=
    λ: "x", 
      let: "a" := AllocN #coupon #false in
      coupon_helper "a" #coupon.
End Coupon.

Definition harmonic_sum:= sum_n_m (λ x, /INR x) 1.
Program Definition nnreal_harmonic_sum (n:nat) : nonnegreal := mknonnegreal (harmonic_sum n) _.
Next Obligation.
  intros.
  rewrite /harmonic_sum.
  induction n.
  - rewrite sum_n_m_zero; try done. lia.
  - rewrite sum_n_Sm; last lia.
    replace (plus _ _) with (sum_n_m (λ x, /INR x) 1 n + /(S n))by done.
    apply Rplus_le_le_0_compat; try done.
    rewrite -Rdiv_1_l. apply Rcomplements.Rdiv_le_0_compat; try lra.
    apply pos_INR_S.
Qed.

Lemma nnreal_harmonic_sum_S (n:nat): nnreal_harmonic_sum (S n) = (nnreal_harmonic_sum n + nnreal_inv (nnreal_nat $ S n))%NNR.
Proof.
  apply nnreal_ext. simpl.
  rewrite {1}/harmonic_sum. rewrite sum_n_Sm; last lia.
  apply Rplus_eq_compat_l. done.
Qed.
                          

Local Lemma coupon_etc_credit_split p coupon:
  (p≠0)%nat -> (coupon ≠ 0)%nat -> (p<coupon)%nat -> p/coupon + (coupon-p)/coupon * (1 + (coupon/p)) = (coupon/p).
Proof.
  intros H1 H2. 
  rewrite Rmult_plus_distr_l -Rplus_assoc Rmult_1_r.
  replace (_/_+_) with 1.
  - replace (_*_) with ((coupon-p)/p).
    + replace 1 with (p/p).
      * rewrite -Rdiv_plus_distr.
        by replace (_+_) with (INR coupon) by lra.
      * apply Rdiv_diag. replace 0 with (INR 0) by done. by move => /INR_eq.
    + rewrite Rmult_div_assoc -Rmult_div_swap -Rmult_div_assoc.
      rewrite Rdiv_diag; first lra.
      replace 0 with (INR 0) by done.
      by apply not_INR.
  - rewrite -Rdiv_plus_distr.
    replace (p+_) with (INR coupon) by lra.
    rewrite Rdiv_diag; first lra.
    replace 0 with (INR 0) by done.
    by apply not_INR.
Qed.

Section proofs.
  #[local] Definition cost1 {Λ} (e : language.expr Λ) := (nnreal_nat 1).
  #[local] Instance Cost1 {Λ} : Costfun Λ.
  Proof.
    unshelve econstructor.
    - exact cost1.
    - eexists nnreal_one ; by intuition auto.
    - auto.
  Defined.

  Context `{!ert_clutchGS Σ Cost1}.

  Notation tc_end:= (nnreal_nat 6).
  Notation tc_mid:=(nnreal_nat 999).
  Notation tc_start := (nnreal_nat 5).

  Local Lemma wp_coupon_helper_end (coupon':nat) (l:loc) E: 
    {{{ ⧖ (tc_end) }}} coupon_helper coupon' #l #(0) @ E {{{ RET #(); True}}}.
  Proof.
    iIntros (Φ) "Hx HΦ".
    wp_pures.
    iApply "HΦ".
    done.
  Qed.

  Local Lemma wp_coupon_helper_ind (coupon':nat) (l:loc) (lis:list val) (true_set: gset nat) (n:nat) E:
    (0<n<= S coupon')%nat ->
    (length lis = S coupon')%nat ->
    (size true_set = S coupon' - n)%nat ->
    (∀ n:nat, (n<S coupon')%nat -> lis !! n = Some (#true) <-> n∈true_set) -> 
    {{{ ⧖ (tc_end + tc_mid * nnreal_nat(n) * nnreal_harmonic_sum n)%NNR ∗
          l ↦∗ lis
    }}}
      coupon_helper coupon' #l #(n) @ E
      {{{RET #(); True}}}.
  Proof.
    iIntros (Hn Hlis Hset Hrel Φ) "[Hx Hl] HΦ".
    iLöb as "IH" forall (true_set n lis Hn Hlis Hset Hrel Φ) "Hx Hl HΦ".
    destruct n as [| n]; first lia.
    rewrite /coupon_helper.
  Admitted.

  Lemma wp_coupon_collection (coupon':nat) E:
    {{{ ⧖ (tc_start+tc_end + tc_mid * nnreal_nat(S coupon') * nnreal_harmonic_sum (S coupon'))%NNR }}}
      coupon_collection coupon' #()@E
      {{{RET #(); True}}}.
  Proof.
    iIntros (Φ) "Hx HΦ".
    rewrite /coupon_collection.
    rewrite -nnreal_plus_assoc (nnreal_plus_comm tc_start).
    iDestruct "Hx" as "[Hx1 Hx2]".
    wp_pures.
    iChip.
    wp_apply (wp_allocN with "[$]"); first (lia).
    iIntros (l) "Hl".
    wp_pure. iChip. wp_pure.
    rewrite -/(coupon_helper _).
    wp_apply (wp_coupon_helper_ind with "[$Hx1 $Hl]"); try done.
    - lia.
    - rewrite replicate_length. by rewrite Nat2Z.id. 
    - replace (_-_)%nat with 0%nat by lia. instantiate (1:= ∅).
      done.
    - intros. split; last set_solver.
      move => /lookup_replicate [??]. done.
  Qed.
  
End proofs.
