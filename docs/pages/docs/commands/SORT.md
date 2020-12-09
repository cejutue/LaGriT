---
title: "sort"
categories: sort 
---

# SORT 

----------------


The **sort** command creates a sort key for chosen node or element attributes. 
Sort can be in ascending or descending order and will not alter current mesh object values.


The mesh object is not re-ordered but a sort key is created. Use [**`REORDER`**](REORDER.md) to change the node or element ordering of the mesh object.


 
## SYNTAX

<pre>
<b>sort</b>/mo_name/<b>bins</b> /[<b> ascending</b> or <b>descending</b>]/key_name/ sort_attribute / [epsilon_user]

<b>sort</b>/mo_name/<b>index</b> or <b>rank</b>/[<b>ascending</b> or <b>descending</b>]/key_name/ in_att1, in_att2, in_att3 ...

<b>sort</b>/mo_name/<b>line_graph</b> /[<b>ascending</b> or <b> descending</b>]/key_name/[<b>elements</b> or <b>nodes</b>]
</pre>
 

For all commands:

`mo_name` is the name of a valid mesh object or **-def-** which selects the currently active mesh object.


`sort_type` sorting methods include **`bins`**, **`index`**, **`rank`** and **`line_graph`** See below.


 **`ascending`** or **`descending`** detirmines the ordering direction. Note this parameter is ignored by the **line_graph** method but must be present for consistency with other sort variations. 


`key_name` is the name of the sort key attribute created. The **reorder** command uses this to reorder the mesh.
This is an integer vector (VINT) which will hold the output sort key values. If no name is given for `key_name`, a name will be created which will be  **ikey_** and the first attribute name in sort_attributes. For the **`line_graph`** option, the default `key_name` will be called **ikey_line_graph**.


*`sort_attributes`* The name of one or more existing attribute names. Each attribute will be used as a node of element based array upon which the sorting routine will sort. Multi-key sorts can have an arbitrary number
of input attributes. Attribute in_att1(n) has priority over in_att2(n) in breaking ties. Note: all attributes are put into a type real work array before being sent to the sort routine.
Note the **line_graph** does not use attributes as it sorts line elements based on connectivity (see method below). 



###  Single-Key sort: 


**`bins`** is a single-key sort which assigns each in_att1 value a bin
 number. If in_att1 is an integer then bins each have a unique integer
 value associated with them. If in_att1 is a real number, bins are
 created with values which are within +-epsilon of each other, where
 epsilon=1.e-10 x abs(real_bin_value). If all array values are unique,
 then the maximum value of the index array will equal the number of
 entries in the sorted list. Otherwise, the maximum value of the index
 array will be less than the number of entries in the sorted list but
 will equal the number of unique entries in the list. With the **`bins`** method, an optional user specified epsilon
 multiplier, *epsilon_user*, will override the default value of 1.e-10.


### Multi-Key sort:

**`index`** is a single or multi-key sort that constructs an index table such that
 in_att1(ikey(1)) is the first entry in the sorted array, in_att1(ikey(2)) is the second, etc.


**`rank`** is a single or multi-key sort that constructs a rank table such that the tables ith entry give the rank of the ith entry of the sorted arrays. The rank table is derived from the index table by:
<pre>
 foreach j = 1,N
   rank(index(j)) = j
 end
</pre>


### Line Graph sort:


**`line_graph`** is a sort for connected line segments for arranging into a reasonable order. The sorted order for components which are not polylines or polygons is unspecified, but it will usually be reasonable because the underlying
 algorithm visits the edges via depth first search. In particular, it makes the following guarantees:

 -   Each connected component will be arranged together.
 -   Polylines (chains of line segments with no branching or loops)
     will be in order from one end to the other.
 -   Polygons will be in order starting from one segment and looping
     back around to the same place.
 

 **`line_graph`** with **`elements`** generates the following three integer element attributes:

 -   cid: A component id for distinguishing separate connected
     components. Each connected component receives a unique positive
     integer starting from one. This allows you to identify all the
     edges in a particular component by selecting all elements with a
     particular component id.
 -   ctype: The component type, represented as an integer from 1 to 5.

     1 (Polyline)
     :   A connected chain of segments with no branches or loops.

     2 (Tree)
     :   A connected acyclic component.

     3 (Polygon)
     :   A component consisting solely of a single loop.

     4 (Shared Edges)
     :   A component which has a pair of cycles with a shared edge.

     5 (Other)
     :   Anything which does not fit into the above categories.

 -   loop\_id: This is a unique positive integer assigned to each
     simple cycle. Edges that are not part of a cycle receive a default
     value of zero. If an edge is shared (i.e. part of more than one
     cycle) then it will be labeled with only one of its cycles. In
     this case, the cycle corresponding to the label is not fully
     specified because there is more than one right answer.

 **`line_graph`** with **`nodes`** is based on the option for
 elements, except that it does not create extra attributes. Based on
 the sorted elements, the nodes will be reordered in the same sequence.
 This is necessary for triangulation as "TRIANGULATE" routine requires
 the nodes to be in either clockwise or counterclockwise order.


