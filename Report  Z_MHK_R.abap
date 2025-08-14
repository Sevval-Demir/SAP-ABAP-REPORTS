*&---------------------------------------------------------------------*
*& Report  Z_MHK_R  - Malzeme Hareketleri Kırılım Raporu
*&---------------------------------------------------------------------*
REPORT z_mhk_r.

TABLES: mara, mkpf, mseg.
"mara = malzeme basic data
"mkpf = malzeme belge başlığı
"mseg = malzeme belge kalemi
TYPE-POOLS: vrm. "seçim ekranındaki listboxları vrm_set_values ile doldurulur
TYPE-POOLS: slis.
TABLES: SSCRFIELDS. "sscrfields ile seçim ekranı butonu

TYPES: ty_coltext TYPE c LENGTH 50.
"field catalogda kolon başlıpı gibi yerlerde kullanılan 50 karakterlik kısa metin tipi


SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS:
  s_mblnr FOR mkpf-mblnr, "Belge Numarası
  s_mjahr FOR mkpf-mjahr, "Belge Yılı
  s_blart FOR mkpf-blart, "Belge Türü
  s_bldat FOR mkpf-bldat. "Belge Tarihi
SELECTION-SCREEN END OF BLOCK b1.
"select options aralık seçimi yapar

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.
SELECT-OPTIONS:
  s_matnr FOR mseg-matnr, "Malzeme Numarası
  s_bwart FOR mseg-bwart, "Hareket Türü
  s_werks FOR mseg-werks, "Üretim Yeri
  s_lgort FOR mseg-lgort, "Depo Yeri
  s_charg FOR mseg-charg, "Parti No
  s_sakto FOR mseg-sakto. "Ana Hesap No
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE text-003.
PARAMETERS:
  p_kir1 TYPE char20 AS LISTBOX VISIBLE LENGTH 25,
  p_kir2 TYPE char20 AS LISTBOX VISIBLE LENGTH 25. "iki kırılım alanı as listbox sayesinde
SELECTION-SCREEN END OF BLOCK b3.                  " vrm ile dinamik doldurulur.

SELECTION-SCREEN FUNCTION KEY 1. "kaydet butonu

TYPE-POOLS: lvc.
"satır indeksi tespitinde kullanılacak lvc tiplerini sağlar
DATA: lt_vals TYPE vrm_values,
      ls_val  TYPE vrm_value.
"vrm_set_values a verilecek seçenek listesi için veri yapıları

AT SELECTION-SCREEN OUTPUT.
  PERFORM fill_kir_listboxes. "outputtan önce listbox değerleri doldurulur
  "ekran açıldığında ilk kullanıcı bir şey seçmeden önce doldurulur
  SSCRFIELDS-FUNCTXT_01 = 'Kaydet'.

AT SELECTION-SCREEN.
  IF sy-ucomm = 'ONLI'. "kullanıcı run tuşuna bastığı zaman iki kırılım aynı anda seçilemez
    IF p_kir1 IS NOT INITIAL AND p_kir2 = p_kir1.
      CLEAR p_kir2.
      MESSAGE 'İki kırılım değeri aynı olamaz.' TYPE 'E'.
    ENDIF.
  ENDIF.


