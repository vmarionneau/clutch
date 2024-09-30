From iris.algebra Require Import frac_auth.
From iris.base_logic.lib Require Import invariants.
From clutch.coneris Require Import coneris hocap random_counter hocap_flip.

Set Default Proof Using "Type*".

Local Definition expander (l:list nat):=
  l ≫= (λ x, [2<=?x; (Nat.odd x)]).
Local Lemma expander_eta x: x<4->(Z.of_nat x=  Z.of_nat 2*Z.b2z (2<=? x)%nat +  Z.b2z (Nat.odd x))%Z.
Proof.
  destruct x as [|[|[|[|]]]]; last lia; intros; simpl; lia.
Qed.

Local Lemma expander_inj l1 l2: Forall (λ x, x<4) l1 ->
                                   Forall (λ y, y<4) l2 ->
                                   expander l1 = expander l2 ->
                                   l1 = l2. 
Proof.
  rewrite /expander.
  revert l2.
  induction l1 as [|x xs IH].
  - simpl.
    by intros [] ???.
  - simpl.
    intros [|y ys]; simpl; first done.
    rewrite !Forall_cons.
    rewrite /Nat.odd.
    intros [K1 H1] [K2 H2] H.
    simplify_eq.
    f_equal; last naive_solver.
    repeat (destruct x as [|x]; try lia);
      repeat (destruct y as [|y]; try lia);
      simpl in *; simplify_eq.
Qed.
(* Local Definition expander (l:list nat):= *)
(*   l ≫= (λ x, [Nat.div2 x; Nat.b2n (Nat.odd x)]). *)

