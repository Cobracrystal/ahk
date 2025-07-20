#Include "%A_LineFile%\..\..\LibrariesV2\PrimitiveUtilities.ahk"

/**
 * Counts how many times a given value is included in an Object
 * @param obj array or map
 * @param value value to check for
 * @returns {Integer} Count of how many instances of value were encountered
 */
objCountValue(obj, value, comparator := (itKey,itVal,setVal) => (itVal = setVal)) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objCountValue does not handle type " . Type(obj)))
	count := 0
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (comparator(i, e, value))
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
objContainsValue(obj, value, comparator := (itKey,itVal,setVal) => (itVal = setVal)) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objContainsValue does not handle type " . Type(obj)))
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (comparator(i, e, value))
			return i
	return 0
}

/**
 * Returns ObjOwnPropCount if obj is Object, else .Length or .Count for Array/Map
 * @param obj 
 * @returns {Integer} 
 */
objGetValueCount(obj) {
	return obj is Map ? obj.Count : (obj is Array ? obj.Length : ObjOwnPropCount(obj))
}

objGetRandomValue(obj) {
	isArrLike := (obj is Array || obj is Map)
	isArr := obj is Array
	if !(isArrLike || obj is Object)
		throw(TypeError("objContainsValue does not handle type " . Type(obj)))
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
	isArrLike := (obj is Array || obj is Map)
	if !(obj is Object)
		return obj
	copy := obj.Clone()
	for i, e in (isArrLike ? obj : obj.OwnProps())
		isArrLike ? copy[i] := objClone(e) : copy.%i% := objClone(e)
	return copy
}

/**
 * Deletes given Value from Object {limit} times. Returns count of removed values
 * @param {Array | Map} obj
 * @param value the value to remove
 * @param {Integer} limit if 0, removes all
 * @returns {Integer} count
 */
