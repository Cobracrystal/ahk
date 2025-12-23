#Include "%A_LineFile%\..\..\LibrariesV2\PrimitiveUtilities.ahk"

/**
 * Counts how many times a given value is included in an Object
 * @param obj array or map
 * @param value value to check for
 * @returns {Integer} Count of how many instances of value were encountered
 */
objCountValue(obj, value, conditional := (itKey,itVal,setVal) => (itVal = setVal)) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objCountValue does not handle type " . Type(obj)))
	count := 0
	for i, e in objGetEnumerator(obj)
		if conditional(i, e, value)
			count++
	return count
}

/**
 * Checks whether obj contains given value and returns index if found, else 0
 * @param obj 
 * @param value 
 * @param {Func} comparator 
 * @returns {Integer} 
 */
objContainsValue(obj, value, fn := (v => v)) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objContainsValue does not handle type " . Type(obj)))
	for i, v in objGetEnumerator(obj)
		if fn(v) == value
			return i
	return 0
}

/**
 * Checks whether obj contains given value and returns index if found, else 0
 * @param obj 
 * @param value 
 * @param {Func} comparator 
 * @returns {Integer} 
 */
objContainsMatch(obj, match := (itKey,itVal) => (true), retAllMatches := 0) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objContainsMatch does not handle type " . Type(obj)))
	lambda := match.MaxParams == 1 ? (i, e) => match(e) : (i, e) => match(i, e)
	if retAllMatches {
		arr := []
		for i, e in objGetEnumerator(obj)
			if (lambda(i, e))
				arr.push(i)
		return arr
	}
	for i, e in objGetEnumerator(obj)
		if (lambda(i, e))
			return i
	return 0
}

/**
 * Returns ObjOwnPropCount if obj is Object, else .Length or .Count for Array/Map if nonrecursive. Otherwise calls itself for each object in the given object.
 * @param obj 
 * @returns {Integer} 
 */
objGetValueCount(obj, recursive := false, countUnsetValues := true) {
	if !recursive {
		if countUnsetValues
			return obj is Map ? obj.Count : (obj is Array ? obj.Length : ObjOwnPropCount(obj))
		else
			return objgetsum(obj, a => 1)
	}
	if countUnsetValues
		return objGetSum(obj, (e?) => IsSet(e) && IsObject(e) ? objGetValueCount(e, true, true) : 1, (i,e?) => true)
	return objgetsum(obj, e => IsObject(e) ? objGetValueCount(e, true, countUnsetValues) : 1)
}

objGetRandomValue(obj) {
	isArrLike := (obj is Array || obj is Map)
	isArr := obj is Array
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objGetRandomValue does not handle type " . Type(obj)))
	r := Random(1, objGetValueCount(obj))
	if isArr
		return obj[r]
	for i, e in isArrLike ? obj : obj.ownprops()
		if A_Index == r
			return e
}

/**
 * Returns a deep copy of a given object.
 * @param obj A .Clone()-able object
 * @returns {Object} A deep clone of the given object
 */
objClone(obj) {
	encountered := Map()
	return _clone(obj)

	_clone(obj) {
		isArrLike := (obj is Array || obj is Map)
		if !(IsObject(obj))
			return obj
		if encountered.Has(ptr := ObjPtr(obj))
			return encountered[ptr]
		copy := obj.clone()
		encountered[ptr] := copy
		for i, e in objGetEnumerator(obj)
			for i, e in obj
				if IsObject(e)
					isArrLike ? copy[i] := _clone(e) : copy.%i% := _clone(e)
		return copy
	}
}
/**
 * Merges obj2 into obj1 or creates a new object if desired. Prefers obj1 keys over obj2 unless specified.
 * This only works for Maps and Objects. For merging arrays, use arrayMerge instead.
 * @param obj1 
 * @param obj2 
 * @param {Integer} createNew 
 * @param {Integer} overwriteIdenticalKeys 
 * @returns {Any} 
 */
objMerge(obj1, obj2, createNew := false, overwriteIdenticalKeys := false) {
	if (Type(obj1) != Type(obj2))
		throw(TypeError("obj1 and obj2 are not of equal type, instead " Type(obj1) ", " Type(obj2)))
	isMap := obj1 is Map
	obj := createNew ? objClone(obj1) : obj1
	for key, val in objGetEnumerator(obj2) {
		if (isMap) {
			if !obj.Has(key) || overwriteIdenticalKeys
				obj[key] := val
		}
		else if (!obj.HasOwnProp(key) || overwriteIdenticalKeys)
			obj.%key% := val
	}
	return obj
}

/**
 * Deletes given Value from Object {limit} times. Returns count of removed values
 * @param {Array | Map} obj
 * @param value the value to remove
 * @param {Integer} limit if 0, removes all
 * @param {Func} conditional
 * @param {Any?} EmptyValue to replace removed value with.
 * @returns {Integer} count
 */
objRemoveValue(obj, value := "", limit := 0, conditional := ((itKey, itVal) => (itVal = value)), emptyValue?) {
	_conditional := conditional.MaxParams == 3 ? conditional : (i, v, v2) => conditional(i, v)
	return objRemoveValues(obj, [value], limit, _conditional, emptyValue?)
}

/**
 * Deletes given Value from Object, either on first encounter or on all encounters. Returns count of removed values
 * @param obj 
 * @param values 
 * @param {Integer} limit 
 * @param {(iterator, value) => Number} comparator 
 * @param emptyValue If this is set, all encountered values are not removed, but instead replaced by this value.
 * @returns {Integer} 
 */