(* Class hocap_tapesGS' (Σ : gFunctors) := Hocap_tapesGS' { *)
(*   hocap_tapesGS_inG' :: ghost_mapG Σ loc (bool* list nat) *)
(*                                          }. *)
(* Definition hocap_tapesΣ' := ghost_mapΣ loc (bool *list nat). *)

(* Notation "α ◯↪N ( b , ns ) @ γ":= (α ↪[ γ ] (b, ns))%I *)
(*                                     (at level 20) : bi_scope. *)

(* Notation "● m @ γ" := (ghost_map_auth γ 1 m) (at level 20) : bi_scope. *)

(* Section tapes_lemmas. *)
(*   Context `{!hocap_tapesGS' Σ}. *)

(*   Lemma hocap_tapes_alloc' m: *)
(*     ⊢ |==>∃ γ, (● m @ γ) ∗ [∗ map] k↦v ∈ m, (k ◯↪N (v.1, v.2) @ γ). *)
(*   Proof. *)
(*     iMod ghost_map_alloc as (γ) "[??]". *)
(*     iFrame. iModIntro. *)
(*     iApply big_sepM_mono; last done. *)
(*     by iIntros (?[??]). *)
(*   Qed. *)

(*   Lemma hocap_tapes_agree' m b γ k ns: *)
(*     (● m @ γ) -∗ (k ◯↪N (b, ns) @ γ) -∗ ⌜ m!!k = Some (b, ns) ⌝. *)
(*   Proof. *)
(*     iIntros "H1 H2". *)
(*     by iCombine "H1 H2" gives "%". *)
(*   Qed. *)

(*   Lemma hocap_tapes_new' γ m k ns b: *)
(*     m!!k=None -> ⊢ (● m @ γ) ==∗ (● (<[k:=(b, ns)]>m) @ γ) ∗ (k ◯↪N (b, ns) @ γ). *)
(*   Proof. *)
(*     iIntros (Hlookup) "H". *)
(*     by iApply ghost_map_insert. *)
(*   Qed. *)

(*   Lemma hocap_tapes_presample' b γ m k ns n: *)
(*     (● m @ γ) -∗ (k ◯↪N (b, ns) @ γ) ==∗ (● (<[k:=(b, ns++[n])]>m) @ γ) ∗ (k ◯↪N (b, ns++[n]) @ γ). *)
(*   Proof. *)
(*     iIntros "H1 H2". *)
(*     iApply (ghost_map_update with "[$][$]"). *)
(*   Qed. *)

(*   Lemma hocap_tapes_pop1' γ m k ns: *)
(*     (● m @ γ) -∗ (k ◯↪N (true, ns) @ γ) ==∗ (● (<[k:=(false, ns)]>m) @ γ) ∗ (k ◯↪N (false, ns) @ γ). *)
(*   Proof. *)
(*     iIntros "H1 H2". *)
(*     iApply (ghost_map_update with "[$][$]"). *)
(*   Qed. *)
  
(*   Lemma hocap_tapes_pop2' γ m k ns n: *)
(*     (● m @ γ) -∗ (k ◯↪N (false, n::ns) @ γ) ==∗ (● (<[k:=(true, ns)]>m) @ γ) ∗ (k ◯↪N (true, ns) @ γ). *)
(*   Proof. *)
(*     iIntros "H1 H2". *)
(*     iApply (ghost_map_update with "[$][$]"). *)
(*   Qed. *)

(*   Lemma hocap_tapes_notin' `{F: flip_spec Σ} {L:flipG Σ} α ns m γ (f:(bool*list nat)-> (list bool)) : *)
(*     flip_tapes_frag (L:=L) γ α ns -∗ ([∗ map] α0↦t ∈ m, flip_tapes_frag (L:=L) γ α0 (f t)) -∗ ⌜m!!α=None ⌝. *)
(*   Proof. *)
(*     destruct (m!!α) eqn:Heqn; last by iIntros. *)
(*     iIntros "Hα Hmap". *)
(*     iDestruct (big_sepM_lookup with "[$]") as "?"; first done. *)
(*     iExFalso. *)
(*     by iDestruct (flip_tapes_frag_exclusive with "[$][$]") as "%". *)
(*   Qed. *)

(* End tapes_lemmas. *)

Section impl2.
  Context `{F: flip_spec Σ}.
  Definition new_counter2 : val:= λ: "_", ref #0.
  (* Definition incr_counter2 : val := λ: "l", let: "n" := rand #1 in *)
  (*                                           let: "n'" := rand #1 in *)
  (*                                           let: "x" := #2 * "n" + "n'" in *)
  (*                                           (FAA "l" "x", "x"). *)
  Definition allocate_tape2 : val := flip_allocate_tape.
  Definition incr_counter_tape2 :val := λ: "l" "α", let: "n" :=
                                                      conversion.bool_to_int (flip_tape "α")
                                                    in
                                                    let: "n'" :=
                                                      conversion.bool_to_int (flip_tape "α")
                                                    in
                                                    let: "x" := #2 * "n" + "n'" in
                                                    (FAA "l" "x", "x").
  Definition read_counter2 : val := λ: "l", !"l".
  Class counterG2 Σ := CounterG2 { (* counterG2_tapes:: hocap_tapesGS' Σ; *)
                                   counterG2_frac_authR:: inG Σ (frac_authR natR);
                                   counterG2_flipG: flipG Σ
                         }.
  
  Context `{L:!flipG Σ, !inG Σ (frac_authR natR)}.
  
  
  Definition counter_inv_pred2 (c:val) γ :=
    (∃ (l:loc) (z:nat),
        ⌜c=#l⌝ ∗ l ↦ #z ∗ own γ (●F z)
    )%I.

  Definition is_counter2 N (c:val) γ1 γ2:=
    (is_flip (L:=L) (N.@"flip") γ1 ∗
    inv (N.@"counter") (counter_inv_pred2 c γ2)
    )%I.

  Lemma new_counter_spec2 E N:
    {{{ True }}}
      new_counter2 #() @ E
      {{{ (c:val), RET c;
          ∃ γ1 γ2, is_counter2 N c γ1 γ2 ∗ own γ2 (◯F 0%nat)
      }}}.
  Proof.
    rewrite /new_counter2.
    iIntros (Φ) "_ HΦ".
    wp_pures.
    iMod (flip_inv_create_spec) as "(%γ1 & #Hinv)".
    wp_alloc l as "Hl".
    iMod (own_alloc (●F 0%nat ⋅ ◯F 0%nat)) as "[%γ2[H5 H6]]".
    { by apply frac_auth_valid. }
    replace (#0) with (#0%nat) by done.
    iMod (inv_alloc _ _ (counter_inv_pred2 (#l) γ2) with "[$Hl $H5]") as "#Hinv'"; first done.
    iApply "HΦ".
    iFrame.
    iModIntro.
    iExists _. by iSplit.
  Qed.


  (** This lemma is not possible as only one view shift*)
  (* Lemma incr_counter_spec2 E N c γ1 γ2 γ3 (ε2:R -> nat -> R) (P: iProp Σ) (T: nat -> iProp Σ) (Q: nat->nat->iProp Σ): *)
  (*   ↑N ⊆ E-> *)
  (*   (∀ ε n, 0<= ε -> 0<= ε2 ε n)%R-> *)
  (*   (∀ (ε:R), 0<=ε -> ((ε2 ε 0%nat) + (ε2 ε 1%nat)+ (ε2 ε 2%nat)+ (ε2 ε 3%nat))/4 <= ε)%R → *)
  (*   {{{ inv N (counter_inv_pred2 c γ1 γ2 γ3) ∗ *)
  (*       □(∀ (ε:R) (n : nat), P ∗ ●↯ ε @ γ1 ={E∖↑N}=∗ (⌜(1<=ε2 ε n)%R⌝∨●↯ (ε2 ε n) @ γ1 ∗ T n) ) ∗ *)
  (*       □ (∀ (n z:nat), T n ∗ own γ3 (●F z) ={E∖↑N}=∗ *)
  (*                         own γ3 (●F(z+n)%nat)∗ Q z n) ∗ *)
  (*       P *)
  (*   }}} *)
  (*     incr_counter2 c @ E *)
  (*     {{{ (n:nat) (z:nat), RET (#z, #n); Q z n }}}. *)
  (* Proof. *)
  (*   iIntros (Hsubset Hpos Hineq Φ) "(#Hinv & #Hvs1 & #Hvs2 & HP) HΦ". *)
  (*   rewrite /incr_counter2. *)
  (*   wp_pures. *)
  (*   wp_bind (rand _)%E. *)
  (*   iInv N as ">(%ε & %m & %l & %z & H1 & H2 & H3 & H4 & -> & H5 & H6)" "Hclose". *)
  (*   (** cant do two view shifts! *) *)
  (* Abort. *)

  Lemma allocate_tape_spec2 N E c γ1 γ2:
    ↑N ⊆ E->
    {{{ is_counter2 N c γ1 γ2 }}}
      allocate_tape2 #() @ E
      {{{ (v:val), RET v;
          ∃ (α:loc), ⌜v=#lbl:α⌝ ∗ (flip_tapes_frag (L:=L) γ1 α (expander []) ∗ ⌜Forall (λ x, x<4) []⌝)
      }}}.
  Proof.
    iIntros (Hsubset Φ) "[#Hinv #Hinv'] HΦ".    
    rewrite /allocate_tape2.
    wp_pures.
    wp_apply flip_allocate_tape_spec; [by eapply nclose_subseteq'|done|..].
    iIntros (?) "(%&->&?)".
    iApply "HΦ".
    iFrame.
    iPureIntro. split; first done.
    by apply Forall_nil.
  Qed.
    
  Lemma incr_counter_tape_spec_some2 N E c γ1 γ2 (Q:nat->iProp Σ) (α:loc) n ns:
    ↑N⊆E ->
    {{{ is_counter2 N c γ1 γ2 ∗
        (flip_tapes_frag (L:=L) γ1 α (expander (n::ns)) ∗ ⌜Forall (λ x, x<4) (n::ns)⌝) ∗
        (  ∀ (z:nat), own γ2 (●F z) ={E∖↑N}=∗
                    own γ2 (●F (z+n)) ∗ Q z)
           
    }}}
      incr_counter_tape2 c #lbl:α @ E
                                  {{{ (z:nat), RET (#z, #n);
                                      (flip_tapes_frag (L:=L) γ1 α (expander ns) ∗ ⌜Forall (λ x, x<4) ns⌝) ∗ Q z }}}.
  Proof.
    iIntros (Hsubset Φ) "((#Hinv & #Hinv') & [Hα %] & Hvs) HΦ".
    rewrite /incr_counter_tape2.
    wp_pures.
    wp_apply (flip_tape_spec_some with "[$]") as "Hα".
    { by apply nclose_subseteq'. }
    wp_apply (conversion.wp_bool_to_int) as "_"; first done.
    wp_pures.
    wp_apply (flip_tape_spec_some with "[$]") as "Hα".
    { by apply nclose_subseteq'. }
    wp_apply (conversion.wp_bool_to_int) as "_"; first done.
    wp_pures.
    wp_bind (FAA _ _).
    iInv "Hinv'" as ">(%&%&->&?&?)" "Hclose".
    wp_faa. simpl.
    iMod (fupd_mask_subseteq (E ∖ ↑N)) as "Hclose'".
    { apply difference_mono; [done|by apply nclose_subseteq']. }
    iMod ("Hvs" with "[$]") as "[H6 HQ]".
    replace 2%Z with (Z.of_nat 2%nat) by done.
    replace (_*_+_)%Z with (Z.of_nat n); last first.
    { assert (n<4).
      - by eapply (@Forall_inv _ (λ x, x<4)).
      - by apply expander_eta.
    }
    replace (#(z+n)) with (#(z+n)%nat); last first.
    { by rewrite Nat2Z.inj_add. }
    iMod "Hclose'" as "_".
    iMod ("Hclose" with "[-HΦ HQ Hα]") as "_"; first by iFrame.
    iModIntro.
    wp_pures.
    iApply "HΦ".
    iFrame.
    iPureIntro.
    by eapply Forall_inv_tail.
  Qed.

  Lemma counter_presample_spec2 NS E T γ1 γ2 c α ns:
    ↑NS ⊆ E ->
    is_counter2 NS c γ1 γ2 -∗
    (flip_tapes_frag (L:=L) γ1 α (expander ns) ∗ ⌜Forall (λ x, x<4) ns⌝) -∗
    ( |={E∖↑NS,∅}=>
        ∃ ε ε2 num,
        ↯ ε ∗ 
        ⌜(∀ n, 0<=ε2 n)%R⌝ ∗
        ⌜(SeriesC (λ l, if bool_decide (l∈fmap (λ x, fmap (FMap:=list_fmap) fin_to_nat x) (enum_uniform_fin_list 3%nat num)) then ε2 l else 0%R) / (4^num) <= ε)%R⌝ ∗
      (∀ ns', ↯ (ε2 ns') ={∅,E∖↑NS}=∗
              T ε ε2 num ns'
      ))-∗ 
        wp_update E (∃ ε ε2 num ns', (flip_tapes_frag (L:=L) γ1 α (expander (ns++ns')) ∗ ⌜Forall (λ x, x<4) (ns++ns')⌝) ∗ T ε ε2 num ns').
  Proof.
  Admitted.
  (* Proof. *)
  (*   iIntros (Hsubset Hpos Hineq) "(#Hinv & #Hinv') #Hvs HP Hfrag". *)
  (*   iApply fupd_wp_update. *)
  (* Admitted. *)
  (*   iApply flip_presample_spec. *)
  (*   iApply wp_update_state_step_coupl. *)
  (*   iIntros (σ ε) "((Hheap&Htapes)&Hε)". *)
  (*   iMod (inv_acc with "Hinv") as "[>(% & % & % & % & H1 & H2 & H3 & H4 & -> & H5 & H6) Hclose]"; [done|]. *)
  (*   iDestruct (hocap_tapes_agree' with "[$][$]") as "%". *)
  (*   erewrite <-(insert_delete m) at 1; last done. *)
  (*   rewrite big_sepM_insert; last apply lookup_delete. *)
  (*   simpl. *)
  (*   iDestruct "H3" as "[Htape H3]". *)
  (*   iDestruct (tapeN_lookup with "[$][$]") as "(%&%&%H1)". *)
  (*   iDestruct (ec_supply_bound with "[$][$]") as "%". *)
  (*   iMod (ec_supply_decrease with "[$][$]") as (ε1' ε_rem -> Hε1') "Hε_supply". subst. *)
  (*   iApply fupd_mask_intro; [set_solver|]; iIntros "Hclose'". *)
  (*   iApply (state_step_coupl_iterM_state_adv_comp_con_prob_lang 2%nat); first done. *)
  (*   pose (f (l:list (fin 2)) := (match l with *)
  (*                                      | x::[x'] => 2*fin_to_nat x + fin_to_nat x' *)
  (*                                      | _ => 0 *)
  (*                                      end)). *)
  (*   unshelve iExists *)
  (*     (λ l, mknonnegreal (ε2 ε1' (f l) ) _). *)
  (*   { apply Hpos; simpl. auto. } *)
  (*   simpl. *)
  (*   iSplit. *)
  (*   { iPureIntro. *)
  (*     etrans; last apply Hineq; last auto. *)
  (*     pose (k:=(λ n, 1 / ((1 + 1) * ((1 + 1) * 1)) * ε2 ε1' (f n))%R). *)
  (*     erewrite (SeriesC_ext _ (λ x, if bool_decide (x ∈ enum_uniform_list 1%nat 2%nat) *)
  (*                                   then k x else 0%R))%R; last first. *)
  (*     - intros. case_bool_decide as K. *)
  (*       + rewrite elem_of_enum_uniform_list in K. by rewrite K /k. *)
  (*       + rewrite elem_of_enum_uniform_list in K. *)
  (*         case_match eqn:K'; [by rewrite Nat.eqb_eq in K'|done]. *)
  (*     - rewrite SeriesC_list; last apply NoDup_enum_uniform_list. *)
  (*       rewrite /k /=. rewrite SeriesC_nat_bounded'/=. lra. *)
  (*   } *)
  (*   iIntros (sample ?). *)
  (*   destruct (Rlt_decision (nonneg ε_rem + (ε2 ε1' (f sample)))%R 1%R) as [Hdec|Hdec]; last first. *)
  (*   { apply Rnot_lt_ge, Rge_le in Hdec. *)
  (*     iApply state_step_coupl_ret_err_ge_1. *)
  (*     simpl. simpl in *. lra. *)
  (*   } *)
  (*   iApply state_step_coupl_ret. *)
  (*   unshelve iMod (ec_supply_increase _ (mknonnegreal (ε2 ε1' (f sample)) _) with "Hε_supply") as "[Hε_supply Hε]". *)
  (*   { apply Hpos. apply cond_nonneg. } *)
  (*   { simpl. done. } *)
  (*   assert (Nat.div2 (f sample)<2)%nat as K1. *)
  (*   { rewrite Nat.div2_div. apply Nat.Div0.div_lt_upper_bound. rewrite /f. *)
  (*     simpl. repeat case_match; try lia. pose proof fin_to_nat_lt t. pose proof fin_to_nat_lt t0. lia. *)
  (*   } *)
  (*   rewrite -H1. *)
  (*   iMod (tapeN_update_append _ _ _ _ (nat_to_fin K1) with "[$][$]") as "[Htapes Htape]". *)
  (*   assert (Nat.b2n (Nat.odd (f sample))<2)%nat as K2. *)
  (*   { edestruct (Nat.odd _); simpl; lia.  } *)
  (*   rewrite -(list_fmap_singleton (fin_to_nat)) -fmap_app. *)
  (*   iMod (tapeN_update_append _ _ _ _ (nat_to_fin K2) with "[$][$]") as "[Htapes Htape]". *)
  (*   iMod (hocap_tapes_presample' _ _ _ _ _ (f sample) with "[$][$]") as "[H4 Hfrag]". *)
  (*   iMod "Hclose'" as "_". *)
  (*   iMod ("Hvs" with "[$]") as "[%|[H2 HT]]". *)
  (*   { iExFalso. iApply (ec_contradict with "[$]"). exact. } *)
  (*   rewrite insert_insert. *)
  (*   rewrite fmap_app -!app_assoc /=. *)
  (*   assert (([nat_to_fin K1;nat_to_fin K2]) = sample) as K. *)
  (*   { destruct sample as [|x xs]; first done. *)
  (*     destruct xs as [|x' xs]; first done. *)
  (*     destruct xs as [|]; last done. *)
  (*     pose proof fin_to_nat_lt x. pose proof fin_to_nat_lt x'. *)
  (*     repeat f_equal; apply fin_to_nat_inj; rewrite fin_to_nat_to_fin. *)
  (*     - rewrite /f. rewrite Nat.div2_div. *)
  (*       rewrite Nat.mul_comm Nat.div_add_l; last lia. rewrite Nat.div_small; lia. *)
  (*     - rewrite /f. rewrite Nat.add_comm Nat.odd_add_even. *)
  (*       + destruct (fin_to_nat x') as [|[|]]; simpl; lia. *)
  (*       + by econstructor. *)
  (*   } *)
  (*   iMod ("Hclose" with "[$Hε $H2 Htape H3 $H4 $H5 $H6]") as "_". *)
  (*   { iNext. iSplit; last done. *)
  (*     rewrite big_sepM_insert_delete; iFrame. *)
  (*     simpl. rewrite !fin_to_nat_to_fin. *)
  (*     rewrite /expander bind_app -/(expander ns). simpl. by rewrite H1. *)
  (*   } *)
  (*   iApply fupd_mask_intro_subseteq; first set_solver. *)
  (*   rewrite K. *)
  (*   iFrame. *)
  (* Qed. *)

  Lemma read_counter_spec2 N E c γ1 γ2 Q:
    ↑N ⊆ E ->
    {{{  is_counter2 N c γ1 γ2 ∗
         (∀ (z:nat), own γ2 (●F z) ={E∖↑N}=∗
                    own γ2 (●F z) ∗ Q z)
        
    }}}
      read_counter2 c @ E
      {{{ (n':nat), RET #n'; Q n'
      }}}.
  Proof.
    iIntros (Hsubset Φ) "((#Hinv & #Hinv') & Hvs) HΦ".
    rewrite /read_counter2.
    wp_pure.
    iInv "Hinv'" as ">(%l&%z  & -> & Hloc & Hcont)" "Hclose".
    wp_load.
    iMod (fupd_mask_subseteq (E ∖ ↑N)) as "Hclose'".
    { apply difference_mono_l. by apply nclose_subseteq'. }
    iMod ("Hvs" with "[$]") as "[Hcont HQ]".
    iMod "Hclose'".
    iMod ("Hclose" with "[ $Hloc $Hcont]"); first done.
    iApply "HΦ". by iFrame.
  Qed.
  
End impl2.

Program Definition counterG2_to_flipG `{conerisGS Σ, !flip_spec, !counterG2 Σ} : flipG Σ.
Proof.
  eapply counterG2_flipG.
Qed.
  
Program Definition random_counter2 `{flip_spec Σ}: random_counter :=
  {| new_counter := new_counter2;
    allocate_tape:= allocate_tape2;
    incr_counter_tape := incr_counter_tape2;
    read_counter:=read_counter2;
    counterG := counterG2;
    tape_name := flip_tape_name;
    counter_name :=gname;
    is_counter _ N c γ1 γ2 := is_counter2 N c γ1 γ2;
    counter_tapes_auth K γ m := (flip_tapes_auth (L:=counterG2_to_flipG) γ ((λ ns, expander ns)<$>m) ∗ ⌜map_Forall (λ _ ns, Forall (λ x, x<4) ns) m⌝)%I;
    counter_tapes_frag K γ α ns := (flip_tapes_frag (L:=counterG2_to_flipG) γ α (expander ns) ∗ ⌜Forall (λ x, x<4) ns⌝)%I;
    counter_content_auth _ γ z := own γ (●F z);
    counter_content_frag _ γ f z := own γ (◯F{f} z);
    new_counter_spec _ := new_counter_spec2;
    allocate_tape_spec _ :=allocate_tape_spec2;
    incr_counter_tape_spec_some _ :=incr_counter_tape_spec_some2;
    counter_presample_spec _ :=counter_presample_spec2;
    read_counter_spec _ :=read_counter_spec2
  |}.
Next Obligation.
  simpl.
  iIntros (???????) "[H1 ?] [H2 ?]".
  iApply (flip_tapes_auth_exclusive with "[$][$]").
Qed.
Next Obligation.
  simpl.
  iIntros (????????) "[??] [??]".
  iApply (flip_tapes_frag_exclusive with "[$][$]").
Qed.
Next Obligation.
  simpl.
  iIntros (????????) "[Hauth %H0] [Hfrag %]".
  iDestruct (flip_tapes_agree γ α ((λ ns0 : list nat, expander ns0) <$> m) (expander ns) with "[$][$]") as "%K".
  iPureIntro.
  rewrite lookup_fmap_Some in K. destruct K as (?&K1&?).
  replace ns with x; first done.
  apply expander_inj; try done.
  by eapply map_Forall_lookup_1 in H0.
Qed.
Next Obligation.
  simpl.
  iIntros (???????) "[? %]".
  iPureIntro.
  eapply Forall_impl; first done.
  simpl. lia.
Qed.
Next Obligation.
  simpl.
  iIntros (??????????) "[H1 %] [H2 %]".
  iMod (flip_tapes_update with "[$][$]") as "[??]".
  iFrame.
  iModIntro.
  rewrite fmap_insert. iFrame.
  iPureIntro. split.
  - apply map_Forall_insert_2; last done.
    eapply Forall_impl; first done. simpl; lia.
  - eapply Forall_impl; first done.
    simpl; lia.
Qed.
Next Obligation.
  simpl.
  iIntros (???????) "H1 H2".
  iCombine "H1 H2" gives "%K". by rewrite auth_auth_op_valid in K.
Qed.
Next Obligation.
  simpl. iIntros (????? z z' ?) "H1 H2".
  iCombine "H1 H2" gives "%K".
  apply frac_auth_included_total in K. iPureIntro.
  by apply nat_included.
Qed.
Next Obligation.
  simpl.
  iIntros (?????????).
  rewrite frac_auth_frag_op. by rewrite own_op.
Qed.
Next Obligation.
  simpl. iIntros (???????) "H1 H2".
  iCombine "H1 H2" gives "%K".
  iPureIntro.
  by apply frac_auth_agree_L in K.
Qed.
Next Obligation.
  simpl. iIntros (?????????) "H1 H2".
  iMod (own_update_2 _ _ _ (_ ⋅ _) with "[$][$]") as "[$$]"; last done.
  apply frac_auth_update.
  apply nat_local_update. lia.
Qed.
