/* example graph.txt file. combining multiple node IDs that share the same values otherwise is possible with dashes.
4, Directed, Unweighted
0 1-2
1 0-3
2 3
3 1
---
0 1 `n 0 2 is equivalent to 0 1-2.
The resulting graph has 4 nodes, where node 0 connects to points 1,2, node 1 connects to 0,3, 2 to 3, 3 to 1.

EXAMPLE USAGE:
gr := Graph(true)
gr.loadFromFile("Graphs\graphSmall.txt")
path := GraphUtils.findPath(gr, gr.nodes[0], gr.nodes[1337]) ; => gives array of nodes in path
grSmall := GraphUtils.getSpanningArborescence(gr, gr.nodes[0]) => gives back a new graph
return
*/

/*
WHAT IF YOU HAVE A SOLITARY NODE WITH NO NEIGHBOURS.
*/

; OPTION TO INSTANTIATE GRAPH WITH SPECIFIED DEFAULT VALUE FOR NODES/EDGES, EG ALL EDGES WEIGHT 0.
; THEN DON'T NEED TO CHECK IF EDGE HAS WEIGHT.
class GraphUtils {

	/**
	 * Finds path between start and end with smallest weight (or smallest # of edges).
	 * @param {Graph} g 
	 * @param {Graph.Node} start 
	 * @param {Graph.Node} end 
	 * @returns {Bool} 
	 */
	static shortestPath(g, start, end, useWeight := true) {
		reverseTree := Graph(true) 
		reverseTree.addNode(start.id)
		stack := [start]
		seen := Map(start.id, true)
		while (stack.Length > 0) {
			node := stack.RemoveAt(1)
			for nID, nNode in node.neighbours {
				if (!seen.Has(nID)) {
					stack.Push(nNode)
					rtNode := reverseTree.addNode(nID)
					rtNode.addEdge(reverseTree.nodes[node.id])
					seen[nID] := true
				}
				if (nID == end.id) { ; rtNode.id == end.id == nID
					local path := []
					while (rtNode.id != start.id) {
						for i, previousNode in rtNode.neighbours { ; this only ever has one iteration since its a reverse tree
							path.InsertAt(1, rtNode.id)
							rtNode := previousNode
						}
					}
					path.InsertAt(1, rtNode.id)
					reverseTree.nodes[end.id].getNeighbours()
					return path
				}
			}
		}
		return false
	}

	/**
	 * Finds path between start and end with smallest weight (or smallest # of edges).
	 * @param {Graph} g 
	 * @param {Graph.Node} start 
	 * @param {Graph.Node} end 
	 * @returns {Bool} 
	 */
	static bestPath(g, start, end, useWeight := true) {
		distances := Map()
		distances[start.id] := 0
		prev := Map()
		stack := [start]
		visited := Map()
		while (stack.Length > 0) {
			minim := distances[stack[1].id]
			mIndex := 1
			for i, e in stack {
				if (distances[e.id] < minim) {
					minim := distances[e.id]
					mIndex := i
				}
			}
			node := stack.RemoveAt(mIndex)
			if (node.id == end.id) {
				local path := [end.id]
				nodeID := end.id
				while(nodeID != start.id) {
					nodeID := prev[nodeID]
					path.InsertAt(1, nodeID)
				}
				return [distances[end.id], path]
			}
			visited[node.id] := true
			for nID, edge in node.getEdges() {
				altDistance := distances[node.id] + (useWeight ? edge.weight : 1)
				if (!distances.Has(nID) || distances.has(nID) && altDistance < distances[nID]) {
					stack.push(edge.tail)
					distances[nID] := altDistance
					prev[nID] := node.id
				}
			}
		}
		return false
	}


	/**
	 * Returns whether there is a path between node start and node end. Optionally specify whether to use DFS or BFS.
	 * @param graph 
	 * @param {Graph.Node} start 
	 * @param {Graph.Node} end 
	 * @param {Integer} dfs 
	 * @returns {Bool} 
	 */
	static isReachable(graph, start, end, dfs := 0) {
		stack := [start]
		seen := Map(start.id, true)
		while (stack.Length > 0) {
			node := (dfs ? stack.Pop() : stack.RemoveAt(1)) ; only difference between bfs and dfs
			for nID, nNode in node.neighbours {
				if (nID == end.id)
					return true
				if (!seen.Has(nID)) {
					stack.Push(nNode)
					seen[node.id] := true
				}
			}
		}
		return false
	}

	/**
	 * Returns whether the graph is fully connected.
	 * @param {Graph} g 
	 * @returns {Bool} 
	 */
	static isConnected(g) {
		stack := [g.getNode()]
		seen := Map(stack[0].id, true)
		while (stack.Length > 0) {
			node := stack.Pop()
			for nID, nNode in node.neighbours {
				if (!seen.Has(nID)) {
					stack.Push(nNode)
					seen[nID] := true
				}
			}
		}
		return g.nodes.Count == seen.Count
	}

