All scripts use a trap on RETURN, out of laziness.

##### Llist

The double linked list gets an controlling associative array variable with the keys lname[type], lname[nodes] and lname[id.] Any node of the list will also get its own associative array variable with the following keys: `lname_$((lname[id] + 1))=([prev]= [next]= [data]=)`. Further, any list has an second index array variable lname_idx, which indexes all nodes in the right order.

Of course, lname_idx isn't necessary. But iterating over the list is still slower. This "implemantation" is a good example, how slow things are getting done in Bash in general.

```
set         lname [element ...]
unset       lname

linsert     lname index [element ...]
append      lname [element ...]
replace     lname first last [element ...]

index       lname [index]
range       lname [-r] first last

length      lname [-t]

traverse    lname [-r] index
```

##### Queue

One associative array variable will be used. Its keys are lname[type], lname[first] and lname[last]. In the case of pushing many elements to the queue, a second indexed array variable lname_idx would be better.

```
set     lname
pushl   lname [element]
pushr   lname [element]
popl    lname [element]
popr    lname [element]
```
