UPDATE Units
SET Combat = CAST((Combat*0.80) AS INT)
WHERE (instr(Type, '_MAGICAL_GIRL_') > 0);