START-OF-SELECTION.

  TYPES: BEGIN OF ty_list,
           mblnr TYPE mkpf-mblnr,
           blart TYPE mkpf-blart,
           bldat TYPE mkpf-bldat,
           mjahr TYPE mkpf-mjahr,
           matnr TYPE mseg-matnr,
           bwart TYPE mseg-bwart,
           werks TYPE mseg-werks,
           lgort TYPE mseg-lgort,
           charg TYPE mseg-charg,
           sakto TYPE mseg-sakto,
           zeile type mseg-zeile, "mseg kalem numarası
           stok type CHAR1,  "stok kontrolü
           erfmg TYPE mseg-erfmg, "Miktar
           erfme TYPE mseg-erfme, "Ölçü Birimi
           dmbtr TYPE mseg-dmbtr, "Tutar
           waers TYPE mseg-waers, "Para Birimi
           shkzg TYPE mseg-shkzg, "Stok hareketi
         END OF ty_list.
  "mkpf+mseg den okunan tekil satırlar

  DATA: gt_list TYPE STANDARD TABLE OF ty_list WITH DEFAULT KEY, "raporun ham verisi
        gs_list TYPE ty_list.

  " Özet tablo: Kırılım(1-2) + PB + ÖB bazında toplama
  TYPES: BEGIN OF ty_sum,
           kir1       TYPE char30,
           kir1_text  TYPE char30, "kırılımların dil bazlı açıklamaları
           kir2       TYPE char30,
           kir2_text  TYPE char30,
           waers      TYPE mseg-waers,
           dmbtr      TYPE mseg-dmbtr,
           erfme      TYPE mseg-erfme,
           erfmg      TYPE mseg-erfmg,
         END OF ty_sum.
  "kırılımlar ve metin karşılıkları

  DATA: gt_sum TYPE STANDARD TABLE OF ty_sum WITH DEFAULT KEY,"özet ekranının veri kaynağı
        gs_sum TYPE ty_sum.

  " ALV alan kataloğu / layout
  DATA: gt_fcat      TYPE slis_t_fieldcat_alv,
        gs_layo      TYPE slis_layout_alv,
        gt_fcat_sum  TYPE slis_t_fieldcat_alv, "her kolonun adını,başlığını,birim/para bağını/toplam davra
        gs_layo_sum  TYPE slis_layout_alv.

  " Ekran modu: 'S' (Summary) / 'D' (Detail)
  DATA: g_mode TYPE c VALUE 'S'. "ilk açılışta özet ekran

  " Özet satırından seçilen anahtarlar → detayı süzmek için
  DATA: g_s_kir1  TYPE char30,
        g_s_kir2  TYPE char30,
        g_s_waers TYPE mseg-waers,
        g_s_erfme TYPE mseg-erfme.
  "kullanıcı özet satırına çift tıkladığı zaman o satırın kırılım değeri

  " Detay veri seti
  DATA: gt_detail TYPE STANDARD TABLE OF ty_list WITH DEFAULT KEY,
        gs_detail TYPE ty_list.
  "özet satırından seçilen bağlama göre filtreleyip doldurulan detay alv tablosu

  types: begin of ty_stok,
    malzeme_belgesi type mblnr,
    yil type mjahr,
    kalem type mblpo,
    stok_kaydi type char1,
    end of ty_stok.

  DATA: gt_stok TYPE HASHED TABLE OF zmhk_t
      WITH UNIQUE KEY malzeme_belgesi yil kalem.


  if SSCRFIELDS-ucomm = 'FC01'.
    if gt_detail is INITIAL.
      MESSAGE 'Kaydedilecek detay verisi yok' TYPE 'S'.
    else.
      perform save_stok.
    endif.
    clear SSCRFIELDS-ucomm.
  endif.


  PERFORM get_data. "okuma işi yapılıyor
  IF gt_list IS INITIAL.
    MESSAGE 'Seçim kriterlerine uyan kayıt bulunamadı.' TYPE 'S'.
    EXIT.
  ENDIF.

  PERFORM build_summary. "gt_list içindeki detayları,seçilen kırılımlar+pb+öb eksenine toplayıp gt_sum içine yazılıyor
  PERFORM build_fieldcat_sum.
  PERFORM tweak_headers CHANGING gt_fcat_sum.
  PERFORM display_sum.

FORM fill_kir_listboxes.
  CLEAR lt_vals.

  CLEAR ls_val. ls_val-key = 'BLART'. ls_val-text = 'Belge Türü (BLART)'.  APPEND ls_val TO lt_vals.
  CLEAR ls_val. ls_val-key = 'MATNR'. ls_val-text = 'Malzeme No (MATNR)'.  APPEND ls_val TO lt_vals.
  CLEAR ls_val. ls_val-key = 'BWART'. ls_val-text = 'Hareket Türü (BWART)'.APPEND ls_val TO lt_vals.
  CLEAR ls_val. ls_val-key = 'WERKS'. ls_val-text = 'Üretim Yeri (WERKS)'. APPEND ls_val TO lt_vals.
  CLEAR ls_val. ls_val-key = 'LGORT'. ls_val-text = 'Depo Yeri (LGORT)'.   APPEND ls_val TO lt_vals.
  CLEAR ls_val. ls_val-key = 'CHARG'. ls_val-text = 'Parti No (CHARG)'.    APPEND ls_val TO lt_vals.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_KIR1'
      values = lt_vals.
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_KIR2'
      values = lt_vals.