objRemoveValues(obj, values, limit := 0, conditional := ((itKey,itVal,setVal) => (itVal = setVal)), emptyValue?) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objRemoveValues does not handle type " . Type(obj)))
	queue := []
	count := 0
	for i, e in objGetEnumerator(obj)
		for f in values
			if conditional(i, e, f) {
				if (!limit || count++ < limit)
					queue.push(i)
				else
					break
			}
	n := queue.Length
	if (IsSet(emptyValue)) {
		for e in queue
			isArrLike ? obj[e] := emptyValue : obj.%e% := emptyValue
	} else {
		while (queue.Length != 0)
			isArrLike ? (isArr ? obj.RemoveAt(queue.Pop()) : obj.Delete(queue.Pop())) : obj.DeleteProp(queue.Pop())
	}
	return n
}

/**
 * Creates a new object containing only values matching filter.
 * @param obj 
 * @param {(k, v) => Boolean} filter 
 * @returns {Integer} 
 */
objFilter(obj, filter := (k, v) => (true)) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objRemoveValue does not handle type " . Type(obj)))
	clone := %Type(obj)%()
	if isArr
		clone.Capacity := obj.Length
	if isArr {
		for i, e in obj
			if filter(i, e)
				clone.push(e)
	} else if isArrLike {
		for i, e in obj
			if filter(i, e)
				clone[i] := e
	} else {
		for i, e in ObjOwnProps(obj)
			if filter(i, e)
				clone.%i% := e
	}
	return clone
}

objDoForEach(obj, fn := (v => toString(v)), conditional := (itKey?, itVal?) => true, useKeys := false) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objDoForEach does not handle type " . Type(obj)))
	clone := %Type(obj)%()
	if (isArrLike && !isMap)
		clone.Length := clone.Capacity := obj.Length
	for i, e in objGetEnumerator(obj) {
		t := useKeys ? i : e
		v := conditional(i, e?) ? fn(t?) : t
		if useKeys
			isArrLike ? clone[v] := e : clone.%v% := e
		else
			isArrLike ? clone[i] := v : clone.%i% := v
	}
	return clone
}

objGetMinimum(obj, fn := a => a) => objCollect(obj, (a,b) => Min(a,b), fn)
objGetMaximum(obj, fn := a => a) => objCollect(obj, (a,b) => Max(a,b), fn)
objGetSum(obj, fn := a => a, cond := (i,e?) => IsSet(e)) => objCollect(obj, (a,b) => (a+b), fn,, cond)
objGetAverage(obj, fn := a => a) => objGetSum(obj, fn) / objGetValueCount(obj)
objGetProd(obj, fn := a => a) => objCollect(obj, (a,b) => a*b, fn)
objCollectString(obj, separator := ",", fn := a => toString(a)) => objCollect(obj, (a,b) => (a separator b), fn)

objDoForEachRecursive(obj, fn := v => v, conditional := (itKey?, itVal?) => true, useKeys := false) {
	return recurse(obj)

	recurse(q) {
		return IsObject(q) ? objDoForEach(q, recurse, conditional, useKeys) : fn(q)
	}
}

/**
 * 
 * @param obj 
 * @param {Func} collector function responsible for collecting objects. Equivalent to fn(fn(....fn(fn(base,obj[1]),obj[2])...,obj[n-1]),obj[n])
 * @param {Func} transformer function responsible for transforming iterated elements into usable parameters for collector. Note that elements are not transformed when given to conditional.
 * @param {Any} initialBase Initial value of the base on which fn operates. If not given, first element in object becomes base. Set this if fn operators onto properties or items of enumerable values.
 * @param {Any} value Optional Value to check conditional upon
 * @param {Func} conditional Optional Comparator to determine which values to include in collection.
 * @returns {Any} Collected Value
 */
objCollect(obj, collector := ((base, e) => (base ", " e)), transformer := (a => a), initialBase?, conditional := (itKey, itVal?) => IsSet(itVal), useKeys := false) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	flagInitialBase := IsSet(initialBase)
	if (flagInitialBase) {
		base := initialBase
		j := 0
	} else {
		for i, e in objGetEnumerator(obj) {
			if !conditional(i,e?)
				continue
			base := useKeys ? transformer(i) : transformer(e)
			j := i
			break
		}
	}
	for i, e in objGetEnumerator(obj) {
		if i <= j && !flagInitialBase
			continue
		if (conditional(i, e?))
			base := (useKeys ? collector(base, transformer(i?)) : collector(base, transformer(e?)))
	}
	return base ?? ""
}

/**
 * Flattens obj into an array of either keys or values
 * @param obj 
 * @param {(e) => void} fn 
 * @param {Integer} keys 
 * @returns {Array} 
 */
objFlatten(obj, fn := (e => e), keys := false) {
	arr := []
	for key, e in objGetEnumerator(obj)
		arr.push(keys ? fn(key) : fn(e))
	return arr
}

/**
 * 
 * @param obj 
 * @param {(a) => void} fn Function to get value to compare for duplications. Ie for [{x:1,y:5},{x:4,y:5}] specify (a) => (a.y) to get entries where y is the same
 * @param {Integer} caseSense Whether comparison is case-sense strict or not
 * @param {Integer} grouped Determines whether to group indices by their value
 * @returns {Array} If grouped, array of arrays of indices of duplicate values, sorted alphanumerically by value. Otherwise, sorted array of indices of duplicate values
 */
objGetDuplicates(obj, fn := (a => a), caseSense := true, grouped := false) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	duplicateMap := Map()
	counterMap := Map()
	duplicateIndices := []
	duplicateMap.CaseSense := caseSense
	for i, e in objGetEnumerator(obj) {
		v := fn(e)
		if (duplicateMap.Has(v)) {
			duplicateMap[v].push(i)
			counterMap[v] := 1
		}
		else
			duplicateMap[v] := [i]
	}
	if grouped {
		for i, e in duplicateMap
			if e.Length > 1
				duplicateIndices.push(e)
	}
	else
		for i, e in objGetEnumerator(obj) {
			v := fn(e)
			if (duplicateMap[v].Length > 1)
				duplicateIndices.push(duplicateMap[v][counterMap[v]++])
		}
	return duplicateIndices
}

