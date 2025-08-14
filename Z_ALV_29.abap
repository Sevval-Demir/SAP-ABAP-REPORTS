*&---------------------------------------------------------------------*
*& Report  Z_ALV_29
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  Z_ALV_29.

*data: gt_sbook type table of sbook,
*      go_salv type ref to  cl_salv_table.
*
*START-OF-SELECTION.
*
*  select * up to 20 rows from sbook
*    into table gt_sbook.
*
*  cl_salv_table=>FACTORY(
*  IMPORTING
*    r_salv_table = go_salv
*    changing
*      t_table = gt_sbook
*  ).
*
*  go_salv->display( ).


data: gt_sbook type table of sbook,
      go_salv type ref to  cl_salv_table.

START-OF-SELECTION.

  select * up to 20 rows from sbook
    into table gt_sbook.

  cl_salv_table=>FACTORY(
  IMPORTING
    r_salv_table = go_salv
    changing
      t_table = gt_sbook
  ).

  data: lo_display type ref to cl_salv_display_settings.

  lo_display = go_salv->get_display_settings( ).
  lo_display->SET_LIST_HEADER( value = 'SALV Eğitim Videosu' ).
  lo_display->SET_STRIPED_PATTERN( value = 'X' ).

  data: lo_cols type ref to cl_salv_columns.

  lo_cols = go_salv->GET_COLUMNS( ).
  lo_cols->SET_OPTIMIZE( value = 'X' ).

  data: lo_col type ref to cl_salv_column.

  TRY.
      lo_col = lo_cols->GET_COLUMN( COLUMNNAME = 'INVOICE' ).
      lo_col->SET_LONG_TEXT('Yeni Fatura Düzenleyici').
      lo_col->SET_MEDIUM_TEXT('Yeni Fatura D.').
      lo_col->SET_SHORT_TEXT('Ye Fa. D.').
    CATCH cx_salv_not_found.
  ENDTRY.


  try.
      lo_col = lo_cols->GET_COLUMN( columnname = 'MANDT' ).
      lo_col->set_visible(
      value = IF_SALV_C_BOOL_SAP=>FALSE
      ).
    catch cx_salv_not_found.
  endtry.

  data: lo_func type ref to cl_salv_functions.

  lo_func = go_salv->GET_FUNCTIONS( ).
  lo_func->SET_ALL( abap_true ).

  data: lo_header type ref to CL_SALV_FORM_LAYOUT_GRID,
        lo_h_label type ref to cl_salv_form_label,
        lo_h_flow type ref to cl_salv_form_layout_flow.

  CREATE OBJECT lo_header.

  LO_H_LABEL = LO_HEADER->create_label( row = 1 column = 1 ).
  LO_H_LABEL->set_text( value = 'Başlık İlk Satır' ).
  LO_H_FLOW = LO_HEADER->CREATE_FLOW( row = 2 column = 1 ).
  LO_H_FLOW->CREATE_TEXT(
  EXPORTING
    text = 'Başlık İkinci Satır'
    ).
  go_salv->SET_TOP_OF_LIST( value = lo_header ).

  go_salv->set_screen_popup(
  EXPORTING
    start_column = 10
    end_column = 75
    start_line = 5
    end_line = 25
 ).

  go_salv->display( ).