	/**
	 * Returns new graph with only the connected nodes of the given node.
	 * @param {Graph} g 
	 * @param {Graph.Node} node 
	 * @returns {Graph} 
	 */
	static getConnectedInstance(g, node) {
		cgi := Graph(g.isDirected)
		stack := [node]
		seen := Map(node.id, node)
		while (stack.Length > 0) {
			node := stack.Pop()
			for nID, nNode in node.neighbours {
				if (!seen.Has(nID)) {
					stack.Push(nNode)
					seen[nID] := nNode
				}
			}
		}
		for nodeID, n in seen
			cgi.addNode(nodeID)
		for nodeID, n in seen
			cgi.projectNode(n)
		return cgi
	}

	/**
	 * Returns *a* spanning arborecence of the graph, starting from the given root node.
	 * @param {Graph} g 
	 * @param {Graph.Node} root 
	 * @returns {Graph} 
	 */
	static getSpanningArborescence(g, root) {
		arborescence := Graph(g.isDirected)
		rootAr := arborescence.addNode(root.id)
		stack := [root]
		seen := Map(root.id, true)
		while (stack.Length > 0) {
			node := stack.Pop()
			nodeAr := arborescence.nodes[node.id]
			for nID, nNode in node.neighbours
				if (!seen.Has(nID)) {
					seen[nID] := true
					stack.Push(nNode)
					nNodeAr := arborescence.addNode(nID)
					edge := node.getEdge(nNode)
					arborescence.addEdge(nodeAr, nNodeAr, edge.getAllProperties()*)
				}
		}
		return arborescence
	}

	class FibonacciHeap {
		__New() {
			this.nodes := Map()       ; all nodes by ID
			this.minNode := unset     ; pointer to min node
			this.rootList := []       ; top-level trees
			this.nodeCount := 0
		}

		insert(value, key) {
			node := this.createNode(value, key)
			this.rootList.Push(node)
			this.nodes[value] := node
			if (!IsSet(this.minNode) || node.key < this.minNode.key)
				this.minNode := node
		}

		createNode(value, key) {
			return {
				value: value,
				key: key,
				parent: unset,
				children: [],
				degree: 0,
				mark: false
			}
		}

		getMin() {
			return IsSet(this.minNode) ? this.minNode.value : ""
		}

		extractMin() {
			local min := this.minNode
			if !IsSet(min)
				return ""

			; Promote min’s children to root list
			for child in min.children {
				child.parent := unset
				this.rootList.Push(child)
			}

			; Remove min from root list
			this.rootList := this.rootList.Filter((n) => n.value != min.value)
			this.nodes.Delete(min.value)

			; Consolidate trees
			this.consolidate()

			return min.value
		}

		decreaseKey(value, newKey) {
			node := this.nodes[value]
			if (!IsSet(node) || newKey > node.key)
				return  ; invalid

			node.key := newKey
			parent := node.parent
			if IsSet(parent) && node.key < parent.key {
				this.cut(node, parent)
				this.cascadingCut(parent)
			}
			if node.key < this.minNode.key
				this.minNode := node
		}

		cut(child, parent) {
			parent.children := parent.children.Filter((n) => n.value != child.value)
			parent.degree -= 1
			this.rootList.Push(child)
			child.parent := unset
			child.mark := false
		}

		cascadingCut(node) {
			p := node.parent
			if !IsSet(p)
				return
			if !node.mark
				node.mark := true
			else {
				this.cut(node, p)
				this.cascadingCut(p)
			}
		}

		consolidate() {
			degreeTable := Map()
			newRootList := []

			for node in this.rootList {
				d := node.degree
				while degreeTable.Has(d) {
					other := degreeTable[d]
					if node.key > other.key {
						temp := node, node := other, other := temp
					}
					this.link(other, node)
					degreeTable.Delete(d)
					d += 1
				}
				degreeTable[d] := node
			}

			this.minNode := unset
			for d, node in degreeTable {
				newRootList.Push(node)
				if !IsSet(this.minNode) || node.key < this.minNode.key
					this.minNode := node
			}

			this.rootList := newRootList
		}

		link(child, parent) {
			this.rootList := this.rootList.Filter((n) => n.value != child.value)
			child.parent := parent
			parent.children.Push(child)
			parent.degree += 1
			child.mark := false
		}
	}
}

class Graph {
	nodes := Map()
	isDirected := false
	isWeighted := false
	hasFlow := false