<hr>


## EXAMPLES 

<pre>
     sort / cmo / line_graph / ascending / ikey / elements
</pre>

Sort the line segment elements into a reasonable order based on connectivity. This also creates attributes cid, ctype, and loop_id (see above).
 

<pre>
 sort / cmo / index / ascending / ikey / imt zic yic xic
</pre>
Multi-key sort first by imt then to break ties consider z coordinate, then if there are further ties, use y coordinate. Use x coordinate as final tie breaker.


<pre>
     sort / cmo / rank / descending / ikey / yic
</pre>
Produce ranking of nodes based on y coordinate in descending order.

<pre>
     sort / cmo / index /-def-/-def-/ xic yic zic
     </pre>

 Produce index of noded coordinates. This would be like a line sweep
 sort where the sweep is first along x coordinate then y then z.

<pre>
     sort / cmo / bins / ascending / i_index / xic
     sort/ cmo / bins / ascending / j_index / yic
     sort / cmo / bins / ascending / k_index / zic
     </pre>

 If the cmo were a finite difference grid of points, the above three
 commands would produce the finite difference indexing. All points with
 the same x value would be in the same i_index bin, all points with
 the same y value would be in the same j_index bin, etc.

<pre>
define MOGOOD motet
define MOSORT mopts

cmo/addatt/MOSORT id_mesh1 /VINT/scalar/nnodes/linear/permanent//0      
interpolate/voronoi/ MOSORT id_mesh1/1,0,0/ MOGOOD id_node

cmo/addatt/MOSORT id_diff /VINT/scalar/nnodes/linear/permanent//0      
math/sub/MOSORT id_diff/1,0,0/ MOSORT id_mesh1 /MOGOOD id_node
cmo/printatt/MOSORT/ id_diff / minmax

sort/ MOSORT/ index / ascending / ikey / id_mesh1
reorder/MOSORT/ ikey
</pre>

Sort and reorder a set of nodes based on a source mesh, based on node id and position xyz. Use **`interpolate/voronoi`** to associate each node with the good mesh node id's. We check to see if the ordering for both mesh objects is different by subtracting the node id of one from the second. The result would be 0 for all nodes that match position and node id. Sort mesh object using the attribute with the interpolated node id's, then reorder using the ikey values.
 


## LINKS

[LaGriT command file example 1 for sort and reorder](../demos/input/sort_lagrit_input_1.txt)

[LaGrit command file example 2 for sort and reorder](../demos/input/sort_lagrit_input_2.txt)


## OLD FORMAT - No longer supported but syntax will still work. ##

<pre>
sort / xyz / [ index  bins  rank ]
</pre>

 **`sort/xyz/index`** sorts the x,y,z coordinate integer arrays i_index,
 j_index, k_index such that xic(i_index(i)) i=1,..nnodes lists the coordinate in ascending order.

 **`sort/xyz/bins`** sorts the x,y,z coordinates and assigns each i_index,
 j_index, k_index values in ascending order of the bin number of the sorted list.

 **`sort/xyz/rank`**  sorts the x,y,z coordinates and assigns each i_index,
 j_index, k_index values the ranking of the node in the sorted list.

 If all array values are unique, then the maximum value of the index
 array will equal the number of entries in the sorted list. Otherwise,
 the maximum value of the index array will be less than the number of
 entries in the sorted list but will equal the number of unique entries
 in the list.

<pre>
 For example given x = 0, 1, 2, 1, 0

 sort/xyz/index returns i_index = 5, 1, 4, 2, 3

 sort/xyz/bins returns i_index = 1, 2, 3, 2, 1

 sort/xyz/rank returns i_index = 2, 4, 5, 3, 1
 </pre>



