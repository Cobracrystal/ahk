#Include "%A_LineFile%\..\OVERLAPPED.ahk"
#Include "%A_LineFile%\..\ctypes.ahk"
#Include "%A_LineFile%\..\jsongo.ahk"

class HttpServer {
	static Prototype._id := 0
	static KnownHeaders := ['Cache-Control', 'Connection', 'Date', 'Keep-Alive', 'Pragma', 'Trailer', 'Transfer-Encoding', 'Upgrade', 'Via', 'Warning', 'Allow', 'Content-Length', 'Content-Type', 'Content-Encoding', 'Content-Language', 'Content-Location', 'Content-MD5', 'Content-Range', 'Expires', 'Last-Modified', 'Accept', 'Accept-Charset', 'Accept-Encoding', 'Accept-Language', 'Authorization', 'Cookie', 'Expect', 'From', 'Host', 'If-Match', 'If-Modified-Since', 'If-None-Match', 'If-Range', 'If-Unmodified-Since', 'Max-Forwards', 'Proxy-Authorization', 'Referer', 'Range', 'TE', 'Translate', 'User-Agent']
	static StatusCodeReasons := Map(
		100, 'Continue', 101, 'Switching Protocols',
		200, 'OK', 201, 'Created', 202, 'Accepted', 203, 'Non-Authoritative Information', 204, 'No Content', 205, 'Reset Content', 206, 'Partial Content',
		300, 'Multiple Choices', 301, 'Moved Permanently', 302, 'Found', 303, 'See Other', 304, 'Not Modified', 305, 'Use Proxy', 306, '(Unused)', 307, 'Temporary Redirect',
		400, 'Bad Request', 401, 'Unauthorized', 402, 'Payment Required', 403, 'Forbidden', 404, 'Not Found', 405, 'Method Not Allowed', 406, 'Not Acceptable', 407, 'Proxy Authentication Required', 408, 'Request Timeout', 409, 'Conflict', 410, 'Gone', 411, 'Length Required', 412, 'Precondition Failed', 413, 'Request Entity Too Large', 414, 'Request-URI Too Long', 415, 'Unsupported Media Type', 416, 'Requested Range Not Satisfiable', 417, 'Expectation Failed',
		500, 'Internal Server Error', 501, 'Not Implemented', 502, 'Bad Gateway', 503, 'Service Unavailable', 504, 'Gateway Timeout', 505, 'HTTP Version Not Supported'
	)

