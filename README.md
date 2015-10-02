# Glasgow TSP Challenge

1. Find the shortest tour that covers the 348 locations in file g7k.tsp.
2. All locations are space delimited x y coordinates (units might vary), one location per line, e.g.:
```
1632 4570
1118 3080
6275 3525
0 0
4488 3269
```
3. There are smaller location files (SisterTour.tsp, etc.) you might use for solution development & debugging
4. The first location in each file has index 0.
5. Each solution solution must be a permutation of location indices, e.g.:
```
0
2
4
3
1
```
6. All locations have to be visited once and only once.
5. Your solution will be costed using Verify.java program, i.e.:
```bash
java Verify g7k.tsp g7k.sol  
```
6. Shortest tour wins, tie breaking on who commits that tour on github first.
7. You can push a solution to github as often as you wish.
8. You can visualise any valid tour using Display.java, i.e.:
```bash
java Display SisterTour.tsp SisterTour.sol
```
9. You have to compile all .java files with java 7 (and not java 8), like this:
```bash
javac *.java
```

Best of luck,
Adam Kurkiewicz & Patrick Prosser
02/10/2015

