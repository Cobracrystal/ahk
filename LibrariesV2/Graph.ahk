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
	 * Finds path between start and end with minimal amount of edges crossed.
	 * @param {Graph} g 
	 * @param {Graph.Node} start 
	 * @param {Graph.Node} end 
	 * @returns {Bool} 
	 */
	static findPath(g, start, end) {
		reverseTree := Graph(true) 
		reverseTree.addNode(start.id)
		stack := [start]
		visited := Map()
		while (stack.Length > 0) {
			node := stack.RemoveAt(1)
			visited[node.id] := true
			for nID, nNode in node.neighbours {
				if (!visited.Has(nID)) {
					stack.Push(nNode)
					rtNode := reverseTree.addNode(nID)
					rtNode.addEdge(reverseTree.nodes[node.id])
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
	 * Returns whether there is a path between node start and node end. Optionally specify whether to use DFS or BFS.
	 * @param graph 
	 * @param {Graph.Node} start 
	 * @param {Graph.Node} end 
	 * @param {Integer} dfs 
	 * @returns {Bool} 
	 */
	static isReachable(graph, start, end, dfs := 0) {
		stack := [start]
		visited := Map()
		while (stack.Length > 0) {
			node := (dfs ? stack.Pop() : stack.RemoveAt(1)) ; only difference between bfs and dfs
			visited[node.id] := true
			for nID, nNode in node.neighbours {
				if (nID == end.id)
					return true
				if (!visited.Has(nID))
					stack.Push(nNode)
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
		stack := [node]
		visited := Map()
		while (stack.Length > 0) {
			node := stack.Pop()
			visited[node.id] := true
			for nID, nNode in node.neighbours
				if (!visited.Has(nID))
					stack.Push(nNode)
		}
		return g.nodes.Count == visited.Count
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
		visited := Map()
		while (stack.Length > 0) {
			node := stack.Pop()
			visited[node.id] := node
			for nID, nNode in node.neighbours
				if (!visited.Has(nID))
					stack.Push(nNode)
		}
		for nodeID, n in visited
			cgi.addNode(nodeID)
		for nodeID, n in visited
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
					arborescence.addEdge(nodeAr, nNodeAr, edge.getProperties()*)
				}
		}
		return arborescence
	}
}

class Graph {
	nodes := Map()
	isDirected := false
	isWeighted := false
	hasFlow := false

	__New(isDirected := true) {
		this.isDirected := isDirected
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
					if !(this.nodes.Has(A_Index)) {
						nodeID := A_Index
						break
					}
				}
		}
		return (this.nodes[nodeID] := Graph.Node(nodeID))
	}

	/**
	 * Projects a node from other graph H onto this graph, removing any edges to nodes which do not exist here.
	 * Node with same ID may already exist, in which case the edges are updated accordingly.
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
				this.addEdge(newNode, this.nodes[nID], edge.getProperties()*)
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

	loadFromFile(fileName) {
		f := FileOpen(fileName, "r")
		options := f.ReadLine()
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
			for i, e in nodeNeighbours
				nodeNeighbours[i] := Integer(e) ; ERROR CHECKING CAN COME LATER.
			if (this.nodes.Has(nodeID))
				neighbours[nodeID].push(nodeNeighbours*)
			else {
				this.nodes[nodeID] := Graph.Node(nodeID)
				neighbours[nodeID] := nodeNeighbours
			}
		}
		for nodeID, nodeNeighbours in neighbours
			for neighbourID in nodeNeighbours {
				if !(this.nodes.Has(neighbourID))
					this.nodes[neighbourID] := Graph.Node(neighbourID)
				this.nodes[nodeID].addEdge(this.nodes[neighbourID])
				if (!this.isDirected)
					this.nodes[neighbourID].addEdge(this.nodes[nodeID])
			}
	}
	; load in graph
	; -> build the graph by iterating over all nodes in the order that they are given, ignoring all nodes given only by connection
	; -> then, when we have all node objects, we initialize the node objects with their connected nodes by iterating over their saved node IDs.
	; -> then, we iterate over all edges and add them to the graph

	class Node {
		edges := Map()
		neighbours := Map()

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
			this.edges[tail.id] := Graph.Edge(this, tail, weight?, capacity?, flow?)
			return 1
		}

		/**
		 * Removes the given *directed* edge
		 * @param {Graph.Node} tail 
		 * @returns {Integer} 
		 */
		removeEdge(tail, isDirected := true) {  
			if (this.hasNeighbour(tail.id)) {
				node := this.neighbours.Delete(tail.id)
				this.edges.Delete(tail.id)
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

		hasNeighbour(node) { ; -> boolean
			return this.neighbours.Has(node)
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

		getProperties() {
			return [this.HasOwnProp("weight") ? this.weight : unset,
					this.HasOwnProp("capacity") ? this.capacity : unset,
					this.HasOwnProp("flow") ? this.flow : unset	]
		}
	}
}
