*&---------------------------------------------------------------------*
*& Report  Z_OPENSQL
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  Z_OPENSQL.

DATA: gv_malzno TYPE matnr,
      gv_malztur type zmtart2,
      gv_malgrub type zmatkl2,
      gv_eskimalzno type bismt,
      gv_teolbrm type meins,
      gv_brutagr type brgew,
      gv_netagr type ntgew,
      gv_agrbrm type gewei,
      gs_malzmast type zmt_malzeme,
      gt_malzmast type TABLE OF zmt_malzeme.

*select * from zmt_malzeme into table gt_malzmast. "bütün tabloyu çekme
*
*select single * from zmt_malzeme into gs_malzmast. "tablo içindeki structure gösterme
*
*select single malzeme_no from zmt_malzeme into gv_malzno. "tablodaki bir satırdaki değişkeni gösterme
*
*select * from zmt_malzeme into table gt_malzmast where mal_grubu eq 'mek'. "mal grubundaki mek yazan tablo içindeki değişkeni getir
*
*update zmt_malzeme set brut_agirlik = '250,000' where malzeme_no = 'VIDA-001'.
*
*insert zmt_malzeme from gs_malzmast. "yeni veri ekleme yapar.
*
**gs_malzmast- ctrl+space yapıldığı zaman değişken isimleri gelir
*
*delete zmt_malzeme where net_agirlik  eq '320,000'.
*
*" modify -> update ve insert birleşimi şeklimnde çalışır
*
*modify zmt_malzeme from gs_malzmast. " o key de bir satır varsa update olarak çalışır, yoksa insert olarak çalışır.