	/**
	 * Creates new Graph Instance 
	 * @param {Integer} isDirected Whether the Graph is directed 
	 * @param filePath a path to a file containing a compatible graph format
	 */
	__New(isDirected?, filePath?, isWeighted?, hasFlow?) {
		if (IsSet(filePath))
			this.loadFromFile(filePath, isDirected, isWeighted, hasFlow)
		else {
			if (IsSet(isDirected))
				this.isDirected := isDirected
			if (IsSet(isWeighted))
				this.isWeighted := isWeighted
			if (IsSet(hasFlow))
				this.hasFlow := hasFlow
		}
	}

	getNode(id?) {
		if (IsSet(id))
			return this.nodes[id]
		for i, node in this.nodes
			return node
	}
	

	/**
	 * @returns {Graph.Node} 
	 */
	addNode(nodeID?) {
		if (IsSet(nodeID)) {
			if (this.nodes.Has(nodeID))
				throw(Error(Format("Node {} already exists.", nodeID)))
		}
		else {
			if (!this.nodes.Has(this.nodes.Count + 1))
				nodeID := this.nodes.Count + 1
			else
				Loop(this.nodes.Count) {
					if !(this.nodes.Has(this.nodes.Count + A_Index + 1)) {
						nodeID := A_Index
						break
					}
				}
		}
		return (this.nodes[nodeID] := Graph.Node(nodeID))
	}

	/**
	 * Projects a node from other graph H onto this graph, removing any edges to nodes which do not exist here.
	 * A node with the same ID may already exist, in which case the edges are updated accordingly.
	 * @param {Graph.Node} node 
	 */
	projectNode(node) {
		if (this.nodes.Has(node.id))
			newNode := this.nodes[node.id]
		else {
			newNode := Graph.Node(node.id, node.Has("name") ? node.name : unset)
			this.nodes[node.id] := newNode
		}
		for nID, edge in node.getEdges()
			if (this.nodes.Has(nID))
				this.addEdge(newNode, this.nodes[nID], edge.getAllProperties()*)
		return newNode
	}
	
	/**
	 * 
	 * @param {Graph.Node} head 
	 * @param {Graph.Node} tail 
	 * @param {Integer} weight 
	 * @param {Integer} capacity 
	 * @param {Integer} flow 
	 * @returns {Bool} 
	 */
	addEdge(head, tail, weight?, capacity?, flow?) {
		if (head.hasNeighbour(tail))
			return 0
		head.addEdge(tail, weight?, capacity?, flow?)
		if (!this.isDirected)
			return tail.addEdge(head, weight?, capacity?, flow?)
	}

	/**
	 * Merges given Graph into current graph, without connecting any edges.
	 * @param {Graph} g2 
	 * @returns {Graph} 
	 */
	mergeGraph(g2) {
		return this
	}

	loadFromFile(fileName, asDirected?, asWeighted?, withFlow?) {
		f := FileOpen(fileName, "r")
		options := f.ReadLine()
		if (IsSet(asDirected))
			this.isDirected := asDirected
		else if (InStr(options, "directed") && !InStr(options, "undirected"))
			this.isDirected := true
		if (IsSet(asWeighted))
			this.isWeighted := asWeighted
		else if (InStr(options, "weighted") && !InStr(options, "unweighted"))
			this.isWeighted := true
		if (IsSet(withFlow))
			this.hasFlow := withFlow
		else if (InStr(options, "Flow"))
			this.hasFlow := true
		neighbours := Map()
		while (line := f.ReadLine()) {
			if (line = "")
				break
			arr := StrSplit(RegexReplace(Trim(line), "\s+", " "), [" "])
			nodeID := Integer(arr[1])
			if (arr.Length > 1)
				nodeNeighbours := StrSplit(arr[2], "-")
			else
				nodeNeighbours := []
			if (arr.Length > 2)
				this.isWeighted := true
			for i, e in nodeNeighbours {
				nodeNeighbours[i] := {id: Integer(e)}
				if (this.isWeighted)
					nodeNeighbours[i].weight := arr.Has(3) ? Number(arr[3]) : 1
				if (this.hasFlow) {
					j := this.isWeighted ? 4 : 3
					nodeNeighbours[i].capacity := arr.Has(j) ? Number(arr[j]) : 1
					nodeNeighbours[i].flow := arr.Has(j+1) ? Number(arr[j+1]) : 1
				}
			}
			if (this.nodes.Has(nodeID))
				neighbours[nodeID].push(nodeNeighbours*)
			else {
				this.nodes[nodeID] := Graph.Node(nodeID)
				neighbours[nodeID] := nodeNeighbours
			}
		}
		for nodeID, nodeNeighbours in neighbours
			for nInfo in nodeNeighbours {
				if !(this.nodes.Has(nInfo.id))
					this.nodes[nInfo.id] := Graph.Node(nInfo.id)
				this.nodes[nodeID].addEdge(this.nodes[nInfo.id], this.isWeighted ? nInfo.weight : unset, this.hasFlow ? nInfo.capacity : unset, this.hasFlow ? nInfo.flow : unset)
				if (!this.isDirected)
					this.nodes[nInfo.id].addEdge(this.nodes[nodeID], this.isWeighted ? nInfo.weight : unset, this.hasFlow ? nInfo.capacity : unset, this.hasFlow ? nInfo.flow : unset)
			}
	}
	; load in graph
	; -> build the graph by iterating over all nodes in the order that they are given, ignoring all nodes given only by connection
	; -> then, when we have all node objects, we initialize the node objects with their connected nodes by iterating over their saved node IDs.
	; -> then, we iterate over all edges and add them to the graph

