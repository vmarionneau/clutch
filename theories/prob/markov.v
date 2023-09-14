From Coq Require Import Reals Psatz.
From Coquelicot Require Import Rcomplements Rbar Lim_seq.
From clutch.prob Require Import distribution couplings.

Section markov_mixin.
  Context `{Countable mstate, Countable mstate_ret}.
  Context (step : mstate → distr mstate).
  Context (to_final : mstate → option mstate_ret).

  Record MarkovMixin := {
    mixin_to_final_is_final a :
      is_Some (to_final a) → ∀ a', step a a' = 0;
  }.
End markov_mixin.

Structure markov := Markov {
  mstate : Type;
  mstate_ret : Type;

  mstate_eqdec : EqDecision mstate;
  mstate_count : Countable mstate;
  mstate_ret_eqdec : EqDecision mstate_ret;                     
  mstate_ret_count : Countable mstate_ret;
                     
  step     : mstate → distr mstate;
  to_final : mstate → option mstate_ret;

  markov_mixin : MarkovMixin step to_final;                       
}.
#[global] Arguments Markov {_ _ _ _ _ _} _ _ _.
#[global] Arguments step {_}.
#[global] Arguments to_final {_}.

#[global] Existing Instance mstate_eqdec.
#[global] Existing Instance mstate_count.
#[global] Existing Instance mstate_ret_eqdec.
#[global] Existing Instance mstate_ret_count.

Section is_final.
  Context {δ : markov}.
  Implicit Types a : mstate δ.
  Implicit Types b : mstate_ret δ.

  Lemma to_final_is_final a :
    is_Some (to_final a) → ∀ a', step a a' = 0.
  Proof. apply markov_mixin. Qed. 

  Definition is_final a := is_Some (to_final a).

  Lemma to_final_None a : ¬ is_final a ↔ to_final a = None.
  Proof. rewrite eq_None_not_Some //. Qed.

  Lemma to_final_None_1 a : ¬ is_final a → to_final a = None.
  Proof. apply to_final_None. Qed.

  Lemma to_final_None_2 a : to_final a = None → ¬ is_final a.
  Proof. apply to_final_None. Qed.

  Lemma to_final_Some a : is_final a ↔ ∃ b, to_final a = Some b.
  Proof. done. Qed.

  Lemma to_final_Some_1 a : is_final a → ∃ b, to_final a = Some b.
  Proof. done. Qed.

  Lemma to_final_Some_2 a b : to_final a = Some b → is_final a.
  Proof. intros. by eexists. Qed.

  Lemma is_final_dzero a : is_final a → step a = dzero.
  Proof.
    intros Hf.
    apply distr_ext=> a'.
    rewrite to_final_is_final //.
  Qed.

End is_final.

#[global] Hint Immediate to_final_Some_2 to_final_None_2 to_final_None_1: core.

Section markov.
  Context {δ : markov}. 
  Implicit Types a : mstate δ.
  Implicit Types b : mstate_ret δ.

  (** Strict partial evaluation  *)
  Definition stepN (n : nat) a : distr (mstate δ) := iterM n step a.

  Lemma stepN_O a :
    stepN 0 a = dret a.
  Proof. done. Qed.

  Lemma stepN_Sn a n :
    stepN (S n) a = step a ≫= stepN n.
  Proof. done. Qed.

  Lemma stepN_plus a (n m : nat) :
    stepN (n + m) a = stepN n a ≫= stepN m.
  Proof. apply iterM_plus. Qed.

  Lemma stepN_Sn_inv n a0 a2 :
    stepN (S n) a0 a2 > 0 →
    ∃ a1, step a0 a1 > 0 ∧ stepN n a1 a2 > 0.
  Proof. intros (?&?&?)%dbind_pos. eauto. Qed.

  Lemma stepN_det_steps n m a1 a2 :
    stepN n a1 a2 = 1 →
    stepN n a1 ≫= stepN m = stepN m a2.
  Proof. intros ->%pmf_1_eq_dret. rewrite dret_id_left //. Qed.

  Lemma stepN_det_trans n m a1 a2 a3 :
    stepN n a1 a2 = 1 →
    stepN m a2 a3 = 1 →
    stepN (n + m) a1 a3 = 1.
  Proof.
    rewrite stepN_plus.
    intros ->%pmf_1_eq_dret.
    replace (dret a2 ≫= _)
      with (stepN m a2); [|by rewrite dret_id_left].
    intros ->%pmf_1_eq_dret.
    by apply dret_1.
  Qed.

  (** Non-strict partial evaluation *)
  Definition step_or_final a : distr (mstate δ) :=
    match to_final a with
    | Some _ => dret a
    | None => step a
    end.

  Lemma step_or_final_no_final a :
    ¬ is_final a → step_or_final a = step a.
  Proof. rewrite /step_or_final /is_final /= -eq_None_not_Some. by intros ->. Qed.

  Lemma step_or_final_is_final a :
    is_final a → step_or_final a = dret a.
  Proof. rewrite /step_or_final /=. by intros [? ->]. Qed.

  Definition pexec (n : nat) a : distr (mstate δ) := iterM n step_or_final a.

  Lemma pexec_O a :
    pexec 0 a = dret a.
  Proof. done. Qed.

  Lemma pexec_Sn a n :
    pexec (S n) a = step_or_final a ≫= pexec n.
  Proof. done. Qed.

  Lemma pexec_plus ρ n m :
    pexec (n + m) ρ = pexec n ρ ≫= pexec m.
  Proof. rewrite /pexec iterM_plus //.  Qed.

  Lemma pexec_1 :
    pexec 1 = step_or_final.
  Proof.
    extensionality a.
    rewrite pexec_Sn /pexec /= dret_id_right //.
  Qed.

  Lemma pexec_Sn_r a n :
    pexec (S n) a = pexec n a ≫= step_or_final.
  Proof.
    assert (S n = n + 1)%nat as -> by lia.
    rewrite pexec_plus pexec_1 //.
  Qed.

  Lemma pexec_is_final n a :
    is_final a → pexec n a = dret a.
  Proof.
    intros ?.
    induction n.
    - rewrite pexec_O //.
    - rewrite pexec_Sn step_or_final_is_final //.
      rewrite dret_id_left -IHn //.
  Qed.

  Lemma pexec_no_final a n :
    ¬ is_final a →
    pexec (S n) a = step a ≫= pexec n.
  Proof. intros. rewrite pexec_Sn step_or_final_no_final //. Qed.

  Lemma pexec_det_step n a1 a2 a0 :
    step a1 a2 = 1 →
    pexec n a0 a1 = 1 →
    pexec (S n) a0 a2 = 1.
  Proof.
    rewrite pexec_Sn_r.
    intros Hs ->%pmf_1_eq_dret.
    rewrite dret_id_left /=.
    case_match; [|done].
    assert (step a1 a2 = 0) as Hns; [by eapply to_final_is_final|].
    lra.
  Qed.

  Lemma pexec_det_steps n m a1 a2 :
    pexec n a1 a2 = 1 →
    pexec n a1 ≫= pexec m = pexec m a2.
  Proof. intros ->%pmf_1_eq_dret. rewrite dret_id_left //. Qed.
  
  (** Stratified evaluation to a final state *)
  Fixpoint exec (n : nat) (a : mstate δ) {struct n} : distr (mstate_ret δ) :=
    match to_final a, n with
      | Some b, _ => dret b
      | None, 0 => dzero
      | None, S n => step a ≫= exec n
    end.

  Lemma exec_unfold (n : nat) :
    exec n = λ a,
      match to_final a, n with
      | Some b, _ => dret b
      | None, 0 => dzero
      | None, S n => step a ≫= exec n
      end.
  Proof. by destruct n. Qed.

  Lemma exec_is_final a b n :
    to_final a = Some b → exec n a = dret b.
  Proof. destruct n; simpl; by intros ->. Qed.

  Lemma exec_Sn a n :
    exec (S n) a = step_or_final a ≫= exec n.
  Proof.
    rewrite /step_or_final /=.
    case_match; [|done].
    rewrite dret_id_left -/exec.
    by erewrite exec_is_final.
  Qed.

  Lemma exec_mono a n v :
    exec n a v <= exec (S n) a v.
  Proof.
    apply refRcoupl_eq_elim.
    move : a.
    induction n.
    - intros.
      apply refRcoupl_from_leq.
      intros b. rewrite /distr_le /=.
      by case_match.
    - intros; do 2 rewrite exec_Sn.
      eapply refRcoupl_dbind; [|apply refRcoupl_eq_refl].
      by intros ? ? ->.
  Qed.

  Lemma exec_mono' ρ n m v :
    n ≤ m → exec n ρ v <= exec m ρ v.
  Proof.
    eapply (mon_succ_to_mon (λ x, exec x ρ v)).
    intro. apply exec_mono.
  Qed.

  Lemma exec_mono_term a b n m :
    SeriesC (exec n a) = 1 →
    n ≤ m →
    exec m a b = exec n a b.
  Proof.
    intros Hv Hleq.
    apply Rle_antisym; [ |by apply exec_mono'].
    destruct (decide (exec m a b <= exec n a b))
      as [|?%Rnot_le_lt]; [done|].
    exfalso.
    assert (1 < SeriesC (exec m a)); last first.
    - assert (SeriesC (exec m a) <= 1); [done|]. lra.
    - rewrite -Hv.
      apply SeriesC_lt; eauto.
      intros b'. by split; [|apply exec_mono'].
  Qed.

  Lemma exec_O_not_final a :
    ¬ is_final a →
    exec 0 a = dzero.
  Proof. intros ?%to_final_None_1 =>/=; by case_match. Qed.

  Lemma exec_Sn_not_final a n :
    ¬ is_final a →
    exec (S n) a = step a ≫= exec n.
  Proof. intros ?. rewrite exec_Sn step_or_final_no_final //. Qed.

  Lemma pexec_exec_le_final n a a' b :
    to_final a' = Some b →
    pexec n a a' <= exec n a b.
  Proof.
    intros Hb.
    revert a. induction n; intros a.
    - rewrite pexec_O.
      destruct (decide (a = a')) as [->|].
      + erewrite exec_is_final; [|done].
        rewrite !dret_1_1 //.
      + rewrite dret_0 //.
    - rewrite exec_Sn pexec_Sn.
      destruct (decide (is_final a)).
      + rewrite step_or_final_is_final //.
        rewrite 2!dret_id_left -/exec.
        apply IHn.
      + rewrite step_or_final_no_final //.
        rewrite /pmf /= /dbind_pmf.
        eapply SeriesC_le.
        * intros a''. split; [by apply Rmult_le_pos|].
          by apply Rmult_le_compat.
        * eapply pmf_ex_seriesC_mult_fn.
          exists 1. by intros ρ.
  Qed.

  Lemma pexec_exec_det n a a' b :
    to_final a' = Some b →
    pexec n a a' = 1 → exec n a b = 1.
  Proof.
    intros Hf.
    pose proof (pexec_exec_le_final n a a' b Hf).
    pose proof (pmf_le_1 (exec n a) b).
    lra.
  Qed.

  Lemma exec_pexec_val_neq_le n m a a' b b' :
    to_final a' = Some b' →
    b ≠ b' → exec m a b + pexec n a a' <= 1.
  Proof.
    intros Hf Hneq.
    etrans; [by apply Rplus_le_compat_l, pexec_exec_le_final|].
    etrans; [apply Rplus_le_compat_l, (exec_mono' _ n (n `max` m)), Nat.le_max_l|].
    etrans; [apply Rplus_le_compat_r, (exec_mono' _ m (n `max` m)), Nat.le_max_r|].
    etrans; [|apply (pmf_SeriesC (exec (n `max` m) a))].
    by apply pmf_plus_neq_SeriesC.
  Qed.

  Lemma pexec_exec_det_neg n m a a' b b' :
    to_final a' = Some b' →
    pexec n a a' = 1 →
    b ≠ b' →
    exec m a b = 0.
  Proof.
    intros Hf Hexec Hv.
    pose proof (exec_pexec_val_neq_le n m a a' b b' Hf Hv) as Hle.
    rewrite Hexec in Hle.
    pose proof (pmf_pos (exec m a) b).
    lra.
  Qed.

  Lemma is_finite_Sup_seq_exec a b :
    is_finite (Sup_seq (λ n, exec n a b)).
  Proof.
    apply (Rbar_le_sandwich 0 1).
    - by apply (Sup_seq_minor_le _ _ 0%nat)=>/=.
    - by apply upper_bound_ge_sup=>/=.
  Qed.

  Lemma is_finite_Sup_seq_SeriesC_exec a :
    is_finite (Sup_seq (λ n, SeriesC (exec n a))).
  Proof.
    apply (Rbar_le_sandwich 0 1).
    - by apply (Sup_seq_minor_le _ _ 0%nat)=>/=.
    - by apply upper_bound_ge_sup=>/=.
  Qed.

  (** Full evaluation (limit of stratification) *)
  Definition lim_exec (a : mstate δ) : distr (mstate_ret δ) := lim_distr (λ n, exec n a) (exec_mono a).

  Lemma lim_exec_unfold a b :
    lim_exec a b = Sup_seq (λ n, (exec n a) b).
  Proof. apply lim_distr_pmf. Qed.

  Lemma lim_exec_step a :
    lim_exec a = step_or_final a ≫= lim_exec.
  Proof.
   apply distr_ext.
   intro b.
   rewrite {2}/pmf /= /dbind_pmf.
   rewrite lim_exec_unfold.
   setoid_rewrite lim_exec_unfold.
   assert
     (SeriesC (λ a', step_or_final a a' * Sup_seq (λ n, exec n a' b)) =
      SeriesC (λ a', Sup_seq (λ n, step_or_final a a' * exec n a' b))) as ->.
   { apply SeriesC_ext; intro b'.
     apply eq_rbar_finite.
     rewrite rmult_finite.
     rewrite (rbar_finite_real_eq).
     - rewrite -Sup_seq_scal_l //.
     - apply (Rbar_le_sandwich 0 1).
       + by apply (Sup_seq_minor_le _ _ 0%nat)=>/=.
       + by apply upper_bound_ge_sup=>/=. }
   rewrite (MCT_seriesC _ (λ n, exec (S n) a b) (lim_exec a b)) //.
   - intros. by apply Rmult_le_pos.
   - intros.
     apply Rmult_le_compat; [done|done|done|].
     apply exec_mono.
   - intros a'.
     exists (step_or_final a a').
     intros n.
     rewrite <- Rmult_1_r. by apply Rmult_le_compat_l.
   - intro n.
     rewrite exec_Sn.
     rewrite {3}/pmf/=/dbind_pmf.
     apply SeriesC_correct.
     apply (ex_seriesC_le _ (step_or_final a)); [|done].
     intros a'. split.
     + by apply Rmult_le_pos.
     + rewrite <- Rmult_1_r. by apply Rmult_le_compat_l.
   - rewrite lim_exec_unfold.
     rewrite mon_sup_succ.
     + rewrite (Rbar_le_sandwich 0 1).
       * apply Sup_seq_correct.
       * by apply (Sup_seq_minor_le _ _ 0%nat)=>/=.
       * by apply upper_bound_ge_sup=>/=.
     + intro; apply exec_mono.
  Qed.

  Lemma lim_exec_pexec n a :
    lim_exec a = pexec n a ≫= lim_exec.
  Proof.
    move : a.
    induction n; intro a.
    - rewrite pexec_O dret_id_left //.
    - rewrite pexec_Sn -dbind_assoc/=.
      rewrite lim_exec_step.
      apply dbind_eq; [|done].
      intros ??. apply IHn.
  Qed.

  Lemma lim_exec_det_final n a a' b :
    to_final a' = Some b →
    pexec n a a' = 1 →
    lim_exec a = dret b.
  Proof.
    intros Hb Hpe.
    apply distr_ext.
    intro b'.
    rewrite lim_exec_unfold.
    rewrite {2}/pmf /= /dret_pmf.
    case_bool_decide; simplify_eq.
    - apply Rle_antisym.
      + apply finite_rbar_le; [eapply is_finite_Sup_seq_exec|].
        by apply upper_bound_ge_sup=>/=.
      + apply rbar_le_finite; [eapply is_finite_Sup_seq_exec|].
        apply (Sup_seq_minor_le _ _ n)=>/=.
        by erewrite pexec_exec_det.
    - rewrite -(sup_seq_const 0).
      f_equal. apply Sup_seq_ext=> m.
      f_equal. by eapply pexec_exec_det_neg.
  Qed.

  Lemma lim_exec_final a b :
    to_final a = Some b →
    lim_exec a = dret b.
  Proof.
    intros. erewrite (lim_exec_det_final 0%nat); [done|done|].
    rewrite pexec_O. by apply dret_1_1.
  Qed.

  Lemma lim_exec_leq a b (r : R) :
    (∀ n, exec n a b <= r) →
    lim_exec a b <= r.
  Proof.
    intro Hexec.
    rewrite lim_exec_unfold.
    apply finite_rbar_le; [apply is_finite_Sup_seq_exec|].
    by apply upper_bound_ge_sup=>/=.
  Qed.

  Lemma lim_exec_leq_mass  a r :
    (∀ n, SeriesC (exec n a) <= r) →
    SeriesC (lim_exec a) <= r.
  Proof.
    intro Hm.
    erewrite SeriesC_ext; last first.
    { intros. rewrite lim_exec_unfold //. }
    erewrite (MCT_seriesC _ (λ n, SeriesC (exec n a)) (Sup_seq (λ n, SeriesC (exec n a)))); eauto.
    - apply finite_rbar_le; [apply is_finite_Sup_seq_SeriesC_exec|].
      by apply upper_bound_ge_sup.
    - apply exec_mono.
    - intros. by apply SeriesC_correct.
    - rewrite (Rbar_le_sandwich 0 1).
      + apply (Sup_seq_correct (λ n, SeriesC (exec n a))).
      + by apply (Sup_seq_minor_le _ _ 0%nat)=>/=.
      + by apply upper_bound_ge_sup=>/=.
  Qed.

  Lemma lim_exec_term n a :
    SeriesC (exec n a) = 1 →
    lim_exec a = exec n a.
  Proof.
    intro Hv.
    apply distr_ext=> b.
    rewrite lim_exec_unfold.
    apply Rle_antisym.
    - apply finite_rbar_le; [apply is_finite_Sup_seq_exec|].
      rewrite -/pmf.
      apply upper_bound_ge_sup.
      intros n'.
      destruct (decide (n <= n')) as [|?%Rnot_le_lt].
      + right. apply exec_mono_term; [done|]. by apply INR_le.
      + apply exec_mono'. apply INR_le. by left.
    - apply rbar_le_finite; [apply is_finite_Sup_seq_exec|].
      apply (sup_is_upper_bound (λ m, exec m a b) n).
  Qed.

End markov.




Structure rsm {δ : markov} := Rsm {
  rsm_fun :>  (mstate δ) -> R;
  rsm_eps : R;
  rsm_nneg : forall a, 0 <= rsm_fun a;
  eps_pos : 0 < rsm_eps;
  step_total :  forall a : mstate δ, SeriesC (step a) = 1;
  rsm_term : forall a, rsm_fun a = 0 -> is_final a;
  rsm_int : forall a, ¬ is_final a -> ex_expval (step a) rsm_fun;
  rsm_dec : forall a, ¬ is_final a -> Expval (step a) rsm_fun + rsm_eps <= rsm_fun a;
  }.


Section martingales.

  Context {δ : markov}.
  Context {h : @rsm δ}.

  Local Lemma pexec_mass : forall n (a : mstate δ), SeriesC (pexec n a) = 1.
  Proof using h δ.
    induction n.
    - intro a; rewrite pexec_O.
      apply dret_mass.
    - intro a.
      destruct (decide (is_final a)) as [Hf | Hnf].
      + rewrite pexec_is_final; auto.
        apply dret_mass.
      + rewrite pexec_no_final; auto.
        rewrite /pmf/=/dbind_pmf/=.
        rewrite distr_double_swap.
        setoid_rewrite SeriesC_scal_l.
        setoid_rewrite IHn.
        setoid_rewrite Rmult_1_r.
        apply (step_total h).
  Qed.

  Local Lemma ex_expval_step_distr (μ : distr (mstate δ)) :
    ex_expval μ h -> ex_expval (dbind (λ a, step_or_final a) μ) h.
  Proof.
    intros Hex.
    rewrite /ex_expval.
    rewrite /ex_expval in Hex.
    setoid_rewrite <- SeriesC_scal_r.
    apply (fubini_pos_seriesC_ex_double (λ '(x, a), μ x * step_or_final x a * h a)).
    - intros a' b'.
      specialize (rsm_nneg h b'); real_solver.
    - intros.
      setoid_rewrite Rmult_assoc. apply ex_seriesC_scal_l.
      destruct (decide (is_final a)) as [Hf | Hnf].
      * rewrite (step_or_final_is_final); auto.
        apply (ex_expval_dret h a).
      * rewrite (step_or_final_no_final); auto.
        apply (rsm_int); auto.
    - setoid_rewrite Rmult_assoc.
      setoid_rewrite SeriesC_scal_l.
      eapply ex_seriesC_le ; [ | apply Hex ].
      intros a; split.
      + apply Rmult_le_pos; auto.
        apply SeriesC_ge_0'; intro x;
        specialize (rsm_nneg h x); real_solver.
      + apply Rmult_le_compat_l; auto.
        destruct (decide (is_final a)) as [Hf | Hnf].
        * rewrite (step_or_final_is_final); auto.
          rewrite -(Expval_dret h a) /Expval //.
        * rewrite (step_or_final_no_final); auto.
          etrans; [ | apply (rsm_dec h a Hnf) ].
          pose proof (eps_pos h).
          rewrite /Expval; lra.
  Qed.

  Local Lemma Expval_step_dec (μ : distr (mstate δ)) :
      ex_expval μ h ->
        Expval (dbind (λ a, step_or_final a) μ) h <= Expval μ h.
  Proof.
    intros Hex.
    rewrite Expval_dbind.
    - apply SeriesC_le; auto.
      intro a; split.
      + apply Rmult_le_pos; auto.
        apply SeriesC_ge_0'.
        intro x; specialize (rsm_nneg h x); real_solver.
      + apply Rmult_le_compat_l; auto.
        destruct (decide (is_final a)) as [Hf | Hnf].
        * rewrite step_or_final_is_final; auto.
          rewrite Expval_dret; lra.
        * rewrite step_or_final_no_final; auto.
          etrans; [ | apply (rsm_dec h a Hnf) ].
          pose proof (eps_pos h).
          rewrite /Expval; lra.
    - intro b; apply rsm_nneg.
    - apply ex_expval_step_distr; auto.
  Qed.

  Local Lemma ex_expval_pexec : forall n a, ex_expval (pexec n a) h.
  Proof.
    induction n; intro a.
    - rewrite pexec_O.
      apply ex_expval_dret.
    - rewrite pexec_Sn_r.
      apply ex_expval_step_distr; auto.
  Qed.

  Local Lemma Expval_pexec_dec : forall n a, Expval (pexec (S n) a) h <= Expval (pexec n a) h.
  Proof.
    intros n a.
    rewrite pexec_Sn_r.
    apply Expval_step_dec, ex_expval_pexec.
  Qed.

  Local Lemma Expval_pexec_bounded : forall n a, Expval (pexec n a) h <= h a.
  Proof.
    induction n.
    - intro a; rewrite pexec_O.
      rewrite Expval_dret; lra.
    - intro a.
      etrans; [ | apply IHn].
      apply Expval_pexec_dec.
  Qed.


  Local Lemma rsm_lt_eps_final a : h a < (rsm_eps h) -> is_final a.
  Proof.
    intros Heps.
    destruct (decide (is_final a)) as [ ? | Hnf]; auto.
    exfalso.
    specialize (rsm_int h a Hnf) as Hex.
    specialize (rsm_dec h a Hnf) as Hdec.
    apply Rle_minus_r in Hdec.
    epose proof (Expval_convex_ex_le (step a) h (h a - rsm_eps h) (rsm_nneg h) Hex (step_total h a) Hdec) as [a' [Ha'1 Ha'2]]; eauto.
    pose proof ((rsm_nneg h a')); lra.
  Qed.

  Local Lemma rsm_markov_ineq (μ : distr (mstate δ)) :
      ex_expval μ h ->
         (rsm_eps h) * Expval μ (λ a, if bool_decide (is_final a) then 0 else 1) <= Expval μ h.
  Proof.
    intros Hex.
    rewrite /Expval.
    rewrite -SeriesC_scal_l.
    assert (forall x,
      (rsm_eps h * (μ x * (if bool_decide (is_final x) then 0 else 1))) =
      (μ x * (if bool_decide (is_final x) then 0 else rsm_eps h))) as Haux.
    {
      intro x; real_solver.
    }
    setoid_rewrite Haux.
    apply SeriesC_le; auto.
    pose proof (eps_pos h).
    intro a; split.
    - real_solver.
    - apply Rmult_le_compat_l; auto.
      apply (Rle_trans _ (if bool_decide (h a < rsm_eps h) then 0 else rsm_eps h)).
      + do 2 case_bool_decide; try real_solver.
        assert (is_final a); try done.
        by apply rsm_lt_eps_final.
      + case_bool_decide; try lra.
        apply rsm_nneg.
  Qed.


  Local Lemma rsm_term_dec :
    forall (n : nat) (a : mstate δ),
      Expval (pexec (S n) a) (λ x, if bool_decide (is_final x) then 0 else 1) <=
        Expval (pexec n a) (λ x, if bool_decide (is_final x) then 0 else 1).
  Proof.
    induction n; intro a.
    - rewrite pexec_O pexec_Sn Expval_dret.
      case_bool_decide.
      + rewrite step_or_final_is_final // dret_id_left
          Expval_dret.
        real_solver.
      + rewrite step_or_final_no_final //.
        etransitivity.
        * apply (SeriesC_le _ (λ x, (step a ≫= pexec 0) x)); auto.
          intro a'; split; real_solver.
        * auto.
    - do 2 rewrite pexec_Sn.
      rewrite Expval_dbind.
      + rewrite Expval_dbind.
        * apply SeriesC_le.
          -- intro a'; specialize (IHn a'); split; [ | real_solver].
             apply Rmult_le_pos; auto.
             apply SeriesC_ge_0'.
             intros; real_solver.
          -- apply (ex_expval_bounded _ _ 1).
             intro a'; split; [apply SeriesC_ge_0'; intros; real_solver | ].
             eapply Expval_bounded; real_solver.
        * real_solver.
        * apply (ex_expval_bounded _ _ 1); real_solver.
      + real_solver.
      + apply (ex_expval_bounded _ _ 1); real_solver.
  Qed.

  Local Lemma rsm_dec_aux_1 (a : mstate δ) :
         Expval (step_or_final a) h + (rsm_eps h) * (if bool_decide (is_final a) then 0 else 1) <= h a.
  Proof.
    rewrite /step_or_final.
    case_bool_decide as H.
    - apply to_final_Some_1 in H as [? ->].
      rewrite Expval_dret; lra.
    - pose proof (to_final_None_1 _ H) as ->.
      rewrite Rmult_1_r.
      apply rsm_dec; auto.
  Qed.

  Local Lemma rsm_dec_aux_2 (μ : distr (mstate δ)) :
      ex_expval μ h ->
      SeriesC μ = 1 ->
         Expval (dbind step_or_final μ) h + (rsm_eps h) * Expval μ (λ x, if bool_decide (is_final x) then 0 else 1) <= Expval μ h.
  Proof.
    intros Hex Hmass.
    rewrite Expval_dbind.
    - rewrite -Expval_scal_l
              -Expval_plus.
      + apply SeriesC_le; auto.
        intro a; split.
        * apply Rmult_le_pos; auto.
          apply Rplus_le_le_0_compat.
          -- apply SeriesC_ge_0'.
             intro; specialize (rsm_nneg h x); real_solver.
          -- specialize (eps_pos h); real_solver.
        * apply Rmult_le_compat_l; auto.
          apply rsm_dec_aux_1.
      + eapply (ex_expval_le); [ | apply Hex].
        intro a; split.
        * apply SeriesC_ge_0'.
          intro x; specialize (rsm_nneg h x); real_solver.
        * destruct (decide (is_final a)).
          -- rewrite step_or_final_is_final; auto.
             rewrite Expval_dret; lra.
          -- rewrite step_or_final_no_final; auto.
             eapply Rle_trans; [ | apply (rsm_dec h); auto].
             specialize (eps_pos h); lra.
      + apply (ex_seriesC_le _ (λ x, μ x * rsm_eps h));
          [ | apply ex_seriesC_scal_r; auto ].
        intro; split.
        * apply Rmult_le_pos; auto.
          apply Rmult_le_pos; [left; apply (eps_pos h) | ].
          real_solver.
        * apply Rmult_le_compat_l; auto.
          case_bool_decide.
          ++ rewrite Rmult_0_r; left; apply (eps_pos h).
          ++ lra.
    - intro; apply rsm_nneg.
    - rewrite /ex_expval /pmf /= /dbind_pmf.
      setoid_rewrite <- SeriesC_scal_r.
      apply (fubini_pos_seriesC_ex_double (λ '(x,a), μ x * step_or_final x a * h a)).
      + intros a b; specialize (rsm_nneg h b); real_solver.
      + intro a.
        setoid_rewrite Rmult_assoc.
        apply ex_seriesC_scal_l.
        destruct (decide (is_final a)).
        * setoid_rewrite step_or_final_is_final; auto.
          apply ex_expval_dret.
        * setoid_rewrite step_or_final_no_final; auto.
          apply (rsm_int h); auto.
      + eapply ex_seriesC_le; [ | apply Hex ].
        intro a; split.
        * apply SeriesC_ge_0'.
          intro b; specialize (rsm_nneg h b); real_solver.
        * setoid_rewrite Rmult_assoc.
          rewrite SeriesC_scal_l.
          apply Rmult_le_compat_l; auto.
          destruct (decide (is_final a)) as [Hf | Hnf].
          -- setoid_rewrite step_or_final_is_final; auto.
             (* Rewriting directly does not seem to work *)
             pose proof (Expval_dret h a) as Haux.
             rewrite /Expval in Haux.
             rewrite Haux; lra.
          -- setoid_rewrite step_or_final_no_final; auto.
             pose proof (rsm_dec h a Hnf) as H.
             rewrite /Expval in H.
             specialize (eps_pos h); real_solver.
  Qed.

  Local Lemma rsm_dec_pexec :
    forall (n : nat) (a : mstate δ),
         Expval (pexec n a) h + n * (rsm_eps h) * Expval (pexec n a) (λ x, if bool_decide (is_final x) then 0 else 1) <= h a.
  Proof.
    induction n.
    - intro a.
      replace (h a) with (Expval (pexec 0 a) h).
      2:{
        by rewrite pexec_O Expval_dret.
        }
      simpl; lra.
    - intro a.
      rewrite {1}pexec_Sn_r.
      replace (INR(S n)) with (1 + (INR n)); [ | rewrite S_INR; lra].
      (*rewrite Expval_dbind;
        [ | apply rsm_nneg | rewrite -pexec_Sn_r; apply ex_expval_pexec ].*)
      rewrite Rmult_assoc Rmult_plus_distr_r Rmult_1_l.
      etransitivity; [ | apply IHn].
      rewrite -Rplus_assoc.
      apply Rplus_le_compat.
      + etransitivity; [ | apply rsm_dec_aux_2].
        * apply Rplus_le_compat_l.
          apply Rmult_le_compat_l; [ left; apply eps_pos | ].
          apply rsm_term_dec.
        * apply ex_expval_pexec.
        * apply pexec_mass.
      + rewrite -Rmult_assoc. apply Rmult_le_compat_l.
        * apply Rmult_le_pos; [apply pos_INR | left; apply eps_pos].
        * apply rsm_term_dec.
  Qed.

  Local Lemma expval_is_final_eq_mass :
    forall (n : nat) (a : mstate δ),
         Expval (pexec n a) (λ x, if bool_decide (is_final x) then 1 else 0) = SeriesC (exec n a).
  Proof.
    induction n; intro a.
    - destruct (decide (is_final a)) as [Hf | Hnf].
      + pose proof (to_final_Some_1 a Hf) as [? ?].
        rewrite pexec_O Expval_dret.
        rewrite bool_decide_eq_true_2; auto.
        setoid_rewrite exec_is_final; auto.
        * rewrite dret_mass; auto.
        * eauto.
      + rewrite pexec_O Expval_dret.
        case_bool_decide; try done.
        rewrite /exec to_final_None_1; auto.
        rewrite dzero_mass; auto.
    - rewrite <- Rmult_1_l.
      rewrite -Expval_const; [ | lra].
      rewrite pexec_Sn.
      rewrite exec_Sn.
      rewrite Expval_dbind.
      + rewrite Expval_dbind; [ | intro; lra | apply ex_expval_const ].
        apply SeriesC_ext.
        intro; rewrite IHn Expval_const; lra.
      + intro; real_solver.
      + apply (ex_expval_bounded _ _ 1).
        intro; real_solver.
  Qed.

  Local Lemma rsm_nonterm_bound :
    forall (n : nat) (a : mstate δ),
         (1 + n) * (rsm_eps h) * Expval (pexec n a) (λ x, if bool_decide (is_final x) then 0 else 1) <= h a.
  Proof.
    intros n a.
    rewrite Rmult_assoc
      Rmult_plus_distr_r
      Rmult_1_l.
    etransitivity; [ | apply rsm_dec_pexec].
    rewrite -Rmult_assoc.
    eapply Rplus_le_compat_r.
    apply rsm_markov_ineq.
    apply ex_expval_pexec.
  Qed.

  (* This does not seem to be in the library ??? *)
  Local Lemma Req_minus_r (x y z : R):
    x + z = y -> x = y - z.
  Proof. intros; lra. Qed.

  Local Lemma Rle_exists_nat (x y : R) :
    (0 <= x) -> (0 < y) ->
                 exists (n : nat), x / (1 + n) < y.
  Proof.
    intros Hx Hy.
    assert (exists (r : R), 0 < r /\ x / r < y) as [r [Hr1 Hr2]].
    {
      exists ((x+1)/y); split.
      - apply Rdiv_lt_0_compat; lra.
      - apply Rlt_div_l.
        + apply Rlt_gt,
          Rdiv_lt_0_compat; lra.
        + rewrite Rmult_comm Rmult_assoc Rinv_l; lra.
    }
    destruct (nfloor1_ex r Hr1) as [n Hn].
    exists (S (S n)).
    do 2 rewrite S_INR.
    apply Rlt_div_l; [lra | ].
    apply Rlt_div_l in Hr2; auto.
    apply (Rlt_le_trans _ _ _ Hr2).
    apply Rmult_le_compat_l; lra.
  Qed.

  Lemma rsm_term_bound_exec_n (n : nat) (a : mstate δ) :
         1 - h a / ((1 + n) * (rsm_eps h)) <= SeriesC (exec n a).
  Proof.
    rewrite -expval_is_final_eq_mass.
    assert (Expval (pexec n a) (λ x : mstate δ, if bool_decide (is_final x) then 1 else 0) =
           1 - Expval (pexec n a) (λ x : mstate δ, if bool_decide (is_final x) then 0 else 1)) as ->.
    {
      apply Req_minus_r.
      rewrite -SeriesC_plus.
      - setoid_rewrite <- Rmult_plus_distr_l.
        erewrite SeriesC_ext.
        + apply (pexec_mass n a).
        + intros; case_bool_decide; lra.
      - apply (ex_seriesC_le _ (pexec n a)); auto.
        intros; real_solver.
      - apply (ex_seriesC_le _ (pexec n a)); auto.
        intros; real_solver.
    }
    apply Rplus_le_compat_l,
      Ropp_ge_le_contravar,
      Rle_ge.
    apply Rle_div_r.
    - pose proof (eps_pos h).
      apply Rlt_gt,
        Rmult_lt_0_compat; auto.
      apply Rplus_lt_le_0_compat; try lra.
      apply pos_INR.
    - rewrite Rmult_comm.
      apply rsm_nonterm_bound.
  Qed.


  Lemma rsm_term_bound_exec_n_eps (a : mstate δ) (eps : posreal) :
    exists (n : nat), 1 - eps < SeriesC (exec n a).
  Proof using h δ.
    destruct eps as [eps Hpos].
    simpl.
    assert (exists (n : nat), h a / ((1 + n) * (rsm_eps h)) < eps) as [n Hn].
    {
      pose proof (eps_pos h).
      epose proof (Rle_exists_nat (h a) (eps * (rsm_eps h)) _ _) as [n Hn].
      exists n.
      pose proof (pos_INR n).
      apply Rlt_div_l.
      - apply Rlt_gt.
        apply Rmult_lt_0_compat; [  | lra].
        apply Rplus_lt_le_0_compat; lra.
      - apply (Rlt_div_l (h a)) in Hn; lra.
      Unshelve.
        + apply (rsm_nneg h).
        + apply Rmult_lt_0_compat; lra.
    }
    exists n.
    eapply Rlt_le_trans ; [  | apply rsm_term_bound_exec_n].
    lra.
  Qed.

  Lemma rsm_term_limexec (a : mstate δ) :
         SeriesC (lim_exec a) = 1.
  Proof using h δ.
    erewrite SeriesC_ext; last first.
    { intros. rewrite lim_exec_unfold //. }
    erewrite (MCT_seriesC _ (λ n, SeriesC (exec n a)) (Sup_seq (λ n, SeriesC (exec n a)))); eauto.
    - symmetry. apply eq_rbar_finite.
      symmetry. apply is_sup_seq_unique.
      split.
      + intro.
        apply (Rle_lt_trans _ 1); auto.
        rewrite <-(Rplus_0_r 1) at 1.
        apply Rplus_lt_compat_l; auto.
        apply cond_pos.
      + pose proof (rsm_term_bound_exec_n_eps a eps) as [n Hn].
        eexists n.
        simpl; lra.
    - apply exec_mono.
    - intros. by apply SeriesC_correct.
    - rewrite (Rbar_le_sandwich 0 1).
      + apply (Sup_seq_correct (λ n, SeriesC (exec n a))).
      + by apply (Sup_seq_minor_le _ _ 0%nat)=>/=.
      + by apply upper_bound_ge_sup=>/=.
  Qed.


End martingales.






#[global] Arguments pexec {_} _ _ : simpl never.
