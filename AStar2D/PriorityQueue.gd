var priority_queue = []
var is_max = true

func Make(max : bool = true):
	is_max = max
	priority_queue = []

func Size()->int:
	return priority_queue.size()

func Empty()->bool:
	return priority_queue.is_empty()

func Top():
	if Empty(): return null
	return priority_queue[0]

func Push(item):
	priority_queue.push_back(item)
	

func Pop():
	var top = Top()
	if top == null: 
		return null
	var back = priority_queue.back()
	priority_queue[0] = priority_queue.back()
	priority_queue.pop_back()
	if(!Empty()): Heapify(0)
	return top


func Heapify(cur):
	var target = cur
	var left = cur * 2 + 1
	var right = cur * 2 + 2
	
	if left < priority_queue.Size() and ((is_max and priority_queue[target].pqval < priority_queue[left].pqval) or (not is_max and priority_queue[target].pqval > priority_queue[left].pqval)):
		target = left
	if left < priority_queue.Size() and ((is_max and priority_queue[target].pqval < priority_queue[left].pqval) or (not is_max and priority_queue[target].pqval > priority_queue[left].pqval)):
		target = right
	if target != cur:
		swap(target, cur)
		Heapify(target)

#func /

func swap(a, b):
	var t = priority_queue[b]
	priority_queue[b] = priority_queue[a]
	priority_queue[a] = t
