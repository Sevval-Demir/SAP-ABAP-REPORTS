*&---------------------------------------------------------------------*
*& Report  Z_ODEV_004
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  Z_ODEV_004.

PARAMETERS:
p_num1 TYPE i OBLIGATORY,
p_num2 TYPE i OBLIGATORY.

DATA:
gs_a TYPE i VALUE 1,
gs_count TYPE i VALUE 0.

IF p_num1 >= 1 AND p_num1 <= 100 AND p_num2 >= 1 AND p_num2 <= 9.

  WHILE gs_a <= p_num1.
    WRITE: gs_a.
    gs_count = gs_count + 1.

    IF gs_count MOD p_num2 = 0.
      SKIP.
    ENDIF.
    gs_a = gs_a + 1.
  ENDWHILE.
ELSE.

  WRITE: 'Geçersiz sayı girdiniz.'.

ENDIF.