ENDFORM.

FORM get_data.
  REFRESH gt_list.

  SELECT
      a~mblnr a~blart a~bldat a~mjahr
      b~matnr b~bwart b~werks b~lgort b~charg b~sakto
      b~erfmg b~erfme b~dmbtr b~waers b~shkzg
      b~zeile
    INTO CORRESPONDING FIELDS OF TABLE gt_list
    FROM mseg AS b
    INNER JOIN mkpf AS a
      ON  b~mblnr = a~mblnr
      AND b~mjahr = a~mjahr
    INNER JOIN mara AS c
      ON  b~matnr = c~matnr
      WHERE a~mblnr IN s_mblnr
        AND a~mjahr IN s_mjahr
        AND a~blart IN s_blart
        AND a~bldat IN s_bldat
        AND b~matnr IN s_matnr
        AND b~bwart IN s_bwart
        AND b~werks IN s_werks
        AND b~lgort IN s_lgort
        AND b~charg IN s_charg
        AND b~sakto IN s_sakto.

SELECT malzeme_belgesi
       yil
       kalem
       stok_kaydi
  INTO CORRESPONDING FIELDS OF TABLE gt_stok
  FROM zmhk_t
  WHERE malzeme_belgesi IN s_mblnr
    AND yil IN s_mjahr.

ENDFORM.



FORM get_kir USING    p_key TYPE char20 "hangi alan
                      ps    TYPE ty_list "detay satırı
             CHANGING p_val TYPE char30.
  DATA lv_key TYPE char20.
  CLEAR p_val.
  lv_key = p_key.
  TRANSLATE lv_key TO UPPER CASE.

  CASE lv_key.
    WHEN 'BLART'. p_val = ps-blart.
    WHEN 'MATNR'. p_val = ps-matnr.
    WHEN 'BWART'. p_val = ps-bwart.
    WHEN 'WERKS'. p_val = ps-werks.
    WHEN 'LGORT'. p_val = ps-lgort.
    WHEN 'CHARG'. p_val = ps-charg.
    WHEN OTHERS.  CLEAR p_val.
  ENDCASE.
ENDFORM.
"seçilen kırılım anahtara karşılık ty_list içindeki alan atanıyor

* seçilen kırılım değeri için dil-bazlı tanım
"get_kir için dil bazlı açıklama bulmak
FORM get_text_for USING    p_key    TYPE char20
                           p_val    TYPE char30
                           p_werks  TYPE mseg-werks
                  CHANGING p_text   TYPE char30.

  DATA lv_key TYPE char20.
  CLEAR p_text.
  lv_key = p_key.
  TRANSLATE lv_key TO UPPER CASE.

  CASE lv_key.
    WHEN 'BLART'.
      SELECT SINGLE ltext INTO p_text FROM t003t
       WHERE spras = sy-langu AND blart = p_val.
    WHEN 'MATNR'.
      SELECT SINGLE maktx INTO p_text FROM makt
       WHERE spras = sy-langu AND matnr = p_val.
    WHEN 'BWART'.
      SELECT SINGLE btext INTO p_text FROM t156t
       WHERE spras = sy-langu AND bwart = p_val.
    WHEN 'WERKS'.
      SELECT SINGLE name1 INTO p_text FROM t001w
       WHERE werks = p_val.
    WHEN 'LGORT'.
      IF p_werks IS INITIAL.
        SELECT SINGLE lgobe INTO p_text FROM t001l
         WHERE lgort = p_val.
      ELSE.
        SELECT SINGLE lgobe INTO p_text FROM t001l
         WHERE werks = p_werks AND lgort = p_val.
      ENDIF.
    WHEN 'CHARG'.
      CLEAR p_text. "Parti no için ayrı tanım yok
    WHEN OTHERS.
      CLEAR p_text.
  ENDCASE.
ENDFORM.

