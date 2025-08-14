REPORT Z_ODEV_005.

PARAMETERS:
  p1 TYPE c LENGTH 6,
  p2 TYPE c LENGTH 6,
  p3 TYPE c LENGTH 6,
  p4 TYPE c LENGTH 6,
  p5 TYPE c LENGTH 6.

DATA: w1 TYPE c LENGTH 1 VALUE 'N',
      w2 TYPE c LENGTH 1 VALUE 'N',
      w3 TYPE c LENGTH 1 VALUE 'N',
      w4 TYPE c LENGTH 1 VALUE 'N',
      w5 TYPE c LENGTH 1 VALUE 'N'.

IF p1 CO p2 AND p2 CO p1 AND p1 <> p2.
  WRITE: / p1, '-', p2.
  w1 = 'Y'. w2 = 'Y'.
ENDIF.

IF p1 CO p3 AND p3 CO p1 AND p1 <> p3 AND w1 = 'N' AND w3 = 'N'.
  WRITE: / p1, '-', p3.
  w1 = 'Y'. w3 = 'Y'.
ENDIF.

IF p2 CO p3 AND p3 CO p2 AND p2 <> p3 AND w2 = 'N' AND w3 = 'N'.
  WRITE: / p2, '-', p3.
  w2 = 'Y'. w3 = 'Y'.
ENDIF.

IF w1 = 'N'. WRITE: / p1. ENDIF.
IF w2 = 'N'. WRITE: / p2. ENDIF.
IF w3 = 'N'. WRITE: / p3. ENDIF.
IF w4 = 'N'. WRITE: / p4. ENDIF.
IF w5 = 'N'. WRITE: / p5. ENDIF.
