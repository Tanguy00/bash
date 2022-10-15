Example of use: https://github.com/Tanguy00/bash

To import man page: cp mycompare /usr/man/man1
          and type: man mycompare 

Deploy test environment :
```
mkdir {A,B}
echo 'Chameau' > {1,3}
echo 'Cheval' > {2,4,A/6}
echo 'Dromadaire' > 5
echo 'Âne' > {A/7,B/8}
echo 'Rât' > B/8
```
Result is :
2 link 4 and 6
1 link 3
7 link 8
5 is alone