	__New() {
		#DllLoad httpapi.dll
		static chunk_size := 64 * 1024
		if err := DllCall('httpapi\HttpInitialize', 'uint', 2, 'uint', 1, 'ptr', 0, 'uint') ||
			DllCall('httpapi\HttpCreateServerSession', 'uint', 2, 'int64*', &sessionId := 0, 'uint', 0, 'uint')
			Throw OSError(err)
		this._urlGroup := HttpServer.UrlGroup(
			this._id := sessionId,
			this._requestQueue := HttpServer.RequestQueue(),
			30
		)
		this._overlappeds := Map()
		OVERLAPPED.EnableIoCompletionCallback(rq := this._requestQueue)
		ol := OVERLAPPED(read_header)
		ol._requestQueue := this._requestQueue.Ptr, ol._root := ObjPtr(this._overlappeds)
		err := DllCall('httpapi\HttpReceiveHttpRequest', 'ptr', rq, 'int64', 0, 'uint', 0,
			'ptr', ol._request := HTTP_REQUEST(), 'uint', HTTP_REQUEST.size,
			'ptr', 0, 'ptr', ol, 'uint')
		if err != 997
			Throw OSError(err)
		this._overlappeds[ol] := 1
		static read_header(ol, err, bytes) {
			if err {
				hr := ol._request
				if err = 0x80000005 && hr.Size < bytes {
					id := hr.RequestId, buf := Buffer(bytes, 0), hr := ol._request := HTTP_REQUEST.from_ptr(buf.Ptr, , buf)
					err := DllCall('httpapi\HttpReceiveHttpRequest', 'ptr', ol._requestQueue, 'int64', id, 'uint', 0, 'ptr', buf, 'uint', bytes, 'ptr', 0, 'ptr', ol, 'uint')
					if !err || err = 997
						return
				}
				Throw OSError(err)
			}
			try {
				ol._requestId := ol._request.RequestId
				(ol._chunk := Buffer(chunk_size))._used := 0
				(ol.Call := read_body)(ol, 0, 0)
			}
			finally {
				t := ol, ol := OVERLAPPED(read_header), ol._requestQueue := t._requestQueue, ol._root := t._root
				err := DllCall('httpapi\HttpReceiveHttpRequest', 'ptr', ol._requestQueue, 'int64', 0, 'uint', 0, 'ptr', ol._request := HTTP_REQUEST(), 'uint', HTTP_REQUEST.size, 'ptr', 0, 'ptr', ol, 'uint')
				if err != 997
					Throw OSError(err)
				ObjFromPtrAddRef(t._root)[ol] := 1
			}
		}
		static read_body(ol, err, bytes) {
			chunk := ol._chunk
			if !err {
				if chunk.Size = used := chunk._used += bytes
					chunk.Size <<= 1
				err := DllCall('httpapi\HttpReceiveRequestEntityBody', 'ptr', ol._requestQueue, 'int64', ol._requestId,
					'uint', 1, 'ptr', chunk.Ptr + used, 'uint', chunk.Size - used, 'ptr', 0, 'ptr', ol, 'uint')
				if !err || err = 997
					return
			}
			ObjFromPtrAddRef(ol._root).Delete(ol)
			if err != 38
				throw OSError(err)
			ol.Call := (ol, *) => ObjFromPtrAddRef(ol._root).Delete(ol)
			chunk.Size := chunk.DeleteProp('_used')
			hr := ol.DeleteProp('_request')
			hr.Body := ol.DeleteProp('_chunk')
			(rsp := Map()).CaseSense := 0
			rsp.Call := reply.Bind(ol, hr.Headers)
			(ObjFromPtrAddRef(hr.UrlContext))(hr, rsp)
		}
		static reply(ol, hr_headers, headers, body := '', code := 200, reason?) {
			static CT := 'Content-Type'
			headers.Call := (*) => 0
			ol._hsp := hsp := HTTP_RESPONSE()
			hsp.Version := 65537, hsp.StatusCode := code
			if reason ?? reason := HttpServer.StatusCodeReasons.Get(code, '')
				hsp.Reason := reason, hsp.ReasonLength := StrPut(reason, 'cp0') - 1
			charset := 'utf-8'
			if body !== '' {
				hsp.EntityChunkCount := 1
				hsp.pEntityChunks := data := HTTP_DATA_CHUNK()
				if body is HttpServer.File {
					headers.Get(CT, 0) || headers[CT] := HttpServer.FindMime(body.path ||
						(buf := Buffer(256), buf.Size := body.file.RawRead(buf), buf))
					NumPut('int64', 1, 'int64', 0, 'int64', -1, 'ptr', body.handle, data.ptr())
				}
				else {
					if HasProp(body, 'Ptr') {
						headers.Get(CT, 0) || headers[CT] := HttpServer.FindMime(body) || 'unknown/unknown'
					}
					else {
						if IsObject(body)
							body := jsongo.Stringify(body), ctv := 'application/json'
						else ctv := 'text/html'
						ctv := headers.Get(CT, 0) || headers[CT] := ctv
						if !InStr(ctv, 'charset=')
							headers[CT] := ctv ';charset=utf-8'
						StrPut(body, buf := Buffer(StrPut(body, charset) - 1), charset)
						body := buf
					}
					data.pBuffer := body.Ptr
					data.BufferLength := body.Size
				}
				data._cache := body
			}
			if headers.Count {
				static known_header_index := init_h2i()
				sz := n := 0, hh := hsp.Headers
				for k, v in headers {
					if v == ''
						continue
					sz += StrPut(v, 'cp0')
					if (i := known_header_index.Get(k, 30)) > 29
						sz += StrPut(k, 'cp0'), n++
				}
				hsp._hb := buf := Buffer(sz + n * HTTP_UNKNOWN_HEADER.size, 0)
				if hh.UnknownHeaderCount := n
					hh.pUnknownHeaders := buf.Ptr, huh := hh.pUnknownHeaders
				hhk := hh.KnownHeaders, pstr := buf.Ptr + n * HTTP_UNKNOWN_HEADER.size, n := 0
				for k, v in headers {
					if v == ''
						continue
					if (i := known_header_index.Get(k, 30)) > 29
						h := huh[n++], pstr += 1 + h.NameLength := StrPut(k, h.Name := pstr, 'cp0') - 1
					else h := hhk[i]
					pstr += 1 + h.RawValueLength := StrPut(v, h.RawValue := pstr, 'cp0') - 1
				}
			}
			(root := ObjFromPtrAddRef(ol._root))[ol] := 1
			err := DllCall('httpapi\HttpSendHttpResponse', 'ptr', ol._requestQueue, 'int64', ol._requestId,
				'uint', 0, 'ptr', hsp, 'ptr', 0, 'ptr', 0, 'ptr', 0, 'uint', 0, 'ptr', ol, 'ptr', 0)
			if !err || err == 997
				return
			root.Delete(ol)
		}
		static init_h2i() {
			m := Map(), m.CaseSense := 0
			h := HttpServer.KnownHeaders
			loop 20
				m[h[A_Index]] := A_Index - 1
			for k in ['Accept-Ranges', 'Age', 'Etag', 'Location', 'Proxy-Authenticate', 'Retry-After', 'Server', 'Set-Cookie', 'Vary', 'Www-Authenticate']
				m[k] := 19 + A_Index
			return m
		}
	}
	__Delete() {
		if !this._id
			return
		this._requestQueue := this._urlGroup := 0
		DllCall('httpapi\HttpCloseServerSession', 'int64', this.DeleteProp('_id'))
		DllCall('httpapi\HttpTerminate', 'uint', 1, 'ptr', 0)
	}