	toString() {
		str := this.nodes.Count ", " (this.isDirected ? "Directed" : "Undirected") ", " (this.isWeighted ? "Weighted" : "Unweighted") ", " (this.hasFlow ? "Flow" : "No Flow") "`n"
		seenNodes := Map()
		for id, node in this.nodes {
			uniqueEdges := Map()
			seenNodes[id] := true
			for j, edge in node.edges {
				edgeProperties := (edge.HasOwnProp("weight") ? edge.weight ' ' : "") . (this.HasOwnProp("capacity") ? edge.capacity ' ' : "") . (this.HasOwnProp("flow") ? edge.flow : "")
				if (uniqueEdges.Has(edgeProperties))
					uniqueEdges[edgeProperties].push(edge.tail.id)
				else
					uniqueEdges[edgeProperties] := [edge.tail.id]
			}
			nodeStr := node.allNeighbours.Count > 0 ? "" : id
			for edgeProperties, edges in uniqueEdges {
				edgeStr := ""
				for tailID in edges {
					seenNodes[tailID] := true
					edgeStr .= tailID "-"
				}
				nodeStr .= id ' ' RTrim(edgeStr, "-") ' ' edgeProperties "`n"
			}
			str .= nodeStr == "" ? "" : RTrim(nodeStr, "`n") "`n"
		}
		return RTrim(str, "`n")
	}

	class Node {
		edges := Map()
		neighbours := Map()
		allNeighbours := Map()
		

		__New(id, name?) {
			this.id := id
			this.name := name ?? unset
		}

		/**
		 * Adds a *Directed* Edge to the given node.
		 * @param {Graph.Node} tail 
		 * @param {Integer} weight 
		 * @param {Integer} capacity 
		 * @param {Integer} flow 
		 * @returns {Bool} 
		 */
		addEdge(tail, weight?, capacity?, flow?) {
			if (this.neighbours.Has(tail.id))
				return 0
			this.neighbours[tail.id] := tail ; this exists solely to make it easier to access connected nodes.
			this.allNeighbours[tail.id] := tail ; this is for collecting in- and out-neighbours in the same basket
			tail.allNeighbours[this.id] := this
			this.edges[tail.id] := Graph.Edge(this, tail, weight?, capacity?, flow?)
			return 1
		}

		/**
		 * Removes the given edge
		 * @param {Graph.Node} tail 
		 * @returns {Integer} 
		 */
		removeEdge(tail, isDirected := true) {  
			if (this.hasNeighbour(tail.id)) {
				node := this.neighbours.Delete(tail.id)
				this.edges.Delete(tail.id)
				if (!isDirected) {
					tail.neighbours.delete(this.id)
					tail.edges.delete(this.id)
				}
				if !(tail.hasNeighbour(this.id)) {
					this.allNeighbours.Delete(tail.id)
					tail.allNeighbours.Delete(this.id)
				}
				return 1
			}
			return 0
		}


		getID() { ; -> ID of node
			return this.id
		}

		getEdge(tail) {
			return this.edges[tail.id]
		}

		getEdges() {
			return this.edges
		}

		getNeighbours() { ; -> Map of connected nodes
			return this.neighbours
		}

		getAllNeighbours() {
			return this.allNeighbours
		}

		hasNeighbour(node) { ; -> boolean
			return this.neighbours.Has(node)
		}

		isAdjacent(node) {
			return this.allNeighbours.Has(node)
		}
	}

	
	class Edge {
		__New(head, tail, weight?, capacity?, flow?) {
			this.head := head
			this.tail := tail
			this.weight := weight ?? unset
			this.capacity := capacity ?? unset
			this.flow := flow ?? unset
		}

		getAllProperties() {
			return [this.HasOwnProp("weight") ? this.weight : unset,
					this.HasOwnProp("capacity") ? this.capacity : unset,
					this.HasOwnProp("flow") ? this.flow : unset	]
		}
	}
}
