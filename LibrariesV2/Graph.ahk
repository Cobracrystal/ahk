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
gr := GraphUtils.loadFromFile("Graphs\graphSmall.txt", true)
path := GraphUtils.findPath(gr, gr.nodes[0], gr.nodes[1337]) ; => gives array of nodes in path
grSmall := GraphUtils.getSpanningArborescence(gr, gr.nodes[0]) => gives back a new graph
return
*/


; OPTION TO INSTANTIATE GRAPH WITH SPECIFIED DEFAULT VALUE FOR NODES/EDGES, EG ALL EDGES WEIGHT 0.
; THEN DON'T NEED TO CHECK IF EDGE HAS WEIGHT.
class GraphUtils {

	/**
	 * Finds path between start and end with smallest # of edges.
	 * @param {Graph} g 
	 * @param {Graph.Node} start 
	 * @param {Graph.Node} end 
	 * @returns {Bool} 
	 */
	static shortestPath(g, start, end) {
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
	static minimalPath(g, start, end, useWeight := true) {
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

	static loadFromFile(fileName, asDirected?, asWeighted?, withFlow?) {
		gr := Graph()
		f := FileOpen(fileName, "r")
		options := f.ReadLine()
		if (IsSet(asDirected))
			gr.isDirected := asDirected
		else if (InStr(options, "directed") && !InStr(options, "undirected"))
			gr.isDirected := true
		if (IsSet(asWeighted))
			gr.isWeighted := asWeighted
		else if (InStr(options, "weighted") && !InStr(options, "unweighted"))
			gr.isWeighted := true
		if (IsSet(withFlow))
			gr.hasFlow := withFlow
		else if (InStr(options, "Flow"))
			gr.hasFlow := true
		neighbours := Map()
		while (line := f.ReadLine()) {
			if (line = "")
				break
			arr := StrSplit(RegexReplace(Trim(line), "\s+", " "), " ")
			nodeID := Integer(arr[1])
			if (arr.Length > 1)
				nodeNeighbours := StrSplit(arr[2], "-")
			else
				nodeNeighbours := []
			if (arr.Length > 2 && !IsSet(asWeighted))
				gr.isWeighted := true
			for i, e in nodeNeighbours {
				nodeNeighbours[i] := {id: Integer(e)}
				if (gr.isWeighted)
					nodeNeighbours[i].weight := arr.Has(3) ? Number(arr[3]) : 1
				if (gr.hasFlow) {
					j := gr.isWeighted ? 4 : 3
					nodeNeighbours[i].capacity := arr.Has(j) ? Number(arr[j]) : 1
					nodeNeighbours[i].flow := arr.Has(j+1) ? Number(arr[j+1]) : 1
				}
			}
			if (gr.nodes.Has(nodeID))
				neighbours[nodeID].push(nodeNeighbours*)
			else {
				gr.addNode(nodeID)
				neighbours[nodeID] := nodeNeighbours
			}
		}
		for nodeID, nodeNeighbours in neighbours
			for neighbour in nodeNeighbours {
				if !(gr.nodes.Has(neighbour.id)) ; neighbours may not be defined as their own node
					gr.addNode(neighbour.id)
				gr.nodes[nodeID].addEdge(gr.nodes[neighbour.id], gr.isWeighted ? neighbour.weight : unset, gr.hasFlow ? neighbour.capacity : unset, gr.hasFlow ? neighbour.flow : unset)
				if (!gr.isDirected)
					gr.nodes[neighbour.id].addEdge(gr.nodes[nodeID], gr.isWeighted ? neighbour.weight : unset, gr.hasFlow ? neighbour.capacity : unset, gr.hasFlow ? neighbour.flow : unset)
			}
		return gr
	}
	; load in graph
	; -> build the graph by iterating over all nodes in the order that they are given, ignoring all nodes given only by connection
	; -> then, when we have all node objects, we initialize the node objects with their connected nodes by iterating over their saved node IDs.
	; -> then, we iterate over all edges and add them to the graph

	class FibonacciHeap {
		__New() {
			this.graph := Graph(true)
			this.minNode := unset
			this.rootList := []
			this.nodeRefs := Map() 
			this.nextNodeID := 1
		}

		insert(value, key) {
			id := this.nextNodeID++
			node := this.graph.addNode(id)
			node.value := value
			node.key := key
			node.degree := 0
			node.mark := false
			node.parent := unset
			node.children := []

			this.rootList.Push(node)
			this.nodeRefs[value] := id

			if (!this.HasOwnProp("minNode") || key < this.minNode.key)
				this.minNode := node
		}

		getMin() {
			return this.HasOwnProp("minNode") ? this.minNode.value : ""
		}

		extractMin() {
			minNode := this.minNode
			if !IsSet(minNode)
				return ""

			for child in minNode.children {
				child.parent := unset
				this.rootList.Push(child)
			}

			this.rootList := this.rootList.Filter((n) => n != minNode)
			this.graph.nodes.Delete(minNode.id)
			this.nodeRefs.Delete(minNode.value)

			this.consolidate()

			return minNode.value
		}

		decreaseKey(value, newKey) {
			if !this.nodeRefs.Has(value)
				return

			node := this.graph.nodes[this.nodeRefs[value]]
			if (newKey > node.key)
				return

			node.key := newKey
			parent := node.HasOwnProp("parent") ? node.parent : unset
			if IsSet(parent) && node.key < parent.key {
				this.cut(node, parent)
				this.cascadingCut(parent)
			}
			if node.key < this.minNode.key
				this.minNode := node
		}

		cut(child, parent) {
			parent.children := parent.children.Filter((n) => n != child)
			parent.degree--
			this.rootList.Push(child)
			child.parent := unset
			child.mark := false
		}

		cascadingCut(node) {
			parent := node.HasOwnProp("parent") ? node.parent : unset
			if !IsSet(parent)
				return
			if !node.mark
				node.mark := true
			else {
				this.cut(node, parent)
				this.cascadingCut(parent)
			}
		}

		consolidate() {
			table := Map()
			newRoots := []

			for node in this.rootList {
				d := node.degree
				while table.Has(d) {
					other := table[d]
					if node.key > other.key {
						temp := node, node := other, other := temp
					}
					this.link(other, node)
					table.Delete(d)
					d++
				}
				table[d] := node
			}

			this.minNode := unset
			for _, node in table {
				newRoots.Push(node)
				if !this.HasOwnProp("minNode") || node.key < this.minNode.key
					this.minNode := node
			}

			this.rootList := newRoots
		}

		link(child, parent) {
			this.rootList := this.rootList.Filter((n) => n != child)
			child.parent := parent
			parent.children.Push(child)
			parent.degree++
			child.mark := false
		}
	}  
}

class Graph {
	nodes := Map()
	maxID := ""
	minID := ""
	isDirected := false
	isWeighted := false
	hasFlow := false

	/**
	 * Creates a new graph instance
	 * @param isDirected Whether the Graph is directed
	 * @param isWeighted 
	 * @param hasFlow 
	 */
	__New(isDirected?, isWeighted?, hasFlow?) {
		if (IsSet(isDirected))
			this.isDirected := isDirected
		if (IsSet(isWeighted))
			this.isWeighted := isWeighted
		if (IsSet(hasFlow))
			this.hasFlow := hasFlow
	}

	getNode(id?) {
		if (IsSet(id))
			return this.nodes[id]
		for i, node in this.nodes
			return node
	}
	

	/**
	 * 
	 * @param {Integer?} nodeID The ID of the node
	 * @param nodeName 
	 * @returns {Graph.Node} The created node 
	 */
	addNode(nodeID?, nodeName?) {
		if (IsSet(nodeID)) {
			if (this.nodes.Has(nodeID))
				throw(Error(Format("Node {} already exists.", nodeID)))
		} else
			nodeID := IsInteger(this.maxID) ? this.maxID + 1 : 1
		if IsInteger(this.maxID) ? nodeID > this.maxID : true
			this.maxID := nodeID
		if IsInteger(this.minID) ? nodeID < this.minID : true
			this.minID := nodeID
		this.nodes[nodeID] := Graph.Node(nodeID, nodeName?)
		return this.nodes[nodeID]
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
	 * Add an edge to a graph. This will register the edge for node head (and if undirected, also for tail)
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
	 * Merges given Graph into current graph, resulting in a graph containing all nodes and edges specified in either graph. 
	 * Edge properties from current graph are not updated, only missing ones are. (Unless specified in option)
	 * @param {Graph} g2 
	 * @param {Boolean} updateProps Whether to update edge properties
	 * @returns {Graph} 
	 */
	mergeGraph(g2) {
		for nodeID, node in g2.nodes
			if !this.nodes.has(nodeID)
				this.addNode(nodeID)
		for nodeID, node in g2.nodes {
			for edgeEndID, edge in node.getEdges()
				this.nodes[nodeID].addEdge(this.nodes[edgeEndID], edge.getAllProperties()*)
		}
	}

	/**
	 * Adds another graph to this graph, without connecting any edges
	 * @param g2 
	 */
	addGraph(g2) {
		if this.maxID < g2.minID || g2.maxID < this.minID { ; no overlap
			for nodeID, node in g2.nodes
				projectedNode := this.addNode(nodeID)
			for nodeID, node in g2.nodes
				for edgeEndID, edge in node.edges
					this.nodes[nodeID].addEdge(this.nodes[edgeEndID], edge.getAllProperties()*)
		} else {
			offset := this.maxID - g2.minID + 1
			for nodeID, node in g2.nodes
				projectedNode := this.addNode(offset + nodeID)
			for nodeID, node in g2.nodes
				for edgeEndID, edge in node.edges
					this.nodes[offset + nodeID].addEdge(this.nodes[offset + edgeEndID], edge.getAllProperties()*)
		}
		return this
	}

	/**
	 * Creates a string representing the Graph Object that can be used when saving Graphs
	 * @param {Integer} pretty Whether to make the output human-readable. If this is true, the output will be more understandable, but cannot be parsed by GraphUtils.loadfromFile
	 * @returns {String} 
	 */
	toString(pretty := true) {
		str := this.nodes.Count ", " (this.isDirected ? "Directed" : "Undirected") ", " (this.isWeighted ? "Weighted" : "Unweighted") ", " (this.hasFlow ? "Flow" : "No Flow") "`n"
		seenNodes := Map()
		for nodeID, node in this.nodes {
			uniqueEdges := Map()
			seenNodes[nodeID] := true
			for j, edge in node.edges {
				edgeProperties := (edge.HasOwnProp("weight") ? (pretty?'W:':'') edge.weight ' ' : "") 
					. (this.HasOwnProp("capacity") ? (pretty?'C:':'') edge.capacity ' ' : "") 
					. (this.HasOwnProp("flow") ? (pretty?'F:':'') edge.flow : "")
				if (uniqueEdges.Has(edgeProperties))
					uniqueEdges[edgeProperties].push(edge.tail.id)
				else
					uniqueEdges[edgeProperties] := [edge.tail.id]
			}
			nodeStr := node.allNeighbours.Count > 0 ? "" : nodeID
			for edgeProperties, edges in uniqueEdges {
				edgeStr := ""
				for tailID in edges {
					seenNodes[tailID] := true
					edgeStr .= tailID "-"
				}
				nodeStr .= nodeID (pretty ? '->': ' ') RTrim(edgeStr, "-") ' ' edgeProperties "`n"
			}
			str .= nodeStr == "" ? "" : RTrim(nodeStr, "`n") . "`n"
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


		getID() {
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
