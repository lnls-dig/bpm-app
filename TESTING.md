# Testing List to Release

This tries to enumerate the test cases for manual testing before a release is done.
It is intended to help the tester to go through the possible cases and catch them
before the final user.

## Test Cases

### Data Acquisition

    1. Lower limits

        - # of Pre Samples = 0
        - # of Post Samples = 0

    Expected Result: Too few samples

    2. Upper limits 1

        - # of Pre Samples = 100000
        - # of Post Samples = > 0

    Expected Result: Too many samples

    3. Upper limits 2

        - # of Pre Samples = > 0
        - # of Post Samples = 100000

    Expected Result: Too many samples

    3. Upper limits 3

        - # of Pre Samples = x
        - # of Post Samples = y

        In which x + y > 100000

    Expected Result: Too many samples

    4. Lower boundaries 1

        - # of Pre Samples = 1, 2, 3, 4
        - # of Post Samples = 0
        - Trigger Type = *
        - Acq Channel = adc, adcswap, tbt, fofb, monit1

    Expected Result: Ok

    5. Lower boundaries 2

        - # of Pre Samples = 0
        - # of Post Samples = 1, 2, 3, 4
        - Trigger Type = external, data, software
        - Acq Channel = adc, adcswap, tbt, fofb, monit1

    Expected Result: Ok

    6. Lower boundaries 3

        - # of Pre Samples = 0
        - # of Post Samples = > 0
        - Trigger Type = now

    Expected Result: Error

    7. Internal ADC BRAM 1

        Simulataneous BPMs on the same board. Set both to:

        - # of Pre Samples = 1000, 4000, 4092
        - # of Post Samples = 0
        - Trigger Type = external (same trigger for both)
        - Repetitive = yes
        - Update Time = 0.001 s
        - Acq Channel = adc, adcswap

        Necessary to wait at least 10s before checking the result

    Expected Result: Ok, for both BPMs

    7. External ADC RAM 2

        Simulataneous BPMs on the same board. Set both to:

        - # of Pre Samples = 4093
        - # of Post Samples = 0
        - Trigger Type = external (same trigger for both)
        - Repetitive = yes
        - Update Time = 0.001 s
        - Acq Channel = adc, adcswap

    Expected Result: Acq. Overflow, on both BPMs

    8. Internal TbT, FOFB BRAM 1

        Simulataneous BPMs on the same board. Set both to:

        - # of Pre Samples = 1000, 4092
        - # of Post Samples = 0
        - Trigger Type = external (same trigger for both)
        - Repetitive = yes
        - Update Time = 0.001 s
        - Acq Channel = tbt, fofb

        Necessary to wait at least 10s before checking the result

    Expected Result: Ok, for both BPMs

    9. External TbT, FOFB RAM 2

        Simulataneous BPMs on the same board. Set both to:

        - # of Pre Samples = 4093, 10000, 100000
        - # of Post Samples = 0
        - Trigger Type = external (same trigger for both)
        - Repetitive = yes
        - Update Time = 0.001 s

    Expected Result: Ok, on both BPMs

    10. External TbT, FOFB RAM 3

        Simulataneous BPMs on the same board. Set both to:

        - # of Pre Samples = 50000
        - # of Post Samples = 50000
        - Trigger Type = external (same trigger for both)
        - Repetitive = yes
        - Update Time = 0.001 s

        IOC can appear to be stuck at time, depending on the computer.

    Expected Result: Ok, on both BPMs

### Position Calculation

    1. Position check

        - # of Pre Samples = 100
        - # of Post Samples = 100
        - Repetitive = no

        X, Y, Q, SUM position values must match calculation from A, B, C, D
        amplitdes using another offline method.

    2. Polynomial

        - # of Pre Samples = 100
        - # of Post Samples = 100
        - Repetitive = no
        - [X,Y,Q,SUM]PosCal-Sel = On
        - GEN_Cal[X,Y,Q,SUM]ArrayCoeff-SP = [<valid coefficient values>]

        Corrected position calculation must match calculation using another
        offline method.