	/**
	 * Adds the specified URL's handler.
	 * @param {String} url Url string that contains a properly formed
	 * {@link https://learn.microsoft.com/en-us/windows/desktop/Http/urlprefix-strings UrlPrefix String}
	 * that identifies the URL to be registered.
	 * If you are not running as an administrator, specify a port number greater than 1024,
	 * otherwise you may get an ERROR_ACCESS_DENIED error.
	 * @param {(req: HTTP_REQUEST, rsp: Response)=>void} handler Handler of http request
	 * @typedef {Map} Response
	 * @property {(body?:String|Buffer|Object, code?:Integer, reason?:String)=>void} Response.Call
	 */
	Add(url, handler) => this._urlGroup.Add(url, handler)
	; Removes the specified URL's handler or all handlers.
	Remove(url?) => this._urlGroup.Remove(url?)
	; Detect mime of file or data
	static FindMime(PathOrData) {
		pPath := pBuf := size := 0
		if IsObject(PathOrData)
			pBuf := PathOrData, size := PathOrData.Size
		else if (pPath := StrPtr(PathOrData), !size := (pBuf := FileRead(PathOrData, 'raw m256')).Size)
			pBuf := 0
		loop 2
			hr := DllCall('urlmon\FindMimeFromData', 'ptr', 0, 'ptr', pPath, 'ptr', pBuf, 'uint', size, 'ptr', 0, 'uint', 0x20, 'ptr*', &pmime := 0, 'uint', 0)
		until !pBuf || !pPath || (pBuf := size := 0)
		if hr
			return
		mime := StrGet(pmime), DllCall('ole32\CoTaskMemFree', 'ptr', pmime)
		return mime
	}

	class File {
		__New(path?, handle?) {
			if IsSet(handle)
				this.file := FileOpen(this.handle := handle, 'h'), this.path := path ?? ''
			else this.handle := (this.file := FileOpen(this.path := path, 'r')).Handle
		}
	}