* Özet COLLECT ile PB/ÖB bazında toplama
FORM build_summary.
  DATA: lv_k1 TYPE char30, lv_k2 TYPE char30,
        lv_t1 TYPE char30, lv_t2 TYPE char30.

  REFRESH gt_sum.

  LOOP AT gt_list INTO gs_list.
    " Kırılım değerleri
    PERFORM get_kir USING p_kir1 gs_list CHANGING lv_k1.
    IF p_kir2 IS INITIAL.
      CLEAR lv_k2.
    ELSE.
      PERFORM get_kir USING p_kir2 gs_list CHANGING lv_k2.
    ENDIF.

    " Kırılım tanımları dil bazlı
    PERFORM get_text_for USING p_kir1 lv_k1 gs_list-werks CHANGING lv_t1.
    IF p_kir2 IS INITIAL.
      CLEAR lv_t2.
    ELSE.
      PERFORM get_text_for USING p_kir2 lv_k2 gs_list-werks CHANGING lv_t2.
    ENDIF.

    CLEAR gs_sum.
    gs_sum-kir1      = lv_k1.
    gs_sum-kir1_text = lv_t1.
    gs_sum-kir2      = lv_k2.
    gs_sum-kir2_text = lv_t2.

    gs_sum-waers = gs_list-waers.
    gs_sum-erfme = gs_list-erfme.

    " Toplanacak alanlar
    gs_sum-dmbtr = gs_list-dmbtr.
    gs_sum-erfmg = gs_list-erfmg.

    COLLECT gs_sum INTO gt_sum.
  ENDLOOP.
ENDFORM.


FORM build_fieldcat_sum.
  REFRESH gt_fcat_sum.
  PERFORM add_field USING 'KIR1'      'Kırılım1'  ' ' CHANGING gt_fcat_sum.
  PERFORM add_field USING 'KIR1_TEXT' 'Tanım'     ' ' CHANGING gt_fcat_sum.
  PERFORM add_field USING 'KIR2'      'Kırılım2'  ' ' CHANGING gt_fcat_sum.
  PERFORM add_field USING 'KIR2_TEXT' 'Tanım'     ' ' CHANGING gt_fcat_sum.
  PERFORM add_field USING 'DMBTR'     'Değer'     'X' CHANGING gt_fcat_sum.
  PERFORM add_field USING 'WAERS'     'PB'        ' ' CHANGING gt_fcat_sum.
  PERFORM add_field USING 'ERFME'     'ÖB'        ' ' CHANGING gt_fcat_sum.
  PERFORM add_field USING 'ERFMG'     'Miktar'    'X' CHANGING gt_fcat_sum.
ENDFORM.

FORM add_field USING    p_fieldname TYPE slis_fieldname
                        p_coltext   TYPE ty_coltext
                        p_do_sum    TYPE c
               CHANGING pt_fcat     TYPE slis_t_fieldcat_alv.
  DATA ls_fcat TYPE slis_fieldcat_alv.
  CLEAR ls_fcat.

  ls_fcat-fieldname = p_fieldname.
  ls_fcat-seltext_m = p_coltext.

  IF p_fieldname = 'KIR1_TEXT' OR p_fieldname = 'KIR2_TEXT'.
    ls_fcat-hotspot = 'X'.
  ENDIF.

  IF p_do_sum = 'X'.
    ls_fcat-do_sum = 'X'.
  ENDIF.

  APPEND ls_fcat TO pt_fcat.
ENDFORM.

FORM tweak_headers CHANGING pt_fcat TYPE slis_t_fieldcat_alv.
  DATA ls TYPE slis_fieldcat_alv.
  LOOP AT pt_fcat INTO ls.
    CASE ls-fieldname.
      WHEN 'KIR1'.      ls-seltext_m = 'Kırılım1'.
      WHEN 'KIR1_TEXT'. ls-seltext_m = 'Tanım'.
      WHEN 'KIR2'.      ls-seltext_m = 'Kırılım2'.
      WHEN 'KIR2_TEXT'. ls-seltext_m = 'Tanım'.
      WHEN 'DMBTR'.     ls-seltext_m = 'Değer'.
      WHEN 'WAERS'.     ls-seltext_m = 'PB'.
      WHEN 'ERFME'.     ls-seltext_m = 'ÖB'.
      WHEN 'ERFMG'.     ls-seltext_m = 'Miktar'.
    ENDCASE.
    MODIFY pt_fcat FROM ls.
  ENDLOOP.
ENDFORM.

* Özet ALV

FORM display_sum.
  CLEAR gs_layo_sum.
  gs_layo_sum-zebra = 'X'.
  gs_layo_sum-colwidth_optimize = 'X'.

  g_mode = 'S'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      it_fieldcat             = gt_fcat_sum
      is_layout               = gs_layo_sum
      i_callback_user_command = 'USER_COMMAND'
    TABLES
      t_outtab                = gt_sum
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
ENDFORM.


