*&---------------------------------------------------------------------*
*& Report  Z_PERS_BLG
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  Z_PERS_BLG.

TABLES: zmt_personel,zpers_iletisim,zpers_aile,zpers_egitim.

"Personel numarası arama
SELECT-OPTIONS: s_perno FOR zmt_personel-personel_no MATCHCODE OBJECT zsh_personel.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

PARAMETERS:
p_rad1 RADIOBUTTON GROUP grp DEFAULT 'X', "Master Bilgisi
p_rad2 RADIOBUTTON GROUP grp, "İletişim Bilgisi
p_rad3 RADIOBUTTON GROUP grp, "Aile Bilgisi
p_rad4 RADIOBUTTON GROUP grp. "Eğitim Bilgisi

SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  IF p_rad1 = 'X'.
    PERFORM yaz_master_bilgisi.
  ELSEIF p_rad2 = 'X'.
    PERFORM yaz_iletisim_bilgisi.
  ELSEIF p_rad3 = 'X'.
    PERFORM yaz_aile_bilgisi.
  ELSEIF p_rad4 = 'X'.
    PERFORM yaz_egitim_bilgisi.
  ENDIF.


FORM yaz_master_bilgisi.

  TYPES: BEGIN OF ty_master,
           perno         TYPE zmt_personel-personel_no,
           adi           TYPE zmt_personel-ad,
           soyadi        TYPE zmt_personel-soyad,
           cinsiyet_kod  TYPE zmt_personel-cinsiyet,
           dogum_yeri    TYPE zmt_personel-dogum_yeri,
           dogum_tarihi  TYPE zmt_personel-dogum_tarihi,
           medeni_kod    TYPE zmt_personel-medeni_hali,
           cocuk_sayisi  TYPE zmt_personel-cocuk_sayisi,
           ulke_kodu     TYPE zmt_personel-uyruk,
         END OF ty_master.

  DATA: lt_master TYPE TABLE OF ty_master,
        ls_master TYPE ty_master,
        lv_last_perno TYPE zmt_personel-personel_no.

  SELECT personel_no
       ad
       soyad
       cinsiyet     AS cinsiyet_kod
       dogum_yeri
       dogum_tarihi
       medeni_hali  AS medeni_kod
       cocuk_sayisi
       uyruk        AS ulke_kodu
  INTO TABLE lt_master
  FROM zmt_personel
  WHERE personel_no IN s_perno.

  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'Perno', 10 'Adı', 25 'Soyadı', 45 'Cinsiyet', 60 'Medeni Hali', 75 'Uyruk'.
  ULINE.

  CLEAR lv_last_perno.

  LOOP AT lt_master INTO ls_master.

    " Zebra görünüm
    IF sy-tabix MOD 2 = 0.
      FORMAT INTENSIFIED OFF.
    ELSE.
      FORMAT INTENSIFIED ON.
    ENDIF.

    " Personel no tekrar etmesin
    IF lv_last_perno NE ls_master-perno.
      WRITE: / ls_master-perno, 10 ls_master-adi, 25 ls_master-soyadi,
              45 ls_master-cinsiyet_kod, 60 ls_master-medeni_kod, 75 ls_master-ulke_kodu.
      lv_last_perno = ls_master-perno.
    ELSE.
      WRITE: / space, 10 ls_master-adi, 25 ls_master-soyadi,
              45 ls_master-cinsiyet_kod, 60 ls_master-medeni_kod, 75 ls_master-ulke_kodu.
    ENDIF.

  ENDLOOP.

ENDFORM.

FORM yaz_iletisim_bilgisi.

  TYPES: BEGIN OF ty_iletisim,
         perno type zpers_iletisim-personel_no,
         ile_turu type zpers_iletisim-iletisim_turu,
         ile_tanitici type zpers_iletisim-iletisim_tanitici,
         ile_taniticiuzun type zpers_iletisim-iletisim_tanitici_uzun,
         END OF ty_iletisim.

  DATA: lt_iletisim type table of ty_iletisim,
        ls_iletisim type ty_iletisim,
        lv_last_perno type zpers_iletisim-personel_no.

  SELECT personel_no
         iletisim_turu
          iletisim_tanitici
            iletisim_tanitici_uzun
    into table lt_iletisim
    from zpers_iletisim
    where personel_no in s_perno.

  format color col_heading intensified on.
  write: / 'Personel Numrası',10 'İletişim Türü',25 'İletişim Tanıtıcısı',45'İletişim Tanıtıcısı Uzun'.
  uline.

  clear lv_last_perno.

  loop at lt_iletisim into ls_iletisim.

    "Zebra görünüm.
    if sy-tabix mod 2 = 0.
      format INTENSIFIED off.
    else.
      format intensified on.
    endif.

    if lv_last_perno ne ls_iletisim-perno.
      write: / ls_iletisim-perno,10 ls_iletisim-ile_turu,25 ls_iletisim-ile_tanitici,45 ls_iletisim-ile_taniticiuzun.
      lv_last_perno = ls_iletisim-perno.
    else.
      write: / space,10 ls_iletisim-ile_turu,25 ls_iletisim-ile_tanitici,45 ls_iletisim-ile_taniticiuzun.
    endif.
  endloop.