	;@region internal classes
	class RequestQueue {
		static Prototype.Ptr := 0
		__New() {
			if r := DllCall('httpapi\HttpCreateRequestQueue', 'uint', 2, 'ptr', 0, 'ptr', 0, 'uint', 0, 'ptr*', this, 'uint')
				Throw OSError(r)
		}
		__Delete() {
			if !this.Ptr
				return
			DllCall('httpapi\HttpShutdownRequestQueue', 'ptr', this)
			DllCall('httpapi\HttpCloseRequestQueue', 'ptr', this)
			this.Ptr := 0
		}
	}

	class UrlGroup {
		static Prototype._id := 0
		__New(sessionId, requestQueue, timeout) {
			if r := DllCall('httpapi\HttpCreateUrlGroup', 'int64', sessionId, 'int64*', &urlGroupId := 0, 'uint', 0, 'uint')
				Throw OSError(r)
			; HttpServerBindingProperty
			NumPut('ptr', 1, 'ptr', requestQueue.Ptr, info := Buffer(sz := 2 * A_PtrSize))
			if r := DllCall('httpapi\HttpSetUrlGroupProperty', 'int64', this._id := urlGroupId, 'int', 7, 'ptr', info, 'uint', sz, 'uint')
				Throw OSError(r)
			; HttpServerTimeoutsProperty
			NumPut('uint', 1,
				'ushort', timeout,  ; EntityBody
				'ushort', timeout,  ; DrainEntityBody
				'ushort', timeout,  ; RequestQueue
				'ushort', timeout,  ; IdleConnection
				'ushort', timeout,  ; HeaderWait
				info := Buffer(sz := 20, 0))
			if r := DllCall('httpapi\HttpSetUrlGroupProperty', 'int64', urlGroupId, 'int', 3, 'ptr', info, 'uint', sz, 'uint')
				Throw OSError(r)
			this._handlers := Map()
		}
		__Delete() {
			if this._id
				DllCall('httpapi\HttpCloseUrlGroup', 'int64', this.DeleteProp('_id'))
		}
		Add(url, handler) {
			if r := DllCall('httpapi\HttpAddUrlToUrlGroup', 'int64', this._id, 'wstr', url, 'int64', ObjPtr(handler), 'uint', 0, 'uint')
				Throw OSError(r, , r == 5 ? 'Listening on this URL may require administrator privileges!' : url)
			this._handlers[url] := handler
		}
		Remove(url?) {
			if !IsSet(url)
				DllCall('httpapi\HttpRemoveUrlFromUrlGroup', 'int64', this._id, 'ptr', 0, 'uint', 1), this._handlers.Clear()
			else if r := DllCall('httpapi\HttpRemoveUrlFromUrlGroup', 'int64', this._id, 'wstr', url, 'uint', 0, 'uint')
				Throw OSError(r)
			else this._handlers.Delete(url)
		}
	}
	;@endregion
}

;@region http structs
;@lint-disable class-non-dynamic-member-check
class HTTP_KNOWN_HEADER extends ctypes.struct {
	static fields := [
		['ushort', 'RawValueLength'], ['LPSTR', 'RawValue']
	]
}

class HTTP_UNKNOWN_HEADER extends ctypes.struct {
	static fields := [
		['ushort', 'NameLength'], ['ushort', 'RawValueLength'],
		['LPSTR', 'Name'], ['LPSTR', 'RawValue']
	]
}

class HTTP_REQUEST_HEADERS extends ctypes.struct {
	static fields := [
		['ushort', 'UnknownHeaderCount'], [ctypes.ptr(HTTP_UNKNOWN_HEADER), 'pUnknownHeaders'],
		['ushort', 'TrailerCount'], ['ptr', 'pTrailers'],
		[HTTP_KNOWN_HEADER, 'KnownHeaders[41]']
	]
}

class HTTP_COOKED_URL extends ctypes.struct {
	static fields := [
		['ushort', 'FullUrlLength'], ['ushort', 'HostLength'],
		['ushort', 'AbsPathLength'], ['ushort', 'QueryStringLength'],
		['LPWSTR', 'FullUrl'], ['LPWSTR', 'Host'],
		['LPWSTR', 'AbsPath'], ['LPWSTR', 'QueryString'],
	]
}