FORM build_detail_from_selection.
  REFRESH gt_detail.

  LOOP AT gt_list INTO gs_list.
    IF gs_list-waers = g_s_waers AND gs_list-erfme = g_s_erfme.

      " Kırılım1 filtresi
      IF g_s_kir1 IS NOT INITIAL.
        DATA lv_k1 TYPE char30.
        PERFORM get_kir USING p_kir1 gs_list CHANGING lv_k1.
        IF lv_k1 <> g_s_kir1.
          CONTINUE.
        ENDIF.
      ENDIF.

      " Kırılım2 filtresi
      IF g_s_kir2 IS NOT INITIAL.
        DATA lv_k2 TYPE char30.
        PERFORM get_kir USING p_kir2 gs_list CHANGING lv_k2.
        IF lv_k2 <> g_s_kir2.
          CONTINUE.
        ENDIF.
      ENDIF.

      read table gt_stok with TABLE KEY
      malzeme_belgesi = gs_list-mblnr
      yil = gs_list-mjahr
      kalem = gs_list-zeile
      transporting no fields.

      if sy-subrc = 0.
        gs_list-stok = 'X'.
      else.
        clear gs_list-stok.
      endif.

      APPEND gs_list TO gt_detail.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM add_field_det USING    p_field TYPE slis_fieldname
                            p_text  TYPE ty_coltext
                            p_kind  TYPE c       " 'C' = currency, 'Q' = quantity
                            p_ref   TYPE slis_fieldname.

  DATA ls TYPE slis_fieldcat_alv.
  CLEAR ls.

  ls-fieldname = p_field.
  ls-seltext_m = p_text.
  ls-outputlen = 20.

  " Para/ölçü birimi bağlaması
  CASE p_kind.
    WHEN 'C'.  ls-cfieldname = p_ref.   " DMBTR -> WAERS
    WHEN 'Q'.  ls-qfieldname = p_ref.   " ERFMG -> ERFME
  ENDCASE.

  APPEND ls TO gt_fcat.
ENDFORM.



FORM build_fieldcat_detail.
  REFRESH gt_fcat.


  PERFORM add_field_det USING 'MBLNR' 'Belge No'     ' ' ''.
  PERFORM add_field_det USING 'MJAHR' 'Yıl'          ' ' ''.
  PERFORM add_field_det USING 'MATNR' 'Malzeme No'   ' ' ''.
  PERFORM add_field_det USING 'ERFMG' 'Miktar'       'Q' 'ERFME'.  " Quantity -> ÖB alanı
  PERFORM add_field_det USING 'ERFME' 'ÖB'           ' ' ''.
  PERFORM add_field_det USING 'DMBTR' 'Tutar'        'C' 'WAERS'.  " Currency -> PB alanı
  PERFORM add_field_det USING 'WAERS' 'PB'           ' ' ''.
  PERFORM add_field_det USING 'BWART' 'Hareket Tr'   ' ' ''.
  PERFORM add_field_det USING 'SHKZG' 'B/A'          ' ' ''.
  PERFORM add_field_det USING 'WERKS' 'Üretim Yeri'  ' ' ''.
  PERFORM add_field_det USING 'LGORT' 'Depo Yeri'    ' ' ''.
  PERFORM add_field_det USING 'CHARG' 'Parti No'     ' ' ''.
  PERFORM add_field_det USING 'BLART' 'Belge Türü'   ' ' ''.
  perform add_field_det using 'MBLNR' 'Malzeme Belgesi' ' ' ''.
  perform add_field_det using 'MJAHR' 'Yıl' ' ' ''.
  perform add_field_det using 'ZEILE' 'Kalem' ' ' ''.
  PERFORM add_field_det using 'STOK' 'Stok' ' ' ''.

  data ls type SLIS_FIELDCAT_ALV.
  loop at gt_fcat into ls.
    if ls-FIELDNAME = 'STOK'.
      ls-edit = 'X'.
      ls-CHECKBOX = 'X'.
      ls-OUTPUTLEN = 10.
      modify gt_fcat from ls.
    endif.
  ENDLOOP.


ENDFORM.