/**
 * 
 * @param obj Object to search duplicates in
 * @param {(a) => (a)} fn Function to get value to compare for duplications. Ie for [{x:1,y:5},{x:4,y:5}] specify (a) => (a.y) to get entries where y is the same
 * @returns {Object} CLONE of obj without duplicates
 */
objRemoveDuplicates(obj, fn := (a => a), caseSense := true) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	duplicateMap := Map()
	duplicateMap.CaseSense := caseSense
	for i, e in objGetEnumerator(obj) {
		v := fn(e)
		if (duplicateMap.Has(v))
			duplicateMap[v]++
		else
			duplicateMap[v] := 1
	}
	clone := %Type(obj)%()
	for i, e in objGetEnumerator(obj) {
		v := fn(e)
		if (duplicateMap[v] == 1)
			isArrLike ? (isMap ? clone[i] := e : clone.push(e)) : clone.%i% := e
	}
	return clone
}

objGetUniques(obj, fn := (a => a), caseSense := true) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	uniques := Map()
	uniques.CaseSense := caseSense
	clone := %Type(obj)%()
	for i, e in objGetEnumerator(obj) {
		if !IsSet(e)
			continue
		v := fn(e)
		if !(uniques.Has(v)) {
			uniques[v] := true
			isArrLike ? (isMap ? clone[i] := e : clone.push(e)) : clone.%i% := e
		}
	}
	return clone
}

/**
 * Given two objects, returns a clone of obj2 where all values that are also present in obj1 are deleted
 * @param obj1 
 * @param obj2 
 * @param {(a) => void} fn 
 * @param {Integer} caseSense 
 */
objGetComparedUniques(obj1, obj2, fn := (a => a), caseSense := true) {
	isArrLike := (obj2 is Array || obj2 is Map)
	isMap := (obj2 is Map)
	if !(isArrLike || IsObject(obj2))
		throw(TypeError("objForEach does not handle type " . Type(obj2)))
	appeared := Map()
	appeared.CaseSense := caseSense
	clone := %Type(obj2)%()
	for i, e in objGetEnumerator(obj1)
		appeared[fn(e)] := true
	for i, e in objGetEnumerator(obj2) {
		v := fn(e)
		if !(appeared.Has(v)) {
			isArrLike ? (isMap ? clone[i] := e : clone.push(e)) : clone.%i% := e
		}
	}
	return clone
}

/**
 * Returns true if obj1 and obj2 share the same keys and values and type, 0 otherwise. Does not check for inherited values or Prototype values being different.
 * ```
 * obj1 := {x: 1, y: Map(1,2)}
 * obj2 := {x: 1, y: Map(1,2)}
 * objCompare(obj1, obj2) == true
 * obj2.y.CaseSense := "Off"
 * objCompare(obj1, obj2) == false
 * objCompare(Number.Prototype, 5) == true
 * ```
 * @param obj1 
 * @param obj2 
 */
objCompare(obj1, obj2) {
	if (Type(obj1) != Type(obj2))
		return 0
	if !(IsObject(obj1))
		return (obj1 == obj2)
	isObj := !(obj1 is Array || obj1 is Map)
	isMap := (obj1 is Map)
	count1 := isObj ? ObjOwnPropCount(obj1) : (isMap ? obj1.Count : obj1.Length)
	count2 := isObj ? ObjOwnPropCount(obj2) : (isMap ? obj2.Count : obj2.Length)
	if (count1 != count2)
		return 0
	for i, j, e, f in objZip(obj1, obj2) {
		if (i != j)
			return 0
		if !objCompare(e, f)
			return 0
	}
	return 1
}

objEnumIf(obj, conditional := (e?) => IsSet(e?)) {
	objEnum := objGetEnumerator(obj, true)
	index := 1
	return _enumerate

	_enumerate(&i, &j:= -1, &e := -1) {
		flag2Var := !IsSet(j)
		flag3Var := !IsSet(e)
		flagNotAtEnd := flag2Var ? objEnum(&k, &f) : objEnum(&_, &f)
		if flagNotAtEnd {
			while(!conditional(f) && flagNotAtEnd)
				flagNotAtEnd := flag2Var ? objEnum(&k, &f) : objEnum(&_, &f)
			flag3Var ? (i := index++, j := k, e := f) : flag2Var ? (i := k, j := f) : i := f
		}
		return flagNotAtEnd
	}
}

/**
 * Zips two objects as a combined enumerator. Can accept 2-4 parameters. 
 * @param obj1 Object 1
 * @param obj2 Object 2 (Must be of same Type as Object 1)
 * @param {Integer} stopAtAnyEnd Whether to stop enumerating on encountering ANY end in the objects or whether to stop after ALL ends have been reached (will return unset for ended objects)
 * @returns {Enumerator} Func(&i, &j, &n := -1, &m := -1) Accepts up to 4 parameters. 
 * If two params are given, enumerates both objects values.
 * If three params are given, enumerates the total index and both objects values.
 * If four params are given, enumerates respective key and value of both objects: i = obj1Index, j = obj2Index, n = obj1Value, m = obj2Value
 */
