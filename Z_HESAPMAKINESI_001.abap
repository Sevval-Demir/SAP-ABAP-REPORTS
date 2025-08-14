*&---------------------------------------------------------------------*
*& Report  Z_HESAPMAKINESI_001
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  Z_HESAPMAKINESI_001.

PARAMETERS: p_num1 TYPE i OBLIGATORY,
            p_num2 TYPE i OBLIGATORY,
            rb_add RADIOBUTTON GROUP grp DEFAULT 'X',
            rb_sub RADIOBUTTON GROUP grp,
            rb_mul RADIOBUTTON GROUP grp,
            rb_div RADIOBUTTON GROUP grp.

DATA:       gv_result TYPE p DECIMALS 2,
            gv_metin TYPE string,
            gv_kalan TYPE i.

START-OF-SELECTION.

IF rb_add = 'X'.
gv_metin = 'Toplam = '.
gv_result = p_num1 + p_num2.
WRITE: gv_metin,gv_result.

ELSEIF rb_sub = 'X'.
gv_metin = 'Çıkarma = '.
gv_result = p_num1 - p_num2.
WRITE: gv_metin,gv_result.

ELSEIF rb_mul = 'X'.
gv_metin = 'Çarpma = '.
gv_result = p_num1 * p_num2.
WRITE: gv_metin,gv_result.

ELSEIF rb_div = 'X'.
IF p_num2 = 0.
WRITE: 'Sıfıra bölme yapılamaz'.
ELSE.
gv_metin = 'Bölme = '.
gv_result = p_num1 / p_num2.
WRITE: gv_metin, gv_result.
gv_kalan = p_num1 MOD p_num2.
WRITE: 'Kalan = ' ,gv_kalan.
ENDIF.
ENDIF.
*
*CASE 'X'.
*
*    WHEN rb_add.
*       gv_metin = 'Toplam: '.
*       gv_result = p_num1 + p_num2.
*       WRITE: gv_metin,gv_result.
*
*    WHEN rb_sub.
*       gv_metin = 'Çıkarma: '.
*       gv_result = p_num1 - p_num2.
*       WRITE: gv_metin,gv_result.
*
*    WHEN rb_mul.
*       gv_metin = 'Çarpma: '.
*       gv_result = p_num1 * p_num2.
*       WRITE: gv_metin,gv_result.
*
*    WHEN rb_div.
*      gv_metin = 'Bölme: '.
*      IF p_num2 = 0
*      WRITE: 'Bölme yapılamaz.'.
*      ELSE.
*      gv_metin = 'Bölme : '.
*      gv_result = p_num1 / p_num2.
*      WRITE: gv_metin,gv_result.
*      gv_kalan = p_num1 MOD p_num2.
*      WRITE: 'Kalan = ',gv_kalan.
*      ENDIF.
*ENDCASE.