class HTTP_REQUEST_INFO extends ctypes.struct {
	static fields := [['int', 'InfoType'], ['uint', 'InfoLength'], ['ptr', 'pInfo']]
}

class PSOCKADDR extends ctypes.struct {
	static fields := [['ptr']]
	static from_ptr(ptr, *) {
		if !ptr
			return ''
		ptr := NumGet(ptr, 'ptr')
		addr := NumGet(ptr, 16 + 2 * A_PtrSize, 'ptr')
		addrlen := NumGet(ptr, 16, 'uptr')
		DllCall('ws2_32\WSAAddressToStringW', 'ptr', ptr, 'uint', 28, 'ptr', 0, 'ptr', b := Buffer(s := 2048), 'uint*', &s)
		return StrGet(b)
	}
}

class HTTP_REQUEST extends ctypes.struct {
	static fields := [
		['uint', 'Flags'],
		['int64', 'ConnectionId'],
		['int64', 'RequestId'],
		['int64', 'UrlContext'],
		['uint', 'Version'],
		['int', '_Verb'],
		['ushort', 'UnknownVerbLength'],
		['ushort', 'RawUrlLength'],
		['ptr', 'pUnknownVerb'],
		['LPSTR', 'RawUrl'],
		[HTTP_COOKED_URL, 'CookedUrl'],
		[PSOCKADDR, 'RemoteAddress'],
		[PSOCKADDR, 'LocalAddress'],
		[HTTP_REQUEST_HEADERS, '_Headers'],
		['int64', 'BytesReceived'],
		['ushort', 'EntityChunkCount'],
		['ptr', 'pEntityChunks'],
		['int64', 'RawConnectionId'],
		['ptr', 'pSslInfo'],
		['ushort', 'RequestInfoCount'],
		[HTTP_REQUEST_INFO, '*pRequestInfo']
	]
	Verb {
		get {
			static verbs := ['Unparsed', '', 'Invalid', 'OPTIONS', 'GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE', 'CONNECT', 'TRACK', 'MOVE', 'COPY', 'PROPFIND', 'PROPPATCH', 'MKCOL', 'LOCK', 'UNLOCK', 'SEARCH']
			return verbs[this._Verb + 1] || StrGet(this.pUnknownVerb, this.UnknownVerbLength, 'cp0')
		}
	}
	Headers {
		get {
			(headers := Map()).CaseSense := 0
			_headers := this._Headers
			loop _headers.UnknownHeaderCount
				it := _headers.pUnknownHeaders[A_Index - 1], headers[it.Name] := it.RawValue
			for h in _headers.KnownHeaders
				if h.RawValueLength
					headers[HttpServer.KnownHeaders[A_Index]] := h.RawValue
			return headers
		}
	}
}

class HTTP_RESPONSE_HEADERS extends ctypes.struct {
	static fields := [
		['ushort', 'UnknownHeaderCount'],
		[ctypes.ptr(HTTP_UNKNOWN_HEADER), 'pUnknownHeaders'],
		['ushort', 'TrailerCount'],
		[ctypes.ptr(HTTP_UNKNOWN_HEADER), 'pTrailers'],
		[HTTP_KNOWN_HEADER, 'KnownHeaders[30]']
	]
}

class HTTP_DATA_CHUNK extends ctypes.struct {
	static fields := [
		['int64', 'DataChunkType'],
		['ptr', 'pBuffer'],
		['uint', 'BufferLength'],
		['char', A_PtrSize = 8 ? '_[12]' : '_[20]']
	]
}

class HTTP_RESPONSE extends ctypes.struct {
	static fields := [
		['uint', 'Flags'],
		['uint', 'Version'],
		['ushort', 'StatusCode'],
		['ushort', 'ReasonLength'],
		['LPSTR', 'Reason'],
		[HTTP_RESPONSE_HEADERS, 'Headers'],
		['ushort', 'EntityChunkCount'],
		[ctypes.ptr(HTTP_DATA_CHUNK), 'pEntityChunks'],
		['ushort', 'ResponseInfoCount'],
		['ptr', 'pResponseInfo']
	]
}
;@endregion