objZip(obj1, obj2, stopAtAnyEnd := true) {
	if (Type(obj1) != Type(obj2))
		throw(TypeError("obj1 and obj2 are not of equal type, instead " Type(obj1) ", " Type(obj2)))
	obj1Enum := objGetEnumerator(obj1, true)
	obj2Enum := objGetEnumerator(obj2, true)
	index := 1
	return (&i, &j, &n := -1, &m := -1) => (
		flag3Var := !IsSet(n), ; if for-loop passes n to this function, then it is unset. otherwise it is set.
		flag4Var := !IsSet(m),
		flagObj1End := flag4Var ? obj1Enum(&i, &n) : (flag3Var ? (i := index++, obj1Enum(&_, &j)) : obj1Enum(&_, &i)),
		flagObj2End := flag4Var ? obj2Enum(&j, &m) : (flag3Var ? obj2Enum(&_, &n) 				  : obj2Enum(&_, &j)),
		stopAtAnyEnd ? flagObj1End && flagObj2End : flagObj1End || flagObj2End
	)
}

/**
 * Zips any amount of objects into a combined enumerator, where each enumerated value is an array containing the currently enumerated value for each object..
 * @param objects Variadic amount of objects. Need not be of the same type.
 * @returns {Enumerator} Func(&i, &e := -1, &f := -1) Accepts up to 3 Parameters.
 * If only 1 Parameter is given, enumerates values in all objects simultaneously and gives an array of these values.
 * If two are given, enumerates index and all values.
 * If three are given, enumerates index, an array of the current keys for all objects and an array of corresponding values. 
 */
objZipAsArray(objects*) {
	len := objects.Length
	index := 1
	enums := []
	for o in objects
		enums.push(objGetEnumerator(o, true))
	return (&i, &e := -1, &v := -1) => (
		flag2Var := !IsSet(e), ; if for-loop passes n to this function, then it is unset. otherwise it is set.
		flag3Var := !IsSet(v),
		arrVals := [], arrVals.Capacity := len,
		flag3Var ? (arrKeys := [], arrKeys.Capacity := len) : 0,
		arrResult := flag3Var ? objDoForEach(enums, (en) => (flag := en(&l, &r), arrKeys.push(l?), arrVals.push(r?), flag)) : objDoForEach(enums, (en) => (flag := en(&_, &r), arrVals.push(r?), flag)),
		flagIsAtEnd := objCollect(arrResult, (a, b) => a || b),
		flag2Var ? (i := index++, flag3Var ? (e := arrKeys, v := arrVals) : e := arrVals) : i := arrVals,
		flagIsAtEnd
	)
}

/**
 * Enumerates given objects one after another. 
 * @param objects Variadic chain of objects, can be mixed between obj/arr/map etc.
 * @returns {Enumerator} Func(&i, &j := -1, &e := -1). Accepts up to 3 parameters. 
 * If only 1 parameter is given, enumerates values. 
 * If two are given, enumerates total index and values. 
 * If three are given, enumerates total index, the current objects' index/key and values.
 */
objChain(objects*) {
	enums := []
	for o in objects
		enums.push(objGetEnumerator(o, true))
	len := enums.Length
	index := 1
	objIndex := 1
	return (&i, &j := -1, &e := -1) => (
		flag2Var := !IsSet(j),
		flag3Var := !IsSet(e),
		enum := enums[objIndex],
		flagReachedObjEnd := !(flag2Var ? (i := index++, flag3Var ? enum(&j,&e) : enum(&_, &j)) : enum(&_, &i)),
		flagReachedObjEnd ? objIndex++ : 0,
		flagLastObjEnd := objIndex > len,
		flagReachedObjEnd && !flagLastObjEnd ? enum := enums[objIndex] : 0,
		flagReachedObjEnd && !flagLastObjEnd ? (flag2Var ? (flag3Var ? enum(&j,&e) : enum(&_, &j)) : enum(&_, &i)) : 0,
		!flagLastObjEnd
	)
}

objGetEnumerator(obj, getEnumFunction := false, numberParams?) {
	enum := (obj is Array || obj is Map || obj is ComValue) ? obj : ObjOwnProps(obj)
	if !getEnumFunction
		return enum
	try
		enum := enum.__Enum(numberParams?)
	return enum
}

objGetBaseChain(obj) {
	base := obj
	arr := [base]
	while (base)
		arr.push(base := ObjGetBase(base))
	return arr
}

objGetClassObject(obj) {
	loop((cNames := StrSplit(obj.__Class, ".")).Length) ; if className is eg. Gui.Control, we can't do %Gui.Control%, instead do %Gui%.%Control%
		classObj := A_Index == 1 ? %cNames[1]% : classObj.%cNames[A_Index]%
	return classObj
}


; Aliases for shorthand options
ToStringNoBases(obj, detailedFunctions := false)	=>	toString(obj, , false, , , , true, detailedFunctions, true, false)
ToStringFull(obj, detailedFunctions := false)	=>	toString(obj, , false, , , , true, detailedFunctions, true, true)
ToStringClass(obj, detailedFunctions := false)	=>	toString(obj, , false, , , , true, detailedFunctions, false, false)
/**
 * Return a json-like representation of the given variable, with selectable level of detail.
 * @param {Any} obj Any Value.
 * @param {Integer} [compact] If true, returned String will not contain newlines of any kind. Otherwise, obj will be expanded by its inner values, with the level of expansion set by compress
 * @param {Integer} [compress] If true, returned String will not contain spaces (or indent) and objects with only primitive values or only one inner value will not be expanded.
 * @param {Integer} [strEscape] If true, will escape any values with quotation marks (with the exception of pure numbers). If not set, is false only when obj is an instance and the other flags are false or not set
 * @param {Integer} [anyAsObj] If true, all objects will be printed in the form of { key: value, ... }. Note that if either withInheritedProps or withClassOrPrototype are set to true, then this will default to true, since it is not feasible to put both enumerated values in map form (Map("key", "value")) and properties (Map().CaseSense: "On") or Array Form ([1,2,3]) and properties (Array().Length) in the same object.
 * @param {String} [spacer] String used to indent nested objects (if not compressed)
 * @param {Boolean} [withInheritedProps] Whether to print Values of Properties that are not OwnProps, but inherited from class- or Prototype-Objects. If not set, automaticaly chosen depending on if obj has any values to print and if it is an instance of a class
 * @param {Boolean} [detailedFunctions] Whether to print functions as "Name": "Func" or whether to print Func properties such as MinParams, IsVariadic etc.
 * @param {Boolean} [withClassOrPrototype] Whether to print the class object of an instance, and the Prototype of a class Object
 * @param {Boolean} [withBases] Whether to print the .Base property. If true,any object will have its Base Chain printed up to Any.Prototype. Does NOT print class.Prototype.base, instead only class.base.Prototype (to avoid printing duplicate information), and furthermore does not print Class.Prototype, Object.Prototype, Any.Prototype at all (since they are included in the base chain anyway, since Any.Base == Class.Prototype)
 * @returns {String} The string representing the object
 */