objRemoveValue(obj, value := "", limit := 0, comparator := ((itKey, itVal, val) => (itVal = val)), emptyValue?) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objRemoveValue does not handle type " . Type(obj)))
	queue := []
	count := 0
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (comparator(i, e, value)) {
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
 * Deletes given Value from Object, either on first encounter or on all encounters. Returns count of removed values
 * @param obj 
 * @param values 
 * @param {Integer} limit 
 * @param {(iterator, value) => Number} comparator 
 * @param emptyValue If this is set, all encountered values are not removed, but instead replaced by this value.
 * @returns {Integer} 
 */
objRemoveValues(obj, values, limit := 0, comparator := ((itKey,itVal,setVal) => (itVal = setVal)), emptyValue?) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objRemoveValues does not handle type " . Type(obj)))
	queue := []
	count := 0
	for i, e in (isArrLike ? obj : obj.OwnProps())
		for f in values
			if (comparator(i, e, f)) {
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

objDoForEach(obj, fn := ((e) => (objToString(e))), value := 0, conditional := ((itKey, itVal, setVal) => (true))) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objDoForEach does not handle type " . Type(obj)))
	clone := %Type(obj)%()
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (conditional(i, e, value))
			(isArrLike ? (isMap ? clone[i] := fn(e) : clone.push(fn(e))) : clone.%i% := fn(e))
	return clone
}

objGetMinimum(obj) => objCollect(obj, (a,b) => Min(a,b))
objGetMaximum(obj) => objCollect(obj, (a,b) => Max(a,b))
objGetAverage(obj) => objCollect(obj, (a,b) => (a+b)) / (obj is Array ? obj.Length : obj is Map ? obj.Count : ObjOwnPropCount(obj))

/**
 * 
 * @param obj 
 * @param {Func} fn function responsible for collecting objects. Equivalent to fn(fn(....fn(fn(base,obj[1]),obj[2])...,obj[n-1]),obj[n])
 * @param {Any} initialBase Initial value of the base on which fn operates. If not given, first element in object becomes base. Set this if fn operators onto properties or items of enumerable values.
 * @param {Any} value Optional Value to check conditional upon
 * @param {Func} conditional Optional Comparator to determine which values to include in collection.
 * @returns {Any} Collected Value
 */
objCollect(obj, fn := ((base, iterator) => (base . objToString(iterator))), initialBase?, value := 0, conditional := ((itKey, itVal, setVal) => (true))) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	if (IsSet(initialBase))
		base := initialBase
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (conditional(i, e, value))
			base := IsSet(base) ? fn(base, e) : e
	return base ?? ""
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
	if !(isArrLike || obj is Object)
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	duplicateMap := Map()
	counterMap := Map()
	duplicateIndices := []
	duplicateMap.CaseSense := caseSense
	for i, e in (isArrLike ? obj : obj.OwnProps()) {
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
		for i, e in (isArrLike ? obj : obj.OwnProps()) {
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
	if !(isArrLike || obj is Object)
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	duplicateMap := Map()
	duplicateMap.CaseSense := caseSense
	for i, e in (isArrLike ? obj : obj.OwnProps()) {
		v := fn(e)
		if (duplicateMap.Has(v))
			duplicateMap[v]++
		else
			duplicateMap[v] := 1
	}
	clone := %Type(obj)%()
	for i, e in (isArrLike ? obj : obj.OwnProps()) {
		v := fn(e)
		if (duplicateMap[v] == 1)
			isArrLike ? (isMap ? clone[i] := e : clone.push(e)) : clone.%i% := e
	}
	return clone
}

objGetUniques(obj, fn := (a => a), caseSense := true) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	uniques := Map()
	uniques.CaseSense := caseSense
	clone := %Type(obj)%
	for i, e in (isArrLike ? obj : obj.OwnProps()) {
		v := fn(e)
		if !(uniques.Has(v)) {
			uniques[v] := true
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

objZip(obj1, obj2, stopAtAnyEnd := true) {
	if (Type(obj1) != Type(obj2))
		throw(TypeError("obj1 and obj2 are not of equal type, instead " Type(obj1) ", " Type(obj2)))
	if (obj1 is Array || obj1 is Map)
		obj1Enum := obj1, obj2Enum := obj2
	else
		obj1Enum := obj1.OwnProps(), obj2Enum := obj2.OwnProps()
	index := 1
	try obj1Enum := obj1Enum.__Enum(2)
	try obj2Enum := obj2Enum.__Enum(2)
	return (&i, &j, &n := -1, &m := -1) => (
		flagN := !IsSet(n), ; if for-loop passes n to this function, then it is unset. otherwise it is set.
		flagM := !IsSet(m),
		flagN ? (flagM ? flag1 := obj1Enum(&i, &n)	: i := index++ )			 : flag1 := obj1Enum(&_, &i),
		flagN ? (flagM ? flag2 := obj2Enum(&j, &m)	: flag1 := obj1Enum(&_, &j)) : flag2 := obj2Enum(&_, &j),
		flagN ? (flagM ? 0 							: flag2 := obj2Enum(&_, &n)) : 0,
		stopAtAnyEnd ? flag1 && flag2 : flag1 || flag2
	)
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


/*
we have an object.
if it is a class instance object, we wish to get the properties that it got from the class
ie. msgbox is a func object and thus has the MinParams property, but this property does not appear in ObjOwnProps(Msgbox)

if it is enumerable, we directly enumerate it.

we enumerate ObjOwnProps() with one variable. This will get us ALL property names.
If a property name has a getter, call it.
Otherwise, print information about that property

if the object has a Base object, enumerate that.

Hierarchy:
class Map [extends Object extends Any]
base object chain then is: 
	class Map
		.__Class == "Class"
		.Prototype == Map.Prototype
			.__Class == "Map"
			.base == Object.Prototype -> thus, Map.Prototype.base == Map.base.Prototype
		.Base == class Object
			.__Class == "Class"
			.Prototype == Object.Prototype
				.__Class == "Object"
				.Base == Any.Prototype
			.Base == class Any
				.__Class == "Class"
				.Prototype == Any.Prototype
					.__Class == "Any"
					.Base == "" (literal empty string)
				.Base == Class.Prototype (The Prototype of class Class)
					.__Class == "Class"
					.Base == Object.Prototype
						.__Class == "Object"
						.Base == Any.Prototype
							.__Class == "Any"
							.Base == "" (literal empty string)
TLDR: 
the base of a class is the class object that it is extended from.
the base of class Any is class.Prototype and then we chain
The base of a class instance is class.Prototype
Now:
class Thing {
	property := 1
	static staticproperty := 2
	method() => 1
	static staticmethod => 2
}

The Instance contains only instance properties. Instance methods are inherited from Prototype. __Class is inherited from Prototype and contains the class name 
Method counts as Prop, not an OwnProp
The Prototype contains only instance methods and Properties (that exist in the class. Properties assigned via New/Init/Assignments in class Body are not included) 
. __Class is defined here and is the class name
Method counts as OwnProp
The class Object contains only static properties and static methods. __Class is inherited from class class and thus contains "Class"
static methods count as OwnProps
*/

; Aliases for shorthand options
objToStringNoBases(obj, detailedFunctions := false)	=>	objToString(obj, , false, , , , true, detailedFunctions, true, false)
objToStringFull(obj, detailedFunctions := false)	=>	objToString(obj, , false, , , , true, detailedFunctions, true, true)
objToStringClass(obj, detailedFunctions := false)	=>	objToString(obj, , false, , , , true, detailedFunctions, false, false)
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
objToString(obj, compact := false, compress := true, strEscape := false, anyAsObj := false, spacer := "`t", withInheritedProps?, detailedFunctions?, withClassOrPrototype?, withBases?) {
	if IsObject(obj) {
		origin := obj
		flagFirstIsInstance := (Type(obj) != "Prototype" && Type(obj) != "Class" && Type(objgetbase(obj)) == "Prototype") ; equivalent to line below
		; if obj is an instance of a class, and it isnt enumerable, and it doesn't have any own props, then try getting inheritables
		flagIncludeInheritedProps :=	withInheritedProps		?? (flagFirstIsInstance && !obj.HasMethod("__Enum") && ObjOwnPropCount(obj) == 0 ? 1 : 0)
		flagDetailedFunctions := 		detailedFunctions		?? !flagFirstIsInstance ; (flagFirstIsInstance && Type(obj) != "Func" ? 0 : 1)
		flagIncludeClassOrPrototype := 	withClassOrPrototype	?? !flagFirstIsInstance
		flagWithBases := 				withBases 				?? !flagFirstIsInstance
		strEscape := 					strEscape				?? (!flagFirstIsInstance || flagIncludeClassOrPrototype || flagWithBases)
		if (flagIncludeClassOrPrototype || flagIncludeInheritedProps)
			anyAsObj := true
	}
	return _objToString(obj, 0)

	_objToString(obj, indentLevel, flagOverrideStrEscape := false, flagIsOwnPropDescObject := false) {
		static escapes := [["\", "\\"], ['"', '\"'], ["`n", "\n"], ["`t", "\t"]]
		qt := strEscape || flagOverrideStrEscape ? '"' : ''
		if !(IsObject(obj)) { ; if obj is Primitive, no need for the entire rest.
			if (obj is Number)
				return String(obj)
			if (IsNumber(obj) || obj is String)
				return qt obj qt
			if (strEscape || flagOverrideStrEscape) {
				for e in escapes
					obj := StrReplace(obj, e[1], e[2])
				return qt String(obj) qt
			}
			return obj
		}
		; for very small objects, this may be expensive to do, but it would be very messy otherwise
		objType := Type(obj)
		flagIsMap := obj is Map
		flagIsArr := obj is Array
		flagIsObj := ((!flagIsArr && !flagIsMap) || objType == "Prototype" ? 1 : 0)
		flagIsInstance := (objType != "Prototype" && objType != "Class" && Type(ObjGetBase(obj)) == "Prototype") ; we could also check whether obj doesn't have the proprety Prototype, but that relies on the object not being Primitive/Any
		indent := (compress || compact)  ? '' : strMultiply(spacer, indentLevel + 1)
		trspace := compress ? "" : A_Space
		separator := (!compact && !compress ? '`n' indent : trspace)
		sep2 := (compact || compress) ? separator : '`n' SubStr(indent, 1, -1 * StrLen(spacer))
		count := objGetValueCount(obj)
		className := obj.__Class
		str := ""
		if (flagIsInstance) {
			if (obj.HasMethod("__Enum")) ; enumerate own properties
				for k, v in obj
					strFromCurrentEnums(k, v, true)
			; get OwnProps and inherited Properties (depending on the flag)
			; Ignores .Prototype and .__Class (Prototype later and .__Class is present multiple times)
			strFromAllProperties(flagIncludeInheritedProps ? -1 : 0)
			; now, add .__Class for the current object
			if (flagIncludeClassOrPrototype && !flagIsOwnPropDescObject)
				strFromCurrentEnums("__Class", className)
			flagIsBadFunction := (objType == "Func" && obj != origin) ; only do this if the original object was a function. otherwise we loop infinitely
			if (flagWithBases && !flagIsOwnPropDescObject && !flagIsBadFunction)
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
			flagIsGoodPrototype := (objType == "Prototype" && (className == "Class" || className == "Object"))
			if (flagWithBases) {
				if (objType != "Prototype" || (flagIsGoodPrototype))
					strFromCurrentEnums("Base", ObjGetBase(obj))
				else if className != "Any" ; we are a bad prototype and only get a String base. If we are Any.Prototype, we get no base at all. D:
					strFromCurrentEnums("Base", obj.base.__Class ".Prototype")
			}
		}
		return ( (flagIsObj || anyAsObj) ? "{" : (flagIsArr ? "[" : "Map(") ) (str == '' ? '' : separator) RegExReplace(str, "," separator "$") (str == '' ? '' : sep2) ( (flagIsObj || anyAsObj) ? "}" : (flagIsArr ? "]" : ")") )

		strFromCurrentEnums(k, v, overrStrEscape?, isOwnPropDescObject?) {
			if (!compact && compress)
				separator := isSimple(v) ? trspace : '`n'
			if !(IsSet(v))
				str .= RTrim(str, separator) "," separator
			else if (flagIsObj || anyAsObj )
				str .= _objToString(k ?? "", indentLevel + 1, true) (flagIsMap && !anyAsObj ? "," : ":") trspace _objToString(v ?? "", indentLevel + 1,, isOwnPropDescObject?) "," separator
			else
				str .= _objToString(v ?? "", indentLevel + 1, flagOverrideStrEscape?) "," separator
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

range(startEnd, end?, step?, inclusive := true) {
	start := IsSet(end) ? startEnd : 1
	end := end ?? startEnd
	step := step ?? 1
	index := 1
	return (&n, &m := -1) => (
		!IsSet(m) ? 
			(n := index++, m := start, start := numRoundProper(start + step), inclusive ? m <= end : m < end) : 
			(n := start, start := numRoundProper(start + step), inclusive ? n <= end : n < end)
	)
}

rangeA(startEnd, end?, step?, inclusive := true) {
	a := []
	for e in range(startEnd, end?, step?, inclusive)
		a.push(e)
	return a
}

arrayMerge(array1, array2) {
	arr2 := []
	arr2.push(array1*)
	arr2.push(array2*)
	return arr2
}

arraySlice(arr, from := 1, to := arr.Length) {
	arr2 := []
	to := to > arr.Length ? arr.Length : to
	Loop(to) {
		i := from + A_Index - 1
		arr2.push(arr[i])
	}
	return arr2
}

arrayFunctionMask(arr, maskFunc := (a) => (IsSet(a)), keepEmpty := true) {
	arr2 := []
	if keepEmpty
		arr2.Length := arr.Lenght
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

arraySort(arr, mode := "") {
	arr2 := []
	for i, e in arr
		str .= e . "`n"
	sortedStr := Sort(str, mode)
	Loop Parse, sortedStr, "`n" {
		if (A_LoopField == "")
			continue
		arr2.push(A_LoopField)
	}
	return arr2
}



/**
 * Given an enumerable object whos values itself are objects, sorts it by value of the inner objects key.
 * @param tObj Object, Array or Map to be used for sorting. tObj must contain Objects which itself have accessable values (that of key)
 * @param key key whos matching value will be used for sorting
 * @param {String} mode Sorting mode. equivalent to sorting options in Sort [String]
 * @returns {Array} The sorted array, where each entry in the array is an object with the original index as property .index and value as .value
 */
objSortByKey(tObj, key, mode := "") {
	isArr := tObj is Array
	isMap := tObj is Map
	if !(tObj is Object)
		throw(TypeError("Expected Object, but got " tObj.Prototype.Name))
	isObj := !(isArr || isMap)
	indexMap := Map()
	retArr := []
	l := isArr ? tObj.Length : isMap ? tObj.Count : ObjOwnPropCount(tObj)
	removeDuplicates := InStr(mode, "U")
	if !l
		return []
	for i, sortKey in (isObj ? tObj.OwnProps() : tObj) {
		if (!IsSet(innerIsObj))
			innerIsObj := !(sortKey is Map || sortKey is Array)
		tv := innerIsObj ? sortKey.%key% : sortKey[key]
		if (!IsSet(isString))
			isString := (tv is String)
		if (indexMap.Has(tv) && !removeDuplicates)
			indexMap[tv].push(i)
		else
			indexMap[tv] := [i]
		str .= tv . "`n"
	}
	newStr := Sort(IsSet(str) ? SubStr(str, 1, -1) : "", removeDuplicates ? mode : mode . ' U')
	strArr := StrSplit(newStr, "`n")
	for sortKey in strArr
		for index in indexMap[isString ? String(sortKey) : Number(sortKey)]
			retArr.push({ index: index, value: isObj ? tObj.%index% : tObj[index] })
	return retArr
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
	for i, e in keyArray
		newMap[e] := valueArray[i]
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
MapToObj(objInput, recursive := true) {
	flagIsArray := objInput is Array
	flagIsMapArray := flagIsArray || objInput is Map
	if (!(objInput is Object))
		return objInput
	objOutput := flagIsArray ? Array() : {}
	if (flagIsArray)
		objOutput.Length := objInput.Length
	for i, e in (flagIsMapArray ? objInput : objInput.OwnProps()) {
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
ObjToMap(objInput, recursive := true) {
	flagIsArray := objInput is Array
	flagIsMapArray := flagIsArray || objInput is Map
	flagIsObject := objInput is Object
	if (!flagIsObject)
		return objInput
	objOutput := flagIsArray ? Array() : Map()
	if (flagIsArray)
		objOutput.Length := objInput.Length
	for i, e in (flagIsMapArray ? objInput : objInput.OwnProps())
		objOutput[i] := (recursive ? ObjToMap(e, true) : e)
	return (objOutput)
}