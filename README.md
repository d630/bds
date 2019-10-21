Each script sets a trap on RETURN.

##### Llist

The double linked list gets a controlling associative array variable with the
keys `lname[type]`, `lname[nodes]` and `lname[id]` AND a second index array
variable `lname_idx`, which indexes all nodes in the right order. (Of course,
`lname_idx` isn't necessary. But iterating over the list is still slower.)

Each node of the list will get its own associative array variable with the
following keys: `lname_$((lname[id] + 1))=([prev]= [next]= [data]=)`.

```
set         lname [element ...]
unset       lname

insert      lname index [element ...]
append      lname [element ...]
replace     lname first last [element ...]

index       lname [index]
range       lname [-r] first last

length      lname [-t]

traverse    lname [-r] index
```

##### Queue

One associative array variable is being used. Its keys are `qname[type]`,
`qname[first]` and `qname[last]`. In case of pushing many elements to the
queue, an additional indexed array variable `qname_idx` would be an good idea.

```
set         qname
pushl       qname [element]
pushr       qname [element]
popl        qname
popr        qname
```