toString(obj, compact := false, compress := true, strEscape := false, mapAsObj := true, spacer := "`t", withInheritedProps?, detailedFunctions?, withClassOrPrototype?, withBases?) {
	if obj is VarRef || obj is ComValue {
		return "{}"
	} else if IsObject(obj) {
		origin := obj
		flagFirstIsInstance := (Type(obj) != "Prototype" && Type(obj) != "Class" && Type(objgetbase(obj)) == "Prototype") ; equivalent to line below
		; if obj is an instance of a class, and it isnt enumerable, and it doesn't have any own props, then try getting inheritables
		flagIncludeInheritedProps :=	withInheritedProps		?? (flagFirstIsInstance && !obj.HasMethod("__Enum") && ObjOwnPropCount(obj) == 0)
		flagDetailedFunctions := 		detailedFunctions		?? !flagFirstIsInstance ; (flagFirstIsInstance && Type(obj) != "Func" ? 0 : 1)
		flagIncludeClassOrPrototype := 	withClassOrPrototype	?? !flagFirstIsInstance
		flagWithBases := 				withBases 				?? !flagFirstIsInstance
		strEscape := 					strEscape				?? (!flagFirstIsInstance || flagIncludeClassOrPrototype || flagWithBases)
		overrideAsObj := (flagIncludeClassOrPrototype || flagIncludeInheritedProps)
	}
	encounteredObjs := Map() ; to avoid self-reference loops
	return _toString(obj, 0)

	_toString(obj, indentLevel, flagOverrideStrEscape := false, flagIsOwnPropDescObject := false) {
		static escapes := [["\", "\\"], ['"', '\"'], ["`n", "\n"], ["`r", "\r"], ["`t", "\t"]]
		qt := strEscape || flagOverrideStrEscape ? '"' : ''
		if !(IsObject(obj)) { ; if obj is Primitive, no need for the entire rest.
			if (obj is Number)
				return String(obj)
			if (IsNumber(obj))
				return qt obj qt
			if (strEscape || flagOverrideStrEscape) {
				for e in escapes
					obj := StrReplace(obj, e[1], e[2])
				return qt String(obj) qt
			}
			return obj
		}
		if (encounteredObjs.Has(ObjPtr(obj)))
			return "<DUPLICATE REF> Type " Type(obj) ' @ ' ObjPtr(obj)
		encounteredObjs[ObjPtr(obj)] := true
		; for very small objects, this may be excessive to do, but it would be very messy otherwise
		objType := Type(obj)
		flagIsMap := obj is Map
		flagIsArr := obj is Array
		flagIsObj := ((!flagIsArr && !flagIsMap) || objType == "Prototype" ? 1 : 0)
		flagIsInstance := (objType != "Prototype" && objType != "Class" && Type(ObjGetBase(obj)) == "Prototype") ; we could also check whether obj doesn't have the proprety Prototype, but that relies on the object not being Primitive/Any
		indent := (compress || compact)  ? '' : strMultiply(spacer, indentLevel)
		trspace := compress ? "" : A_Space
		separator := (compact || compress) ? trspace : '`n' indent . spacer
		sep2 := (compact || compress) ? trspace : '`n' indent
		count := objGetValueCount(obj, false)
		className := obj.__Class
		str := ""
		if (flagIsInstance) {
			if (obj.HasMethod("__Enum")) ; enumerate own properties
				for k, v in obj
					strFromCurrentEnums(k, v?, true)
			; get OwnProps and inherited Properties (depending on the flag)
			; Ignores .Prototype and .__Class (Prototype later and .__Class is present multiple times)
			strFromAllProperties(flagIncludeInheritedProps ? -1 : 0)
			; now, add .__Class for the current object
			if (flagIncludeClassOrPrototype && !flagIsOwnPropDescObject)
				strFromCurrentEnums("__Class", className)
			if (flagWithBases) ;  && obj == origin)
				strFromCurrentEnums("Base", obj.base)
			; this would get the class object from an instance. why would we need this?
			; if !(flagIsOwnPropDescObject || flagIsBadFunction || !flagIncludeClassOrPrototype)
			;	strFromCurrentEnums("Class_Object", objGetClassObject(obj))
		} else {
			for k in ObjOwnProps(obj) {
				if (!flagIncludeClassOrPrototype && k == "Prototype")
					continue
				if (obj.HasMethod("GetOwnPropDesc") && (propertyObject := obj.GetOwnPropDesc(k)).HasMethod("Get") && (propertyObject.get.MinParams > 1 || objType == "Prototype"))
					strFromCurrentEnums(k, propertyObject,, true) ; cannot get obj.%k% since it requires parameters. If we don't have getownpropdesc, there will not be issues (unless this is a primitive value with a property that requires params ?)
				else if (k == "Prototype" && (obj.Prototype.__Class == "Class" || obj.Prototype.__Class == "Object" || obj.Prototype.__Class == "Any"))
					strFromCurrentEnums(k, obj.Prototype.__Class ".Prototype")
				else
					strFromCurrentEnums(k, (!flagDetailedFunctions && Type(obj.%k%) == "Func") ? Type(obj.%k%) : obj.%k%)
			}
			; non-prototypes (class objects) should get their base. for class.prototype, object.prototype we need their base since there isn't a way to get it otherwise. any.prototype is empty and is also enumerated above.
			flagIsGoodPrototype := objType == "Prototype" ; (objType != "Prototype" || (objType == "Prototype" && (className == "Class" || className == "Object")))
			if (flagWithBases) {
				if (flagIsGoodPrototype)
					strFromCurrentEnums("Base", ObjGetBase(obj))
				else if className != "Any" ; we are a bad prototype and only get a String base. If we are Any.Prototype, we get no base at all. D:
					strFromCurrentEnums("Base", obj.base.__Class ".Prototype")
			}
		}
		wrapper := overrideAsObj ? ["{", "}"] : ( flagIsArr ? ["[", "]"] : ( mapAsObj ? ["{", "}"] : ["Map(", ")"]))
		return (wrapper[1] . (str == '' ? '' : separator) . RegExReplace(str, "," separator "$") . (str == '' ? '' : sep2) . wrapper[2])

		strFromCurrentEnums(k, v?, overrStrEscape?, isOwnPropDescObject?) {
			if (!compact && compress)
				separator := sep2 := isSimple(v?) ? trspace : '`n'
			if !(IsSet(v)) ; must be array, obj/map keys cannot be unset
				str := RTrim(str, separator) "," separator
			else if (overrideAsObj || flagIsObj || (mapAsObj && flagIsMap))
				str .= _toString(k ?? "", indentLevel + 1, true) (flagIsMap && !mapAsObj ? "," : ":") trspace _toString(v ?? "", indentLevel + 1,, isOwnPropDescObject?) "," separator
			else
				str .= _toString(v ?? "", indentLevel + 1, flagOverrideStrEscape?) "," separator
		}

		strFromAllProperties(maxDepth := -1) {
			base := obj
			depth := 0 ; maxDepth == -1 -> get all properties, maxDepth == 0 -> get only own, == n -> get own and n level deep
			while (base) {
				if (!base || base.__Class == "Any")
					break
				for k in ObjOwnProps(base) {
					if (k == "__Class" || k == "Prototype")
						continue
					propdesc := base.GetOwnPropDesc(k)
					flag := propdesc.HasProp("Value") || (propdesc.HasMethod("get") && propdesc.get.MinParams < 2) ; 1 or 0 because class Methods have (this)
					if flag
						strFromCurrentEnums(k, (!flagDetailedFunctions && Type(obj.%k%) == "Func") ? Type(obj.%k%) : obj.%k%)
				}
				if (maxDepth == depth++)
					break
				base := ObjGetBase(base)
			}
		}

		isSimple(v?) {
			if !IsSet(v)
				return 1
			if !IsObject(v)
				return 1
			if count == 1 && objGetValueCount(v) < 2
				return 1
			return 0
		}
	}
}

varsToString(vars*) => toString(vars,0,1,1)

; Unreliable, may only work in ahk versions around ~2.0.9
BoundFnName(Obj) {
	Address := ObjPtr(Obj)
	n := NumGet(Address, 5 * A_PtrSize + 16, "Ptr")
	Obj := ObjFromPtrAddRef(n)
	return Obj.Name
}

range(startOrEnd, end?, step?, inclusiveEnd := true) {
	start := IsSet(end) ? startOrEnd : 1
	end := end ?? startOrEnd
	step := step ?? 1
	backwards := step < 0
	if backwards && end > startOrEnd
		throw ValueError('Positive Range with negative step')
	index := 1
	return (&n, &m := -1) => (
		!IsSet(m) ? 
			(n := index++, m := start, start += step, backwards ? (inclusiveEnd ? m >= end : m > end) : inclusiveEnd ? m <= end : m < end) : 
			(n := start, start += step, backwards ? (inclusiveEnd ? n >= end : n > end) : inclusiveEnd ? n <= end : n < end)
	)
}

rangeAsArr(startEnd, end?, step?, inclusive := true) {
	local arr := []
	arr.Capacity := Floor(Abs((end ?? 0) - startEnd) * 1/(step??1)) + inclusive
	for e in range(startEnd, end?, step?, inclusive)
		arr.push(e)
	return arr
}

arrayMerge(arrs*) {
	ret := []
	len := 0
	for arr in arrs
		len += arr.length
	ret.Capacity := len
	for arr in arrs
		ret.push(arr*)
	return ret
}

/**
 * Performs (iterative) mergesort on the array nums. Nums will not be operated on.
 * @param {Array} nums Array of values
 * @param {Func} comparator (a,b) => (a <= b) or any other comparator function which returns TRUE if a should be sorted BEFORE b and FALSE otherwise. 
 * @returns {Array} 
 */
arrayMergeSort(nums, comparator := (a,b) => (a <= b)) { ; iterative mergesort
	len := nums.length
	res := []
	res.Length := len
	sliceLen := 1
	while(sliceLen <= len) {
		c := 1
		while (c <= len) {
			i := c
			j := indexB := min(c + sliceLen, len)
			lastIndex := min(c + 2 * sliceLen - 1, len)
			Loop(lastIndex - c + 1) {
				k := c + A_Index - 1
				if (i < indexB && (j > lastIndex || comparator(nums[i], nums[j])))
					res[k] := nums[i++]
				else
					res[k] := nums[j++]
			}
			c += 2 * sliceLen
		}
		sliceLen *= 2
		nums := res.clone()
	}
	return res
}

/**
 * Merges two (ascending) sorted arrays into one efficiently.
 * @param arr1 
 * @param arr2 
 * @returns {Array} 
 */
arrayMergeSorted(arr1, arr2) {
	ret := []
	p1 := 1, p2 := 1
	l1 := arr1.Length, l2 := arr2.Length
	while(p1 <= l1 || p2 <= l2) {
		if (p1 < l1 && (p2 >= l2 || arr1[p1] <= arr2[p2]))
			ret.push(arr1[p1++])
		else
			ret.push(arr2[p2++])
	}
	return ret
}

/**
 * Verifies that an array is numerically sorted. By default, checks that each successive element is larger than its predecessor.
 * @param arr 
 * @param {Integer} downwards 
 * @returns {Integer} 
 */
arrayIsSorted(arr, downwards := false) {
	if downwards {
		Loop(arr.Length - 1)
			if arr[A_Index] < arr[A_Index + 1]
				return false
		return true
	}
	Loop(arr.Length - 1)
		if arr[A_Index] > arr[A_Index + 1]
			return false
	return true
}

/**
 * For an array subset whose values are all contained in arr, and a value contained in arr, inserts the value in the position defined through the ordering in set.
 * @description This essentially just re-creates the ordering in arr into subarr. eg if subarr contained 1,2,5, and arr contains 1,2,3,4,5,6, and we call arrInsertSorted with the value 4, it would be inserted in subarr to the result of [1,2,4,5] because that's where 4 is located in arr.
 * @param arr 
 * @param subarr 
 * @param compareValue 
 * @param insertValue 
 * @param {(itVal, compVal) => Number} comparator 
 * @returns {Integer} Index of the inserted element
 */
arrayInsertSorted(arr, subarr, compareValue, insertValue := compareValue, transformer := (itVal => itVal)) {
	next := 1
	for i, e in arr {
		if (transformer(e) == compareValue || next > subarr.Length) {
			subarr.InsertAt(next, insertValue)
			break
		}
		if transformer(e) == transformer(subarr[next])
			next++
	}
	return next
}

/**
 * Slices the given array arr and returns a new array starting at index [from] until index [to]. 
 * @param arr 
 * @param {Integer} from 
 * @param {Integer} to 
 * @returns {Array} 
 * @example arraySlice(["a","b","c","d","e"], 2) => ["b","c","d","e"]
 * arraySlice(["a","b","c","d","e"], 1,3) => ["a","b","c"]
 * arraySlice(["a","b","c","d","e"], 5) => ["e"]
 */
arraySlice(arr, from := 1, to := arr.Length) {
	arr2 := []
	to := to > arr.Length ? arr.Length : to
	arr2.Capacity := to - from + 1
	Loop(to - from + 1)
		arr2.push(arr[from + A_Index - 1])
	return arr2
}

/**
 * Masks an array with the given function (by default IsSet()). Keeps the element if the mask function returns true, throws it out otherwise.
 * @param arr 
 * @param {(a) => Integer} maskFunc 
 * @param {Integer} keepEmpty 
 * @returns {Array} 
 */
arrayFunctionMask(arr, maskFunc := (a) => (IsSet(a)), keepEmpty := true) {
	arr2 := []
	if keepEmpty
		arr2.Length := arr.Length
	for i, e in arr {
		if (maskFunc(e)) {
			if keepEmpty 
				arr2[i] := e
			else
				arr2.push(e)
		}
	}
	return arr2
}

/**
 * Masks an array with the given mask array. If the element at index j in mask is truthy, index j in arr will be kept. By default, puts empty values into the array at falsy values.
 * @param arr 
 * @param mask 
 * @param {Integer} keepEmpty 
 * @returns {Array} 
 * @example arrayMask(
 * [5,7,2,4,5,7,1,0,0,1],
 * [0,1,1,1,0,0,0,1,0,1]
 * ) =>
 * [ ,7,2,4, , , ,0, , ]
 */
arrayMask(arr, mask, keepEmpty := true) {
	if arr.Length != mask.Length
		throw Error("Invalid mask given")
	arr2 := []
	if (keepEmpty)
		arr2.Length := arr.Length
	for i, e in mask {
		if (e) {
			if (keepEmpty)
				arr2[i] := arr[i]
			else
				arr2.push(arr[i])
		}
	}
	return arr2
}

arrayIgnoreIndex(arr, index) {
	arr2 := arr.Clone()
	arr2.RemoveAt(index)
	return arr2
}

arrayIgnoreIndices(arr, indices*) {
	arr2 := arr.Clone()
	for i, e in arraySort(indices, "N R")
		arr2.RemoveAt(e)
	return arr2
}

arrayReverse(arr) {
	arr2 := []
	for i, e in arr
		arr2.InsertAt(1, e)
	return arr2
}

/**
 * Enumerates an array backwards
 * @param arr 
 */
arrayInReverse(arr) {
	index := arr.Length
	if !index
		return (*) => false
	flagEnd := false
	return (&i, &e := -1) => (
		IsSet(e) ? i := arr[index] : (i := index, e := arr[index]),
		index > 1 ? (index--, 1) : (flagEnd ? 0 : flagEnd := 1)
	)
}

arraySort(arr, fn := (a => a), sortMode := "") {
	sortedArr := []
	indexMap := Map()
	counterMap := Map()
	if arr.Length == 0
		return sortedArr
	for i, e in arr {
		v := String(fn(e))
		if (indexMap.Has(v))
			indexMap[v].push(i)
		else {
			indexMap[v] := [i]
			counterMap[v] := 1
		}
		str .= v . "╦"
	}
	sortMode := RegExReplace(sortMode, "D.")
	valArr := StrSplit(Sort(SubStr(str, 1, -1), sortMode . " D╦"), "╦")
	for v in valArr
		sortedArr.push(arr[indexMap[v][counterMap[v]++]])
	return sortedArr
}

arrayBasicSort(arr, sortMode := "") => objBasicSort(arr, sortMode)
arraySortNumerically(arr, sortMode := "N") => objSortNumerically(arr, sortMode)

arrayContainsArray(arr, subArray, comparator := (arrVal,subArrVal) => (arrVal == subArrVal)) {
	if !subArray.length
		return 1
	firstEl := subArray[1]
	for i, e in arr {
		if comparator(firstEl, e) {
			seqStart := i - 1
			if arr.Length < seqStart + subArray.Length
				return false
			for j, k in subArray
				if !comparator(arr[seqStart + j], k)
					return false
			return seqStart + 1
		}
	}
	return false
}

/**
 * Sorts an object directly, returning the sorted Values. Note that this converts everything to strings.
 * @param obj Given object
 * @param {String} sortMode
 * @returns {Array} 
 */
objBasicSort(obj, sortMode := "") {
	if !objGetValueCount(obj)
		return []
	for e in objGetEnumerator(obj)
		str .= e . "╦"
	sortMode := RegExReplace(sortMode, "D.")
	newStr := Sort(SubStr(str, 1, -1), sortMode . " D╦")
	return StrSplit(newStr, "╦")
}
objSortNumerically(obj, sortMode := "N") => objDoForEach(objBasicSort(obj, sortMode), (e => Number(e)))


objSort(obj, fn := (a => a), sortMode := "", noKeys := true) {
	isArrLike := obj is Array || obj is Map
	sortedArr := []
	sortedArr.Capacity := objGetValueCount(obj)
	indexMap := Map()
	counterMap := Map()
	if objGetValueCount(obj) == 0
		return sortedArr
	for i, e in objGetEnumerator(obj) {
		v := String(fn(e))
		if (indexMap.Has(v))
			indexMap[v].push(i)
		else {
			indexMap[v] := [i]
			counterMap[v] := 1
		}
		str .= v . "╦"
	}
	sortMode := RegExReplace(sortMode, "D.")
	valArr := StrSplit(Sort(SubStr(str, 1, -1), sortMode . " D╦"), "╦")
	if noKeys {
		if isArrLike
			for v in valArr
				sortedArr.push(obj[indexMap[v][counterMap[v]++]])
		else
			for v in valArr
				sortedArr.push(obj.%indexMap[v][counterMap[v]++]%)
	} else if isArrLike {
		for v in valArr {
			key := indexMap[v][counterMap[v]++]
			sortedArr.push({ key: key, value: obj[key]})
		}
	} else {
		for v in valArr {
			key := indexMap[v][counterMap[v]++]
			sortedArr.push({ key: key, value: obj.%key% })
		}
	}
	return sortedArr
}


/**
 * Creates a map from two given arrays, the first one becoming the keys of the other
 * @param keyArray 
 * @param valueArray 
 * @returns {Map} 
 */
mapFromArrays(keyArray, valueArray) {
	if (!(keyArray is Array) || !(valueArray is Array))
		throw(TypeError("mapFromArrays expected Arrays, got " Type(keyArray) ", " Type(valueArray)))
	else if (keyArray.Length != valueArray.Length)
		throw(ValueError("mapFromArrays expected Arrays of equal Length, got Lengths " keyArray.Length ", " valueArray.Length))
	newMap := Map()
	for k, v in objZip(keyArray, valueArray)
		newMap[k] := v
	return newMap
}

/**
 * Given a Map, returns an Array of Length 2 containing two Arrays, the first one containing Keys and the second containing Values. Ordering WILL be random, as Maps are not ordered.
 * @param mapObject 
 * @returns {Array}
 */
mapToArrays(mapObject) {
	if !(mapObject is Map)
		throw(TypeError("Expected Map, got " Type(mapObject)))
	arr1 := []
	arr2 := []
	for i, e in mapObject {
		arr1.Push(i)
		arr2.Push(e)
	}
	return [arr1, arr2]
}
/**
 * Given a Map, returns new Map where keys are the values of original map and vice versa
 * @param {Map} mapObject 
 * @returns {Map} 
 */
mapFlip(mapObject) {
	flippedMap := Map()
	for i, e in mapObject
		flippedMap[e] := i
	return flippedMap
}

/**
 * Given a Map, returns an equivalent Object. If given Object/Array, tries to find all Maps recursively and turns them. Does NOT convert Objects/Arrays.
 * @param objInput 
 * @param {Integer} recursive 
 * @returns {Object | Map | Array} 
 */
MapToObj(obj, recursive := true) {
	flagIsArray := obj is Array
	flagIsMapArray := flagIsArray || obj is Map
	if (!(obj is Object))
		return obj
	objOutput := flagIsArray ? Array() : {}
	if (flagIsArray)
		objOutput.Length := obj.Length
	for i, e in objGetEnumerator(obj) {
		if (flagIsArray)
			objOutput[i] := (recursive ? MapToObj(e, true) : e)
		else
			objOutput.%i% := (recursive ? MapToObj(e, true) : e)
	}
	return (objOutput)
}

/**
 * Given an object with enumerable (Own) Properties, returns equivalent Map. If given Map/Array and recursive is true, finds Objects in it and turns those.
 * @param objInput 
 * @param {Integer} recursive 
 * @returns {Object | Map | Array} 
 */
objToMap(obj, recursive := true) {
	if (!IsObject(obj))
		return obj
	flagisArr := obj is Array
	clone := flagisArr ? [] : Map()
	if (flagisArr)
		clone.Capacity := obj.Length, clone.Length := obj.Length
	for i, e in objGetEnumerator(obj)
		clone[i] := (recursive ? objToMap(e, true) : e)
	return clone
}

objToArrays(obj) => mapToArrays(objToMap(obj, false))
objFromArrays(keyArray, valueArray) => MapToObj(mapFromArrays(keyArray, valueArray), false)