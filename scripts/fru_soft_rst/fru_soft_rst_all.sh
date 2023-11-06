#!/usr/bin/env bash

CRATES=()
CRATES+=("IA-01RaBPM-CO-CrateCtrl")
CRATES+=("IA-02RaBPM-CO-CrateCtrl")
CRATES+=("IA-03RaBPM-CO-CrateCtrl")
CRATES+=("IA-04RaBPM-CO-CrateCtrl")
CRATES+=("IA-05RaBPM-CO-CrateCtrl")
CRATES+=("IA-06RaBPM-CO-CrateCtrl")
CRATES+=("IA-07RaBPM-CO-CrateCtrl")
CRATES+=("IA-08RaBPM-CO-CrateCtrl")
CRATES+=("IA-09RaBPM-CO-CrateCtrl")
CRATES+=("IA-10RaBPM-CO-CrateCtrl")
CRATES+=("IA-11RaBPM-CO-CrateCtrl")
CRATES+=("IA-12RaBPM-CO-CrateCtrl")
CRATES+=("IA-13RaBPM-CO-CrateCtrl")
CRATES+=("IA-14RaBPM-CO-CrateCtrl")
CRATES+=("IA-15RaBPM-CO-CrateCtrl")
CRATES+=("IA-16RaBPM-CO-CrateCtrl")
CRATES+=("IA-17RaBPM-CO-CrateCtrl")
CRATES+=("IA-18RaBPM-CO-CrateCtrl")
CRATES+=("IA-19RaBPM-CO-CrateCtrl")
CRATES+=("IA-20RaBPM-CO-CrateCtrl")
CRATES+=("IA-20RaBPMTL-CO-CrateCtrl")

## CRATES+=("DE-22RaBPM-CO-CrateCtrl") # Homolog
## CRATES+=("DE-23RaBPM-CO-CrateCtrl") # Tests

FRU_IDS=()
FRU_IDS+=("5")
FRU_IDS+=("6")
FRU_IDS+=("7")
FRU_IDS+=("8")
FRU_IDS+=("9")
FRU_IDS+=("10")
FRU_IDS+=("11")
FRU_IDS+=("12")
FRU_IDS+=("13")
FRU_IDS+=("14")
FRU_IDS+=("15")
FRU_IDS+=("16")
## FRU_IDS+=("64")
FRU_IDS+=("90")

for crate in "${CRATES[@]}"; do
  {
    ./fru_soft_rst.expect ${crate} ${FRU_IDS[@]}
  } &
done
