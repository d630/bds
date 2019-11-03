Each script sets a trap on RETURN.

#### Llist

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
prepend     lname [element ...]
replace     lname first last [element ...]

index       lname [index]
range       lname [-r] first last

length      lname [-t]

traverse    lname [-r] index
```

#### Queue

##### normal

One associative array variable is being used. Its keys are `qname[type]`,
`qname[first]` and `qname[last]`.

```
set         qname
pushl       qname [element]
pushr       qname [element]
popl        qname
popr        qname
```

##### ext

One associative array variable + two indexed array variables for head and tail
are being used. Keys are `qname[type]`, `qname[head]`, `qname[tail]`, and
`qname[head_first]`, `qname[tail_first]`

```
set         qname
pushl       qname [element]
pushr       qname [element]
popl        qname
popr        qname
```