FORM display_detail.
  CLEAR gs_layo.
  gs_layo-zebra = 'X'.
  gs_layo-colwidth_optimize = 'X'.
  gs_layo-EDIT = 'X'.
  PERFORM build_fieldcat_detail.

  g_mode = 'D'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      it_fieldcat             = gt_fcat
      is_layout               = gs_layo
      i_callback_user_command = 'USER_COMMAND'
    TABLES
      t_outtab                = gt_detail
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
ENDFORM.

FORM user_command USING r_ucomm     LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

  DATA: lv_index TYPE sy-tabix.

  IF r_ucomm = '&IC1'.

    lv_index = rs_selfield-tabindex.


    IF lv_index IS INITIAL.
      DATA lr_grid TYPE REF TO cl_gui_alv_grid.
      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          e_grid = lr_grid.
      IF lr_grid IS BOUND.
        DATA ls_row TYPE lvc_s_row.
        DATA ls_col TYPE lvc_s_col.
        CALL METHOD lr_grid->get_current_cell
          IMPORTING
            es_row_id = ls_row
            es_col_id = ls_col.
        lv_index = ls_row-index.

      ENDIF.
    ENDIF.

    IF g_mode = 'S'.
      " Özet satırından detaya inme
      DATA ls_sum TYPE ty_sum.
      READ TABLE gt_sum INTO ls_sum INDEX lv_index.
      IF sy-subrc = 0.
        g_s_kir1  = ls_sum-kir1.
        g_s_kir2  = ls_sum-kir2.
        g_s_waers = ls_sum-waers.
        g_s_erfme = ls_sum-erfme.

        PERFORM build_detail_from_selection.

        " Ekranı stabil tut / yenile
        rs_selfield-row_stable = 'X'.
        rs_selfield-col_stable = 'X'.
        rs_selfield-refresh    = 'X'.

        PERFORM display_detail.
        EXIT.
      ENDIF.

    ELSEIF g_mode = 'D'.
      " Detay satırından MB03’e git
      READ TABLE gt_detail INTO gs_detail INDEX lv_index.
      IF sy-subrc = 0.
        SET PARAMETER ID 'MBN' FIELD gs_detail-mblnr.
        SET PARAMETER ID 'MJA' FIELD gs_detail-mjahr.
        CALL TRANSACTION 'MB03' AND SKIP FIRST SCREEN.
      ENDIF.
    ENDIF.
  ENDIF.

  if g_mode = 'D'
    and ( r_ucomm = '&F03' or R_UCOMM = 'BACK'
    or r_ucomm = '&F12' or r_ucomm = 'Cancel'
    or r_ucomm = 'EXIT' or r_ucomm = '&F15' ) .

    CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
      IMPORTING
        e_grid = lr_grid.
    if lr_grid is BOUND.
      CALL METHOD lr_grid->check_changed_data.
    endif.
    return.
  endif.
ENDFORM.

form save_stok.

  data: ls_db type zmhk_t.

  loop at gt_detail into gs_detail.

    clear ls_db.
    ls_db-malzeme_belgesi = gs_detail-mblnr.
    ls_db-yil = gs_detail-mjahr.
    ls_db-kalem = gs_detail-zeile.
    if gs_detail-stok = 'X'.
      ls_db-stok_kaydi = 'X'.
    else.
      clear ls_db-stok_kaydi.
    endif.

    if ls_db-stok_kaydi = 'X'.
      update zmhk_t from ls_db.
      IF sy-subrc <> 0.
        INSERT zmhk_t FROM ls_db.
      ENDIF.
    ELSE.
      " X kaldırıldıysa kaydı sil
      DELETE FROM zmhk_t
        WHERE malzeme_belgesi = ls_db-malzeme_belgesi
          AND yil             = ls_db-yil
          AND kalem           = ls_db-kalem.
    ENDIF.

  ENDLOOP.

  COMMIT WORK.
  MESSAGE 'Stok kaydı işaretleri ZMHK_T tablosuna kaydedildi.' TYPE 'S'.

  "bir sonraki detaya inişte güncel görünsün
  REFRESH gt_stok.
  SELECT malzeme_belgesi
         yil
         kalem
         stok_kaydi
    INTO TABLE gt_stok
    FROM zmhk_t
    WHERE malzeme_belgesi IN s_mblnr
      AND yil             IN s_mjahr.

ENDFORM.
