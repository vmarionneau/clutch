From clutch.coneris Require Import coneris .

Set Default Proof Using "Type*".

Class con_hash1 `{!conerisGS Σ} (val_size:nat):= Con_Hash1
{
  (** * Operations *)
  init_hash1 : val;
  (* incr_counter : val; *)
  allocate_tape1 : val;
  compute_hash1 : val;
  (** * Ghost state *)
  
  (** [name] is used to associate [locked] with [is_lock] *)
  (* tape_name: Type; *)
  
  hash_view_gname:Type;
  hash_set_gname:Type;
  hash_tape_gname: Type;
  hash_lock_gname:Type;
  
  (** * Predicates *)
  con_hash_inv1 (N:namespace) (f l hm: val) (P:gmap nat nat -> gmap val (list nat) -> iProp Σ) {HP: ∀ m m', Timeless (P m m')}  (R:gmap nat nat -> iProp Σ) {HR: ∀ m, Timeless (R m )} (γ1:hash_view_gname) (γ2: hash_set_gname) (γ3:hash_tape_gname) (γ_lock:hash_lock_gname): iProp Σ;
  (* concrete_seq_hash {L:seq_hashG Σ} (f:val) (m:gmap nat nat) : iProp Σ;  *)
  hash_tape1 (α:val) (ns:list nat) (γ2: hash_set_gname) (γ3:hash_tape_gname): iProp Σ;
  hash_tape_auth1 (m:gmap val (list nat)) (γ2 :hash_set_gname) (γ3:hash_tape_gname): iProp Σ;
  hash_auth1 (m:gmap nat nat) (γ:hash_view_gname) (γ2 : hash_set_gname): iProp Σ;
  hash_frag1 (v res:nat) (γ:hash_view_gname) (γ2 : hash_set_gname): iProp Σ;
  hash_set1 (s: gset nat) (γ2:hash_set_gname) : iProp Σ;
  hash_set_frag1 (n:nat) (γ2:hash_set_gname) : iProp Σ;
  
  (** * General properties of the predicates *)
  (* #[global] concrete_seq_hash_timeless {L : seq_hashG Σ} f m :: *)
  (*   Timeless (concrete_seq_hash (L:=L) f m); *)
  #[global] hash_tape_timeless α ns γ2 γ3::
    Timeless (hash_tape1 α ns γ2 γ3);
  #[global] hash_tape_auth_timeless m γ2 γ3::
    Timeless (hash_tape_auth1 m γ2 γ3);
  #[global] hash_auth_timeless m γ γ2::
    Timeless (hash_auth1 m γ γ2);
  #[global] hash_frag_timeless v res γ γ2::
    Timeless (hash_frag1 v res γ γ2);
  #[global] hash_set_timeless s γ2 ::
    Timeless (hash_set1 s γ2); 
  #[global] hash_set_frag_timeless s γ2 ::
    Timeless (hash_set_frag1 s γ2); 
  #[global] con_hash_inv_persistent N f l hm γ1 γ2 γ3 P {HP: ∀ m m', Timeless (P m m')} R {HR: ∀ m, Timeless (R m )}  γ_lock ::
    Persistent (con_hash_inv1 N f l hm P R γ1 γ2 γ3 γ_lock); 
  #[global] hash_frag_persistent v res γ γ2::
    Persistent (hash_frag1 v res γ γ2);
  #[global] hash_set_frag_persistent s γ2 ::
    Persistent (hash_set_frag1 s γ2); 
  hash_auth_exclusive m m' γ γ2:
    hash_auth1 m γ γ2 -∗ hash_auth1 m' γ γ2 -∗ False;
  hash_auth_frag_agree m k v γ γ2:
    hash_auth1 m γ γ2 -∗ hash_frag1 k v γ γ2 -∗ ⌜m!!k=Some v⌝;
  hash_auth_duplicate m k v γ γ2:
    m!!k=Some v -> hash_auth1 m γ γ2 -∗ hash_frag1 k v γ γ2;
  hash_frag_frag_agree k v1 v2 γ γ2:
    hash_frag1 k v1 γ γ2 -∗ hash_frag1 k v2 γ γ2-∗ ⌜v1=v2⌝; 
  hash_frag_in_hash_set γ1 γ2 v res:
    hash_frag1 v res γ1 γ2 -∗ hash_set_frag1 res γ2 ;
  hash_tape_in_hash_set α ns γ γ':
  hash_tape1 α ns γ γ' -∗ [∗ list] n ∈ ns, hash_set_frag1 n γ;
  hash_set_duplicate x s γ:
  x∈s -> hash_set1 s γ -∗ hash_set_frag1 x γ;
  hash_set_frag_in_set s n γ:
  hash_set1 s γ -∗ hash_set_frag1 n γ -∗ ⌜n ∈ s⌝;
  hash_auth_insert m k v γ1 γ2:
    m!!k=None -> hash_set_frag1 v γ2 -∗ hash_auth1 m γ1 γ2 ==∗ hash_auth1 (<[k:=v]> m ) γ1 γ2;
  (* hash_tape_auth_exclusive m m' γ2 γ3: *)
  (*   hash_tape_auth1 m γ2 γ3 -∗ hash_tape_auth1 m' γ2 γ3 -∗ False; *)
  hash_tape_auth_frag_agree m α ns γ2 γ3:
    hash_tape_auth1 m γ2 γ3 -∗ hash_tape1 α ns γ2 γ3 -∗ ⌜m!!α=Some ns⌝;
  (* hash_tape_auth_insert m α γ2 γ3: *)
  (*   m!!α=None -> hash_tape_auth1 m γ2 γ3 ==∗ hash_tape_auth1 (<[α:=[]]> m) γ2 γ3 ∗ hash_tape1 α [] γ2 γ3; *)
  (* hash_tape_auth_frag_update m α ns n γ2 γ3: *)
  (* hash_set_frag1 n γ2 -∗ hash_tape_auth1 m γ2 γ3 -∗ hash_tape1 α ns γ2 γ3 ==∗ *)
  (* hash_tape_auth1 (<[α:=ns++[n]]> m) γ2 γ3 ∗ hash_tape1 α (ns ++ [n]) γ2 γ3; *)
  hash_set_valid s γ:
    hash_set1 s γ -∗ ⌜∀ n, n∈s -> (n<=val_size)%nat⌝;
  hash_tape_valid α ns γ2 γ3:
    hash_tape1 α ns γ2 γ3-∗ ⌜Forall (λ x, x<=val_size)%nat ns⌝; 
  hash_tape_exclusive α ns ns' γ2 γ3:
      hash_tape1 α ns γ2 γ3-∗ hash_tape1 α ns' γ2 γ3 -∗ False;

  
  hash_tape_presample N f l hm P {HP: ∀ m m', Timeless (P m m')} R {HR: ∀ m, Timeless (R m )}  m γ_hv γ_set γ γ_lock α ns s (ε εI εO:nonnegreal) E:
  ↑(N.@"rand")⊆E ->
  (εI * (size s) + εO * (val_size + 1 - size s) <= ε * (val_size + 1))%R ->
  con_hash_inv1 N f l hm P R γ_hv γ_set γ γ_lock -∗
    hash_tape_auth1 m γ_set γ -∗ hash_tape1 α ns γ_set γ -∗ ↯ ε -∗
    hash_set1 s γ_set -∗
    state_update E E (∃ (n:fin(S val_size)), 
          ( (⌜fin_to_nat n ∈ s⌝) ∗ hash_set1 s γ_set ∗ ↯ εI  ∨
            (⌜fin_to_nat n ∉ s⌝) ∗ hash_set1 (s∪{[(fin_to_nat n)]}) γ_set ∗ ↯ εO
          )∗
          hash_tape_auth1 (<[α:=ns++[fin_to_nat n]]>m) γ_set γ ∗
          hash_tape1 α (ns++[fin_to_nat n]) γ_set γ
      ); 

  con_hash_presample1  N f l hm P {HP: ∀ m m', Timeless (P m m')} R {HR: ∀ m, Timeless (R m )} γ_hv γ_set γ_tape γ_lock Q
    E  :
    ↑(N.@"hash") ⊆ E ->
    con_hash_inv1 N f l hm P R γ_hv γ_set γ_tape γ_lock -∗
    (∀ m m', P m m'  -∗
             hash_tape_auth1 m' γ_set γ_tape -∗
             state_update (E∖↑(N.@"hash")) (E∖↑(N.@"hash"))
             (∃ m'', P m m'' ∗ hash_tape_auth1 m'' γ_set γ_tape ∗ Q m m' m'')
    ) -∗
    state_update E E (
        ∃ m m' m'', Q m m' m''
      ) ;

  con_hash_init1 N P {HP: ∀ m m', Timeless (P m m')} R {HR: ∀ m, Timeless (R m )} :
    {{{ P ∅ ∅ ∗ R ∅}}}
      init_hash1 #()
      {{{ (f:val), RET f; ∃ l hm γ1 γ2 γ3 γ_lock, con_hash_inv1 N f l hm P R γ1 γ2 γ3 γ_lock ∗
                                                  hash_set1 ∅ γ2
      }}}; 

  con_hash_alloc_tape1 N f l hm P {HP: ∀ m m', Timeless (P m m')} R {HR: ∀ m, Timeless (R m )} γ1 γ2 γ3 γ_lock Q:
  {{{ con_hash_inv1 N f l hm P R γ1 γ2 γ3 γ_lock ∗
      (∀ m m' α, P m m' -∗ ⌜α∉dom m'⌝ -∗ |={⊤∖↑N.@"hash"}=> P m (<[α:=[]]>m') ∗ Q α)
  }}}
      allocate_tape1 #()
      {{{ (α: val), RET α; hash_tape1 α [] γ2 γ3 ∗ Q α }}}; 

  con_hash_spec1 N f l hm P {HP: ∀ m m', Timeless (P m m')} R {HR: ∀ m, Timeless (R m )} γ1 γ2 γ3 γ_lock Q1 Q2 α (v:nat):
  {{{ con_hash_inv1 N f l hm P R γ1 γ2 γ3 γ_lock ∗ 
      ( ∀ m m', R m -∗ P m m' -∗ hash_tape_auth1 m' γ2 γ3 -∗ hash_auth1 m γ1 γ2 -∗ state_update (⊤∖↑N.@"hash") (⊤∖↑N.@"hash")
             match m!!v with
             | Some res => R m ∗ P m m' ∗ hash_auth1 m γ1 γ2 ∗ hash_tape_auth1 m' γ2 γ3 ∗ Q1 res
             | None => ∃ n ns, hash_tape1 α (n::ns) γ2 γ3 ∗ P m (<[α:=n::ns]> m') ∗ hash_tape_auth1 (<[α:=n::ns]> m') γ2 γ3 ∗
                              (∀ m'', P m m'' -∗  ⌜m''!!α=Some (n::ns)⌝
                                      ={⊤∖↑N.@"hash"}=∗ R (<[v:=n]> m) ∗ P (<[v:=n]> m) (<[α:=ns]> m'') ∗
                                      hash_auth1 (<[v:=n]> m) γ1 γ2  ∗ Q2 n ns)
             end                                        
      )
  }}}
      f #v α
      {{{ (res:nat), RET (#res);  (Q1 res ∨
                                 ∃ n ns, hash_tape1 α ns γ2 γ3 ∗ ⌜res=n⌝ ∗ Q2 n ns
                                )
      }}}

}.

Section test.
  Context `{conerisGS Σ, !con_hash1 val_size}.

  Lemma con_hash_presample_test N f l hm γ1 γ2 γ3 γlock  E (ε εI εO:nonnegreal) ns α s :
    ↑N⊆E ->
    (εI * (size s) + εO * (val_size + 1 - size s) <= ε * (val_size + 1))%R ->
    con_hash_inv1 N f l hm (λ _ _, True) (λ _, True )γ1 γ2 γ3 γlock -∗
    hash_tape1 α ns γ2 γ3 -∗
    ↯ ε -∗
    hash_set1 s γ2 -∗
    state_update E E (∃ (n:fin (S val_size)),
          hash_tape1 α (ns++[fin_to_nat n]) γ2 γ3 ∗
          ( (⌜fin_to_nat n ∈ s⌝) ∗ hash_set1 s γ2 ∗ ↯ εI ∨
            (⌜fin_to_nat n ∉ s⌝) ∗ hash_set1 (s∪{[(fin_to_nat n)]}) γ2 ∗ ↯ εO
          )
      ).
  Proof.
    iIntros (Hsubset Hineq) "#Hinv Ht Herr Hs".
    iMod (con_hash_presample1 _ _ _ _ _ _ _ _ _ _
            (λ m m' m'', (∃ n : fin (S val_size), hash_tape1 α (ns ++ [fin_to_nat n]) γ2 γ3 ∗
                                                  (⌜fin_to_nat n ∈ s⌝ ∗ hash_set1 s γ2 ∗ ↯ εI ∨ ⌜fin_to_nat n ∉ s⌝ ∗ hash_set1 (s ∪ {[fin_to_nat n]}) γ2 ∗ ↯ εO)))%I with "[//][-]") as "Hcont".
    - by apply nclose_subseteq'.
    - iIntros (_ ?) "_ Hauth".
      iMod (hash_tape_presample with "[//][$][$][$][$]") as "(%&?&$&$)".
      + apply subseteq_difference_r; last by apply nclose_subseteq'.
        by apply ndot_ne_disjoint.
      + done.
      + by iFrame.
    - iDestruct "Hcont" as "(%&%&%&%&$&[(%&?&?)|(%&?&?)])"; iModIntro; [iLeft|iRight]; by iFrame.
  Qed.
  
    
  Lemma con_hash_spec_test1 N f l hm γ1 γ2 γ3 γlock α n ns (v:nat):
    {{{ con_hash_inv1 N f l hm (λ _ _, True) (λ _, True) γ1 γ2 γ3 γlock ∗ hash_tape1 α (n::ns) γ2 γ3 }}}
      f #v α
      {{{ (res:nat), RET (#res);  hash_frag1 v res γ1 γ2 ∗
                                (hash_tape1 α ns γ2 γ3 ∗ ⌜res=n⌝ ∨
                                 hash_tape1 α (n::ns) γ2 γ3
                                )
      }}}.
  Proof.
    iIntros (Φ) "[#Hinv Ht] HΦ".
    iDestruct (hash_tape_in_hash_set with "[$]") as "#Hfrag".
    iApply (con_hash_spec1 _ _ _ _ _ _ _ _ _ _ (λ res, hash_frag1 v res γ1 γ2 ∗ hash_tape1 α _ _ _)%I (λ n' ns', ⌜n=n'⌝ ∗ ⌜ns'=ns⌝ ∗ hash_frag1 v n γ1 γ2)%I with "[$Hinv Ht]").
    - iIntros (??) "_ _ Htauth Hauth ".
      case_match.
      + iDestruct (hash_auth_duplicate with "[$]") as "#$"; first done. by iFrame.
      + iDestruct (hash_tape_auth_frag_agree with "[$][$]") as "%H'".
        iFrame. iModIntro.
        iSplit; first done.
        rewrite insert_id; last done.
        iFrame.  
        iMod (hash_auth_insert with "[][$]") as "H"; first done; last first.
        * iDestruct (hash_auth_duplicate with "[$]") as "#$"; first by rewrite lookup_insert.
          iFrame. by iIntros. 
        * rewrite big_sepL_cons. iDestruct "Hfrag" as "[$ ?]".        
    - iNext. iIntros (res) "[[??]|(%&%&?&->&->&->&?)]".
      + iApply "HΦ". iFrame.
      + iApply "HΦ". simplify_eq. iFrame.  iLeft. by iFrame.
  Qed.

  Lemma con_hash_spec_hashed_before1 N f l hm γ1 γ2 γ3 γlock α ns res (v:nat):
    {{{ con_hash_inv1 N f l hm (λ _ _, True) (λ _, True) γ1 γ2 γ3 γlock ∗ hash_tape1 α ns γ2 γ3 ∗ hash_frag1 v res γ1 γ2 }}}
      f #v α
      {{{ RET (#res);  hash_frag1 v res γ1 γ2 ∗
                       (hash_tape1 α ns γ2 γ3 )
      }}}.
  Proof. 
    iIntros (Φ) "(#Hinv & Ht & #Hf) HΦ".
    iDestruct (hash_tape_in_hash_set with "[$]") as "#Hfrag".
    iApply (con_hash_spec1 _ _ _ _ _ _ _ _ _ _ (λ res' , ⌜res=res'⌝ ∗ hash_frag1 v res γ1 γ2 ∗ hash_tape1 α _ _ _)%I (λ _ _, ⌜False⌝)%I with "[$Hinv Ht]").
    - iIntros (??) "_ _ Htauth Hauth".
      case_match.
      + iDestruct (hash_auth_frag_agree with "[$][$]") as "%".
        simplify_eq. iDestruct (hash_auth_duplicate with "[$]") as "#$"; first done. by iFrame.
      + iDestruct (hash_auth_frag_agree with "[$][$]") as "%".
        simplify_eq.
    - iNext. iIntros (res') "[(->&?&?)|(%&%&?&%&[])]".
      iApply "HΦ". iFrame.
  Qed.
  
End test.
