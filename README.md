# About

This repository contains a project for the Spartan3E FPGA. 
The project consists on a limited version of the classic game "Battleship".

The player wins by reaching 15 points before the algorythm, otherwise loses.
Boats are placed statically (their position is pre-defined and cannot be chosen) across an 8 by 8 grid. These have length of 1,2,3,4 and 5.

The pattern of the algorythm's boat positions is chosen randomly from four different pre-defined grids.

## Requirements

-  Basys 2 Spartan-3E FPGA;
- A VGA display/monitor;
- A PS/2 mouse.

## Resource usage

```
Design Summary:
Number of errors:      0
Number of warnings:    6
Logic Utilization:
  Total Number Slice Registers:         503 out of   1,920   26%
    Number used as Flip Flops:          455
    Number used as Latches:              48
  Number of 4 input LUTs:             1,749 out of   1,920   91%
Logic Distribution:
  Number of occupied Slices:            958 out of     960   99%
    Number of Slices containing only related logic:     958 out of     958 100%
    Number of Slices containing unrelated logic:          0 out of     958   0%
      *See NOTES below for an explanation of the effects of unrelated logic.
  Total Number of 4 input LUTs:       1,881 out of   1,920   97%
    Number used as logic:             1,749
    Number used as a route-thru:        132

  The Slice Logic Distribution report is not meaningful if the design is
  over-mapped for a non-slice resource or if Placement fails.

  Number of bonded IOBs:                 39 out of      83   46%
  Number of BUFGMUXs:                     3 out of      24   12%
  Number of DCMs:                         1 out of       2   50%

Average Fanout of Non-Clock Nets:                3.90

Peak Memory Usage:  4400 MB
Total REAL time to MAP completion:  3 secs 
Total CPU time to MAP completion:   3 secs 
```

## Known issues

- Both player and algorythm can select positions already used.
