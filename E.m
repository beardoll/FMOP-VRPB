capacity = [2650 4300 5225];
carnum = [7 4 4];

Lx = [1620 17529 17720 5022 7552 19306 11918 17570 22990 3808 ...
      9429 6508 11547 6367 22147 7733 9680 15442 14528 9700 5002 ...
      18925 22187 23743 9971 4711 9017 14036 12199 8696];
Ly = [9521 5945 1930 15807 2144 13800 8907 13624 19823 27840 ...
      3110 9973 17250 2758 29935 19898 9471 13950 13724 28442 ...
      11529 16108 224 20651 8467 24628 4126 11215 15331 23850];
demandL = [316 727 270 588 775 174 586 846 248 138 511 608 ...
           325 211 651 293 426 396 399 276 933 294 764 783 ...
           851 706 745 601 783 430];
      
Bx = [16822 269 4084 17032 23436 14382 1384 2307 ...
      8079 15768 18448 16531 6503 15697 19311];
By = [18649 1987 28411 20544 8185 23354 23932 807 ...
      21171 3907 4986 22865 11774 18511 16441];
demandB = [319 510 520 319 318 388 653 870 475 ...
           528 539 488 198 323 592];

filename = 'EPro';
save(filename, 'Lx', 'Ly', 'demandL', 'Bx', 'By', 'demandB', 'capacity', 'carnum');