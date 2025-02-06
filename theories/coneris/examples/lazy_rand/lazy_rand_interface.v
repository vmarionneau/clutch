From clutch.coneris Require Import coneris .

Set Default Proof Using "Type*".

Class lazy_rand `{!conerisGS Σ} (val_size:nat):= Lazy_Rand
{
  (** * Operations *)
  init_lazy_rand : val;
  allocate_tape : val;
  lazy_read_rand : val;
  (** * Ghost state *)
  rand_tape_gname: Type;
  rand_view_gname: Type;
  rand_lock_gname:Type;
  
  (** * Predicates *)
  rand_inv (N:namespace) (c: val) (P: option (nat*nat) -> iProp Σ) {HP: ∀ n, Timeless (P n)} 
    (γ:rand_tape_gname) (γ':rand_view_gname) (γ_lock:rand_lock_gname): iProp Σ; 
  rand_tape_frag (α:val) (n:option nat) (γ:rand_tape_gname): iProp Σ;
  rand_tape_auth (m:gmap val (option nat)) (γ:rand_tape_gname) :iProp Σ; 
  rand_auth (m:option (nat*nat)) (γ:rand_view_gname) : iProp Σ;
  rand_frag (res:nat) (tid:nat) (γ:rand_view_gname) : iProp Σ; 
  
  (** * General properties of the predicates *)
  #[global] rand_tape_frag_timeless α ns γ::
    Timeless (rand_tape_frag α ns γ); 
  #[global] rand_tape_auth_timeless m γ::
    Timeless (rand_tape_auth m γ);
  #[global] rand_auth_timeless n γ::
    Timeless (rand_auth n γ);  
  #[global] rand_frag_timeless n tid γ::
    Timeless (rand_frag n tid γ); 
  rand_tape_frag_valid α ns γ:
    rand_tape_frag α (Some ns) γ-∗ ⌜(ns<=val_size)%nat⌝;  
  
  #[global] rand_inv_persistent N c P {HP: ∀ n, Timeless (P n)} γ_tape γ_view γ_lock ::
    Persistent (rand_inv N c P γ_tape γ_view γ_lock); 
  (* #[global] rand_frag_persistent v res γ :: *)
  (*   Persistent (rand_frag v res γ); *)
  
  rand_tape_frag_exclusive α ns ns' γ:
    rand_tape_frag α ns γ-∗ rand_tape_frag α ns' γ-∗ False; 
  (* rand_tape_auth_exclusive m m' γ: *)
  (*   rand_tape_auth m γ -∗ rand_tape_auth m' γ -∗ False; *)
  rand_tape_auth_frag_agree m α ns γ:
  rand_tape_auth m γ  -∗ rand_tape_frag α ns γ -∗ ⌜m!!α=Some ns⌝;
                                                        
  rand_auth_exclusive n n' γ:
    rand_auth n γ -∗ rand_auth n' γ -∗ False; 
  rand_auth_frag_agree n n' tid γ:
    rand_auth n γ -∗ rand_frag n' tid γ -∗ ⌜n=Some (n', tid)⌝; 
  rand_auth_duplicate n γ:
     rand_auth (Some n) γ -∗ rand_auth (Some n) γ ∗ rand_frag n.1 n.2 γ;
  rand_frag_frag_agree v1 v2 tid1 tid2 γ :
    rand_frag v1 tid1 γ -∗ rand_frag v2 tid2 γ-∗ ⌜v1=v2∧tid1=tid2⌝; 

                                                        
  (* rand_tape_auth_alloc m α γ: *)
  (*   m!!α=None -> rand_tape_auth m γ ==∗ rand_tape_auth (<[α:=[]]> m) γ ∗ rand_tape α [] γ; *)
  rand_tape_presample N c P {HP:∀ n, Timeless (P n)} γ γ_view γ_lock E m α ε (ε2:fin (S val_size) -> R):
    ↑(N.@"rand")⊆E ->
    (∀ x, (0 <= ε2 x)%R)->
    (SeriesC (λ n : fin (S val_size), 1 / S val_size * ε2 n) <= ε)%R ->
    rand_inv N c P γ γ_view γ_lock -∗
    rand_tape_auth m γ -∗ rand_tape_frag α None γ -∗ ↯ ε -∗
    state_update E E (∃ n, 
          ↯ (ε2 n) ∗
          rand_tape_auth (<[α:=Some (fin_to_nat n)]>m) γ ∗
          rand_tape_frag α (Some (fin_to_nat n)) γ); 
  (* rand_auth_exclusive m m' γ: *)
  (*   rand_auth m γ -∗ rand_auth m' γ -∗ False; *)
  (* rand_frag_frag_agree k v1 v2 γ : *)
  (*   rand_frag k v1 γ -∗ rand_frag k v2 γ -∗ ⌜v1=v2⌝; *)
  (* rand_auth_duplicate_frag m k v γ: *)
  (*   m!!k=Some v -> rand_auth m γ -∗ rand_frag k v γ; *)
  (* rand_auth_insert m k v γ: *)
  (*   m!!k=None -> rand_auth m γ ==∗ (rand_auth (<[k:=v]> m) γ ∗ rand_frag k v γ); *)
                      

  lazy_rand_presample N c P {HP: ∀ n, Timeless (P n)} γ γ_view γ_lock Q
    E  :
  ↑(N.@"tape") ⊆ E ->
  rand_inv N c P γ γ_view γ_lock -∗
  (∀ m,  rand_tape_auth m γ -∗
         state_update (E∖↑(N.@"tape")) (E∖↑(N.@"tape"))
           (∃ m', rand_tape_auth m' γ ∗ Q m m')
    ) -∗
    state_update E E (
        ∃ m m', Q m m'
      ); 

  lazy_rand_init N P {HP: ∀ n, Timeless (P n)} :
    {{{ P None }}}
      init_lazy_rand #()
      {{{ (c:val), RET c;
          ∃ γ γ_view γ_lock, 
              rand_inv N c P γ γ_view γ_lock }}}; 

  lazy_rand_alloc_tape N c P {HP: ∀ n, Timeless (P n)} γ_tape γ_view γ_lock Q:
  {{{ rand_inv N c P γ_tape γ_view γ_lock ∗
      (∀ (m:gmap val (option nat)) α, ⌜α∉dom m⌝ -∗ |={⊤∖↑N.@"tape"}=> Q α)
  }}}
      allocate_tape #()
      {{{ (α: val), RET α; rand_tape_frag α None γ_tape ∗ Q α }}};    
  
  lazy_rand_spec N c P {HP: ∀ n, Timeless (P n)} γ_tape γ_view γ_lock Q1 Q2 α (v:nat) (tid:nat):
  {{{ rand_inv N c P γ_tape γ_view γ_lock ∗
      ( ∀ n m, P n -∗ rand_auth n γ_view -∗ rand_tape_auth m γ_tape -∗ state_update (⊤∖↑N.@"tape") (⊤∖↑N.@"tape")
             match n with
             | Some (res, tid') => P n ∗ rand_auth n γ_view ∗ rand_tape_auth m γ_tape ∗ Q1 res tid'
             | None => ∃ n', rand_tape_frag α (Some n') γ_tape ∗ rand_tape_auth (<[α:=Some n']> m) γ_tape ∗
                              ( rand_tape_frag α None γ_tape
                                      ={⊤∖↑N.@"tape"}=∗  P (Some (n', tid)) ∗ rand_auth (Some (n', tid)) γ_view ∗ Q2 n' tid)
             end                                        
      )
  }}}
      lazy_read_rand c α #tid
      {{{ (res' tid':nat), RET (#res', #tid')%V;  (Q1 res' tid' ∨
                                                   Q2 res' tid'
                                )
      }}};
}.
