From iris.algebra Require Import frac_auth.
From iris.base_logic.lib Require Import invariants.
From clutch.coneris Require Import coneris hocap random_counter.

Set Default Proof Using "Type*".

Local Definition expander (l:list nat):=
  l ≫= (λ x, [Nat.div2 x; Nat.b2n (Nat.odd x)]).

Class hocap_tapesGS' (Σ : gFunctors) := Hocap_tapesGS' {
  hocap_tapesGS_inG' :: ghost_mapG Σ loc (bool* (nat*list nat))
                                         }.
Definition hocap_tapesΣ' := ghost_mapΣ loc (bool*(nat*list nat)).

Notation "α ◯↪N ( b ,  M ; ns ) @ γ":= (α ↪[ γ ] (b, (M,ns)))%I
                                    (at level 20) : bi_scope.

Notation "● m @ γ" := (ghost_map_auth γ 1 m) (at level 20) : bi_scope.

Section tapes_lemmas.
  Context `{!conerisGS Σ, !hocap_tapesGS' Σ}.

  Lemma hocap_tapes_alloc' m:
    ⊢ |==>∃ γ, (● m @ γ) ∗ [∗ map] k↦v ∈ m, (k ◯↪N (v.1, v.2.1; v.2.2) @ γ).
  Proof.
    iMod ghost_map_alloc as (γ) "[??]".
    iFrame. iModIntro.
    iApply big_sepM_mono; last done.
    by iIntros (?[?[??]]).
  Qed.

  Lemma hocap_tapes_agree' m b γ k N ns:
    (● m @ γ) -∗ (k ◯↪N (b, N; ns) @ γ) -∗ ⌜ m!!k = Some (b, (N, ns)) ⌝.
  Proof.
    iIntros "H1 H2".
    by iCombine "H1 H2" gives "%".
  Qed.

  Lemma hocap_tapes_new' γ m k N ns b:
    m!!k=None -> ⊢ (● m @ γ) ==∗ (● (<[k:=(b, (N,ns))]>m) @ γ) ∗ (k ◯↪N (b, N; ns) @ γ).
  Proof.
    iIntros (Hlookup) "H".
    by iApply ghost_map_insert.
  Qed.

  (* Lemma hocap_tapes_presample γ m k N ns n: *)
  (*   (● m @ γ) -∗ (k ◯↪N (N; ns) @ γ) ==∗ (● (<[k:=(N,ns++[n])]>m) @ γ) ∗ (k ◯↪N (N; ns++[n]) @ γ). *)
  (* Proof. *)
  (*   iIntros "H1 H2". *)
  (*   iApply (ghost_map_update with "[$][$]").  *)
  (* Qed. *)

  Lemma hocap_tapes_pop1' γ m k N ns:
    (● m @ γ) -∗ (k ◯↪N (true, N; ns) @ γ) ==∗ (● (<[k:=(false, (N,ns))]>m) @ γ) ∗ (k ◯↪N (false, N; ns) @ γ).
  Proof.
    iIntros "H1 H2".
    iApply (ghost_map_update with "[$][$]").
  Qed.
  
  Lemma hocap_tapes_pop2' γ m k N ns n:
    (● m @ γ) -∗ (k ◯↪N (false, N; n::ns) @ γ) ==∗ (● (<[k:=(true, (N,ns))]>m) @ γ) ∗ (k ◯↪N (true, N; ns) @ γ).
  Proof.
    iIntros "H1 H2".
    iApply (ghost_map_update with "[$][$]").
  Qed.

  Lemma hocap_tapes_notin' α N ns m (f:(bool*(nat*list nat))-> nat) g:
    α ↪N (N; ns) -∗ ([∗ map] α0↦t ∈ m, α0 ↪N (f t; g t)) -∗ ⌜m!!α=None ⌝.
  Proof.
    destruct (m!!α) eqn:Heqn; last by iIntros.
    iIntros "Hα Hmap".
    iDestruct (big_sepM_lookup with "[$]") as "?"; first done.
    iExFalso.
    iApply (tapeN_tapeN_contradict with "[$][$]").
  Qed.

End tapes_lemmas.

Section lemmas.
  Context `{hocap_tapesGS' Σ}.
End lemmas.

Section impl2.

  Definition new_counter2 : val:= λ: "_", ref #0.
  Definition incr_counter2 : val := λ: "l", let: "n" := rand #1 in
                                            let: "n'" := rand #1 in
                                            let: "x" := #2 * "n" + "n'" in
                                            (FAA "l" "x", "x").
  Definition allocate_tape2 : val := λ: "_", AllocTape #1.
  Definition incr_counter_tape2 :val := λ: "l" "α", let: "n" := rand("α") #1 in
                                                    let: "n'" := rand("α") #1 in
                                                    let: "x" := #2 * "n" + "n'" in
                                                    (FAA "l" "x", "x").
  Definition read_counter2 : val := λ: "l", !"l".
  Class counterG1 Σ := CounterG1 { counterG1_error::hocap_errorGS Σ;
                                   counterG1_tapes:: hocap_tapesGS' Σ;
                                   counterG1_frac_authR:: inG Σ (frac_authR natR) }.
  
  Context `{!conerisGS Σ, !hocap_errorGS Σ, !hocap_tapesGS' Σ, !inG Σ (frac_authR natR)}.
  
  
  Definition counter_inv_pred2 (c:val) γ1 γ2 γ3:=
    (∃ (ε:R) (m:gmap loc (bool*(nat * list nat))) (l:loc) (z:nat),
        ↯ ε ∗ ●↯ ε @ γ1 ∗
        ([∗ map] α ↦ t ∈ m, α ↪N ( t.2.1 `div` 2%nat ; if t.1:bool then expander t.2.2 else drop 1%nat (expander t.2.2)) )
        ∗ ●m@γ2 ∗  
        ⌜c=#l⌝ ∗ l ↦ #z ∗ own γ3 (●F z)
    )%I.

  Lemma new_counter_spec2 E ε N:
    {{{ ↯ ε }}}
      new_counter2 #() @ E
      {{{ (c:val), RET c;
          ∃ γ1 γ2 γ3, inv N (counter_inv_pred2 c γ1 γ2 γ3) ∗
                      ◯↯ε @ γ1 ∗ own γ3 (◯F 0%nat)
      }}}.
  Proof.
    rewrite /new_counter2.
    iIntros (Φ) "Hε HΦ".
    wp_pures.
    wp_alloc l as "Hl".
    iDestruct (ec_valid with "[$]") as "%".
    unshelve iMod (hocap_error_alloc (mknonnegreal ε _)) as "[%γ1 [H1 H2]]".
    { lra. }
    simpl.
    iMod (hocap_tapes_alloc' (∅:gmap _ _)) as "[%γ2 [H3 H4]]".
    iMod (own_alloc (●F 0%nat ⋅ ◯F 0%nat)) as "[%γ3[H5 H6]]".
    { by apply frac_auth_valid. }
    replace (#0) with (#0%nat) by done.
    iMod (inv_alloc N _ (counter_inv_pred2 (#l) γ1 γ2 γ3) with "[$Hε $Hl $H1 $H3 $H5]") as "#Hinv".
    { iSplit; last done. by iApply big_sepM_empty. }
    iApply "HΦ".
    iExists _, _, _. by iFrame.
  Qed.


  (** This lemma is not possible as only one view shift*)
  Lemma incr_counter_spec2 E N c γ1 γ2 γ3 (ε2:R -> nat -> R) (P: iProp Σ) (T: nat -> iProp Σ) (Q: nat->nat->iProp Σ):
    ↑N ⊆ E->
    (∀ ε n, 0<= ε -> 0<= ε2 ε n)%R->
    (∀ (ε:R), 0<=ε -> ((ε2 ε 0%nat) + (ε2 ε 1%nat)+ (ε2 ε 2%nat)+ (ε2 ε 3%nat))/4 <= ε)%R →
    {{{ inv N (counter_inv_pred2 c γ1 γ2 γ3) ∗
        □(∀ (ε:R) (n : nat), P ∗ ●↯ ε @ γ1 ={E∖↑N}=∗ (⌜(1<=ε2 ε n)%R⌝∨●↯ (ε2 ε n) @ γ1 ∗ T n) ) ∗
        □ (∀ (n z:nat), T n ∗ own γ3 (●F z) ={E∖↑N}=∗
                          own γ3 (●F(z+n)%nat)∗ Q z n) ∗
        P
    }}}
      incr_counter2 c @ E
      {{{ (n:nat) (z:nat), RET (#z, #n); Q z n }}}.
  Proof.
    iIntros (Hsubset Hpos Hineq Φ) "(#Hinv & #Hvs1 & #Hvs2 & HP) HΦ".
    rewrite /incr_counter2.
    wp_pures.
    wp_bind (rand _)%E.
    iInv N as ">(%ε & %m & %l & %z & H1 & H2 & H3 & H4 & -> & H5 & H6)" "Hclose".
    (** cant do two view shifts! *)
  Abort.
    (* iDestruct (ec_valid with "[$]") as "[%K1 %K2]". *)
  (*   wp_apply (wp_couple_rand_adv_comp1' _ _ _ _ (λ x, ε2 ε (fin_to_nat x)) with "[$]"). *)
  (*   { intros. naive_solver. } *)
  (*   { rewrite SeriesC_finite_foldr; specialize (Hineq ε K1). simpl; lra. } *)
  (*   iIntros (n) "H1". *)
  (*   iMod ("Hvs1" with "[$]") as "[%|[H2 HT]]". *)
  (*   { iExFalso. iApply ec_contradict; last done. done. } *)
  (*   iMod ("Hclose" with "[$H1 $H2 $H3 $H4 $H5 $H6]") as "_"; first done. *)
  (*   iModIntro. wp_pures. *)
  (*   clear -Hsubset. *)
  (*   wp_bind (FAA _ _). *)
  (*   iInv N as ">(%ε & %m & % & %z & H1 & H2 & H3 & H4 & -> & H5 & H6)" "Hclose". *)
  (*   wp_faa. *)
  (*   iMod ("Hvs2" with "[$]") as "[H6 HQ]". *)
  (*   replace (#(z+n)) with (#(z+n)%nat); last first. *)
  (*   { by rewrite Nat2Z.inj_add. } *)
  (*   iMod ("Hclose" with "[$H1 $H2 $H3 $H4 $H5 $H6]") as "_"; first done. *)
  (*   iModIntro. *)
  (*   wp_pures. *)
  (*   by iApply "HΦ". *)
  (* Qed. *)

  Lemma allocate_tape_spec2 N E c γ1 γ2 γ3:
    ↑N ⊆ E->
    {{{ inv N (counter_inv_pred2 c γ1 γ2 γ3) }}}
      allocate_tape2 #() @ E
      {{{ (v:val), RET v;
          ∃ (α:loc), ⌜v=#lbl:α⌝ ∗ α ◯↪N (true, 3%nat; []) @ γ2
      }}}.
  Proof.
    iIntros (Hsubset Φ) "#Hinv HΦ".
    rewrite /allocate_tape2.
    wp_pures.
    wp_alloctape α as "Hα".
    iInv N as ">(%ε & %m & %l & %z & H1 & H2 & H3 & H4 & -> & H5 & H6)" "Hclose".
    iDestruct (hocap_tapes_notin' with "[$][$]") as "%".
    iMod (hocap_tapes_new' _ _ _ 3%nat _ true with "[$]") as "[H4 H7]"; first done.
    replace ([]) with (expander []) by done.
    iMod ("Hclose" with "[$H1 $H2 H3 $H4 $H5 $H6 Hα]") as "_".
    { iNext. iSplitL; last done.
      rewrite big_sepM_insert; [iFrame|done].
    }
    iApply "HΦ".
    by iFrame.
  Qed.

  Lemma incr_counter_tape_spec_some2 N E c γ1 γ2 γ3 (P: iProp Σ) (Q:nat->iProp Σ) (α:loc) (n:nat) ns:
    ↑N⊆E ->
    {{{ inv N (counter_inv_pred2 c γ1 γ2 γ3) ∗
        □ (∀ (z:nat), P ∗ own γ3 (●F z) ={E∖↑N}=∗
                          own γ3 (●F(z+n)%nat)∗ Q z) ∗
        P ∗ α ◯↪N (true, 3%nat; n::ns) @ γ2
    }}}
      incr_counter_tape2 c #lbl:α @ E
      {{{ (z:nat), RET (#z, #n); Q z ∗ α ◯↪N (true, 3%nat; ns) @ γ2}}}.
  Proof.
    iIntros (Hsubset Φ) "(#Hinv & #Hvs & HP & Hα) HΦ".
    rewrite /incr_counter_tape2.
    wp_pures.
    wp_bind (rand(_) _)%E.
    iInv N as ">(%ε & %m & %l & %z & H1 & H2 & H3 & H4 & -> & H5 & H6)" "Hclose".
    iDestruct (hocap_tapes_agree' with "[$][$]") as "%".
    erewrite <-(insert_delete m) at 1; last done.
    rewrite big_sepM_insert; last apply lookup_delete.
    simpl.
    iDestruct "H3" as "[Htape H3]".
    wp_apply (wp_rand_tape with "[$]").
    iIntros "[Htape %H1]".
    iMod (hocap_tapes_pop1' with "[$][$]") as "[H4 Hα]".
    iMod ("Hclose" with "[$H1 $H2 H3 $H4 $H5 $H6 Htape]") as "_".
    { iSplitL; last done.
      erewrite <-(insert_delete m) at 2; last done.
      iNext.
      rewrite insert_insert.
      rewrite big_sepM_insert; last apply lookup_delete. iFrame.
    }
    iModIntro.
    wp_pures.
    clear -Hsubset H1.
    wp_bind (rand(_) _)%E.
    iInv N as ">(%ε & %m & % & %z & H1 & H2 & H3 & H4 & -> & H5 & H6)" "Hclose".
    iDestruct (hocap_tapes_agree' with "[$][$]") as "%".
    erewrite <-(insert_delete m) at 1; last done.
    rewrite big_sepM_insert; last apply lookup_delete.
    simpl.
    iDestruct "H3" as "[Htape H3]".
    wp_apply (wp_rand_tape with "[$]").
    iIntros "[Htape %H2]".
    iMod (hocap_tapes_pop2' with "[$][$]") as "[H4 Hα]".
    iMod ("Hclose" with "[$H1 $H2 H3 $H4 $H5 $H6 Htape]") as "_".
    { iSplitL; last done.
      erewrite <-(insert_delete m) at 2; last done.
      iNext.
      rewrite insert_insert.
      rewrite big_sepM_insert; last apply lookup_delete. iFrame.
    }
    iModIntro.
    wp_pures.
    clear -Hsubset H1 H2.
    wp_bind (FAA _ _).
    iInv N as ">(%ε & %m & % & %z & H1 & H2 & H3 & H4 & -> & H5 & H6)" "Hclose".
    wp_faa.
    iMod ("Hvs" with "[$]") as "[H6 HQ]".
    replace (#(z+n)) with (#(z+n)%nat); last first.
    { by rewrite Nat2Z.inj_add. }
    replace 2%Z with (Z.of_nat 2%nat) by done.
    rewrite -Nat2Z.inj_mul -Nat2Z.inj_add -Nat.div2_odd -Nat2Z.inj_add. 
    iMod ("Hclose" with "[$H1 $H2 $H3 $H4 H5 $H6]") as "_"; first by iFrame.
    iModIntro. wp_pures.
    iApply "HΦ".
    by iFrame.
  Qed.

  (** TODO *)
  Lemma counter_presample_spec2 NS  E ns α
     (ε2 : R -> nat -> R)
    (P : iProp Σ) T γ1 γ2 γ3 c:
    ↑NS ⊆ E ->
    (∀ ε n, 0<= ε -> 0<=ε2 ε n)%R ->
    (∀ (ε:R), 0<= ε ->SeriesC (λ n, if (bool_decide (n≤3%nat)) then 1 / (S 3%nat) * ε2 ε n else 0%R)%R <= ε)%R->
    inv NS (counter_inv_pred2 c γ1 γ2 γ3) -∗
    (□∀ (ε:R) n, (P ∗ ●↯ ε@ γ1) ={E∖↑NS}=∗
        (⌜(1<=ε2 ε n)%R⌝ ∨(●↯ (ε2 ε n) @ γ1 ∗ T (n))))
        -∗
    P -∗ α ◯↪N (true, 3%nat; ns) @ γ2 -∗
        wp_update E (∃ n, T (n) ∗ α◯↪N (true, 3%nat; ns++[n]) @ γ2).
  Proof.
    iIntros (Hsubset Hpos Hineq) "#Hinv #Hvs HP Hfrag".
    rewrite wp_update_unfold.
    iIntros (?? Hv) "Hcnt".
    rewrite {2}pgl_wp_unfold /pgl_wp_pre /= Hv.
    iIntros (σ ε) "((Hheap&Htapes)&Hε)".
    iMod (inv_acc with "Hinv") as "[>(% & % & % & % & H1 & H2 & H3 & H4 & -> & H5 & H6) Hclose]"; [done|].
    iDestruct (hocap_tapes_agree' with "[$][$]") as "%".
    erewrite <-(insert_delete m) at 1; last done.
    rewrite big_sepM_insert; last apply lookup_delete.
    simpl.
    iDestruct "H3" as "[Htape H3]".
    iDestruct (tapeN_lookup with "[$][$]") as "(%&%&%)".
    iDestruct (ec_supply_bound with "[$][$]") as "%".
    iMod (ec_supply_decrease with "[$][$]") as (ε1' ε_rem -> Hε1') "Hε_supply". subst.
    iApply fupd_mask_intro; [set_solver|]; iIntros "Hclose'".
  Admitted.
  (*   iApply glm_state_adv_comp_con_prob_lang; first done. *)
  (*   unshelve iExists (λ x, mknonnegreal (ε2 ε1' x) _). *)
  (*   { apply Hpos. apply cond_nonneg. } *)
  (*   iSplit. *)
  (*   { iPureIntro. *)
  (*     unshelve epose proof (Hineq ε1' _) as H1; first apply cond_nonneg. *)
  (*     by rewrite SeriesC_nat_bounded_fin in H1. } *)
  (*   iIntros (sample). *)
    
  (*   destruct (Rlt_decision (nonneg ε_rem + (ε2 ε1' sample))%R 1%R) as [Hdec|Hdec]; last first. *)
  (*   { apply Rnot_lt_ge, Rge_le in Hdec. *)
  (*     iLeft. *)
  (*     iPureIntro. *)
  (*     simpl. simpl in *. lra. *)
  (*   } *)
  (*   iRight. *)
  (*   unshelve iMod (ec_supply_increase _ (mknonnegreal (ε2 ε1' sample) _) with "Hε_supply") as "[Hε_supply Hε]". *)
  (*   { apply Hpos. apply cond_nonneg. } *)
  (*   { simpl. done. } *)
  (*   iMod (tapeN_update_append _ _ _ _ sample with "[$][$]") as "[Htapes Htape]". *)
  (*   iMod (hocap_tapes_presample _ _ _ _ _ (fin_to_nat sample) with "[$][$]") as "[H4 Hfrag]". *)
  (*   iMod "Hclose'" as "_". *)
  (*   iMod ("Hvs" with "[$]") as "[%|[H2 HT]]". *)
  (*   { iExFalso. iApply (ec_contradict with "[$]"). exact. } *)
  (*   iMod ("Hclose" with "[$Hε $H2 Htape H3 $H4 $H5 $H6]") as "_". *)
  (*   { iNext. iSplit; last done. *)
  (*     rewrite big_sepM_insert_delete; iFrame. *)
  (*   } *)
  (*   iSpecialize ("Hcnt" with "[$]"). *)
  (*   setoid_rewrite pgl_wp_unfold. *)
  (*   rewrite /pgl_wp_pre /= Hv. *)
  (*   iApply ("Hcnt" $! (state_upd_tapes <[α:= (3%nat; ns' ++[sample]):tape]> σ) with "[$]"). *)
  (* Qed. *)

  
  Lemma incr_counter_tape_spec_none2 N E c γ1 γ2 γ3 (ε2:R -> nat -> R) (P: iProp Σ) (T: nat -> iProp Σ) (Q: nat -> nat -> iProp Σ)(α:loc) (ns:list nat):
    ↑N ⊆ E->
    (∀ ε n, 0<= ε -> 0<= ε2 ε n)%R->
    (∀ (ε:R), 0<=ε -> ((ε2 ε 0%nat) + (ε2 ε 1%nat)+ (ε2 ε 2%nat)+ (ε2 ε 3%nat))/4 <= ε)%R →
    {{{ inv N (counter_inv_pred2 c γ1 γ2 γ3) ∗
        □(∀ (ε:R) (n : nat), P ∗ ●↯ ε @ γ1 ={E∖↑N}=∗ (⌜(1<=ε2 ε n)%R⌝∨●↯ (ε2 ε n) @ γ1 ∗ T n) ) ∗
        □ (∀ (n:nat) (z:nat), T n ∗ own γ3 (●F z) ={E∖↑N}=∗
                          own γ3 (●F(z+n)%nat)∗ Q z n) ∗
        P ∗ α ◯↪N (true, 3%nat; []) @ γ2
    }}}
      incr_counter_tape2 c #lbl:α @ E
      {{{ (z:nat) (n:nat), RET (#z, #n); Q z n ∗ α ◯↪N (true, 3%nat; []) @ γ2 }}}.
  Proof.
    iIntros (Hsubset Hpos Hineq Φ) "(#Hinv & #Hvs1 & #Hvs2 & HP & Hα) HΦ".
    iMod (counter_presample_spec2 with "[//][//][$][$]") as "(%&HT&Hα)"; try done.
    { intros ε Hε. specialize (Hineq ε Hε).
      rewrite SeriesC_nat_bounded_fin SeriesC_finite_foldr /=. lra.
    }
    iApply (incr_counter_tape_spec_some2 _ _ _ _ _ _ (T n) (λ x, Q x n) with "[$Hα $HT]"); try done.
    { by iSplit. }
    iNext. 
    iIntros. iApply ("HΦ" with "[$]").
  Qed.

  Lemma read_counter_spec2 N E c γ1 γ2 γ3 P Q:
    ↑N ⊆ E ->
    {{{  inv N (counter_inv_pred2 c γ1 γ2 γ3) ∗
        □ (∀ (z:nat), P ∗ own γ3 (●F z) ={E∖↑N}=∗
                    own γ3 (●F z)∗ Q z)
         ∗ P
    }}}
      read_counter2 c @ E
      {{{ (n':nat), RET #n'; Q n'
      }}}.
  Proof.
    iIntros (Hsubset Φ) "(#Hinv & #Hvs & HP) HΦ".
    rewrite /read_counter2.
    wp_pure.
    iInv N as ">(%ε & %m & %l & %z & H1 & H2 & H3 & H4 & -> & H5 & H6)" "Hclose".
    wp_load.
    iMod ("Hvs" with "[$]") as "[H6 HQ]".
    iMod ("Hclose" with "[$H1 $H2 $H3 $H4 $H5 $H6]"); first done.
    iApply ("HΦ" with "[$]").
  Qed.
  
End impl2.

(* Program Definition random_counter1 `{!conerisGS Σ}: random_counter := *)
(*   {| new_counter := new_counter1; *)
(*     incr_counter := incr_counter1; *)
(*     allocate_tape:= allocate_tape1; *)
(*     incr_counter_tape := incr_counter_tape1; *)
(*     read_counter:=read_counter1; *)
(*     counterG := counterG1; *)
(*     error_name := gname; *)
(*     tape_name := gname; *)
(*     counter_name :=gname; *)
(*     is_counter _ N c γ1 γ2 γ3 := inv N (counter_inv_pred1 c γ1 γ2 γ3); *)
(*     counter_error_auth _ γ x := ●↯ x @ γ; *)
(*     counter_error_frag _ γ x := ◯↯ x @ γ; *)
(*     counter_tapes_auth _ γ m := (●m@γ)%I; *)
(*     counter_tapes_frag _ γ α N ns := (α◯↪N (N;ns) @ γ)%I; *)
(*     counter_content_auth _ γ z := own γ (●F z); *)
(*     counter_content_frag _ γ f z := own γ (◯F{f} z); *)
(*     new_counter_spec _ := new_counter_spec1; *)
(*     incr_counter_spec _ := incr_counter_spec1; *)
(*     allocate_tape_spec _ :=allocate_tape_spec1; *)
(*     incr_counter_tape_spec_some _ :=incr_counter_tape_spec_some1; *)
(*     incr_counter_tape_spec_none _ := incr_counter_tape_spec_none1; *)
(*     counter_presample_spec _ :=counter_presample_spec1; *)
(*     read_counter_spec _ :=read_counter_spec1 *)
(*   |}. *)
(* Next Obligation. *)
(*   simpl. *)
(*   iIntros (??????) "(%&<-&H1)(%&<-&H2)". *)
(*   iCombine "H1 H2" gives "%H". by rewrite excl_auth.excl_auth_auth_op_valid in H. *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. *)
(*   iIntros (??????) "(%&<-&H1)(%&<-&H2)". *)
(*   iCombine "H1 H2" gives "%H". by rewrite excl_auth.excl_auth_frag_op_valid in H. *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. *)
(*   iIntros (??????) "H1 H2". *)
(*   iApply (hocap_error_agree with "[$][$]"). *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. iIntros (???????) "??". *)
(*   iApply (hocap_error_update with "[$][$]"). *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. *)
(*   iIntros (??????) "H1 H2". *)
(*   by iDestruct (ghost_map_auth_valid_2 with "[$][$]") as "[%H _]". *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl.  *)
(*   iIntros (?????????) "H1 H2". *)
(*   iDestruct (ghost_map_elem_frac_ne with "[$][$]") as "%"; last done. *)
(*   rewrite dfrac_op_own dfrac_valid_own. by intro. *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. *)
(*   iIntros. *)
(*   iApply (hocap_tapes_agree with "[$][$]"). *)
(* Qed. *)
(* Next Obligation. *)
(*   iIntros. *)
(*   iApply (hocap_tapes_presample with "[$][$]"). *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. *)
(*   iIntros (??????) "H1 H2". *)
(*   iCombine "H1 H2" gives "%H". by rewrite auth_auth_op_valid in H. *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. iIntros (???? z z' ?) "H1 H2". *)
(*   iCombine "H1 H2" gives "%H". *)
(*   apply frac_auth_included_total in H. iPureIntro. *)
(*   by apply nat_included. *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. iIntros (??????) "H1 H2". *)
(*   iCombine "H1 H2" gives "%H". *)
(*   iPureIntro. *)
(*   by apply frac_auth_agree_L in H. *)
(* Qed. *)
(* Next Obligation. *)
(*   simpl. iIntros (????????) "H1 H2". *)
(*   iMod (own_update_2 _ _ _ (_ ⋅ _) with "[$][$]") as "[$$]"; last done. *)
(*   apply frac_auth_update. *)
(*   apply nat_local_update. lia. *)
(* Qed. *)
  