ENDFORM.

form yaz_aile_bilgisi.

  types:  begin of ty_aile,
            perno type zpers_aile-personel_no,
            aile_taniticino type zpers_aile-ailetanitici_no,
             aile_ad type zpers_aile-ad,
              aile_soyad type zpers_aile-soyad,
                aile_telefon type zpers_aile-telefon,
                  aile_sokak type zpers_aile-sokak,
                    aile_il type zpers_aile-il,
                      aile_ulke type zpers_aile-ulke,
    end of ty_aile.

  data: lt_aile type table of ty_aile,
        ls_aile type ty_aile,
        lv_last_perno type zpers_aile-personel_no.

  select personel_no
    ailetanitici_no
      ad
    soyad
    telefon
    sokak
    il
    ulke
    into table lt_aile
    from zpers_aile
    where personel_no in s_perno.

  format color col_heading intensified on.
  write: / 'Personel Numarası', 20 'Aile Tanıtıcı No',40 'Aile Ad',55 'Aile Soyad',70 'Aile Sokak',85 'Aile İl',95 'Aile Ulke'.
  uline.

  clear lv_last_perno.

  loop at lt_aile into ls_aile.

    if sy-tabix mod 2 = 0.
      format intensified off.
    else.
      format intensified on.
    endif.
    if lv_last_perno ne ls_aile-perno.
      write: / ls_aile-perno,10 ls_aile-aile_taniticino,20 ls_aile-aile_ad,40 ls_aile-aile_soyad,55 ls_aile-aile_telefon,70 ls_aile-aile_sokak,85 ls_aile-aile_il,95 ls_aile-aile_ulke.
      lv_last_perno = ls_aile-perno.
    else.
      write: / space,10 ls_aile-aile_taniticino,20 ls_aile-aile_ad,40 ls_aile-aile_soyad, 55 ls_aile-aile_telefon,70 ls_aile-aile_sokak,85 ls_aile-aile_il,95 ls_aile-aile_ulke.
    endif.
  endloop.
endform.

form yaz_egitim_bilgisi .

  types: begin of ty_egitim,
    perno type zpers_egitim-personel_no,
    egitim_kodu type zpers_egitim-egitim_kodu,
    okul_adi type zpers_egitim-okul_adi,
    il type zpers_egitim-il,
    ulke type zpers_egitim-ulke,

    end of ty_egitim.

  data: lt_egitim type table of ty_egitim,
        ls_egitim type ty_egitim,
        lv_last_perno type zpers_egitim-personel_no.

  select personel_no
    egitim_kodu
    okul_adi
    il
    ulke
    into table lt_egitim
    from zpers_egitim
    where personel_no in s_perno.

  format color col_heading intensified on.
  write: / 'Personel Numarası',20 'Eğitim Kodu',35 'Okul Adı',70 'Eğitim İli',90 'Eğitim Ülke'.
  uline.

  clear lv_last_perno.

  loop at lt_egitim into ls_egitim.

    if sy-tabix mod 2 = 0.
      format intensified off.
    else.
      format intensified on.
    endif.
    if lv_last_perno ne ls_egitim-perno.
      write: / ls_egitim-perno,20 ls_egitim-egitim_kodu,35 ls_egitim-okul_adi,65 ls_egitim-il,80 ls_egitim-ulke.
      lv_last_perno = ls_egitim-perno.
    else.
      write: / space, 10 ls_egitim-egitim_kodu,35 ls_egitim-okul_adi,65 ls_egitim-il,80 ls_egitim-ulke.
    endif.
  endloop.

endform.
