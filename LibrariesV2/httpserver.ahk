#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\WebSocket.ahk"

class HttpServer {

	class URI {

		encode(url) { ; keep ":/;?@,&=+$#."
			return this.LC_UriEncode(url, "[0-9a-zA-Z:/;?@,&=+$#.]")
		}

		decode(url) {
			return this.LC_UriDecode(url)
		}

		LC_UriEncode(uri, regx := "[0-9A-Za-z]") {
			str := Buffer(StrPut(uri, "UTF-8"), 0)
			StrPut(uri, &str, "UTF-8")
			while (code := NumGet(str, A_Index, "UChar")) {
				char := Chr(code)
				if (char ~= regx)
					res .= char
				else
					res .= Format("%{:02X}", code)
			}
			return res
		}

		LC_UriDecode(uri) {
			pos := 1
			while(pos := RegExMatch(uri, "i)(%[\da-f]{2})+", &code, pos)) {
				str := Buffer(StrLen(code) // 3, 0)
				code := SubStr(code, 2)
				Loop parse code, "`%"
					NumPut("0x" A_LoopField, str, A_Index - 1, "UChar")
				decoded := StrGet(&str, "UTF-8")
				uri := SubStr(uri, 1, pos - 1) . decoded . SubStr(uri, pos + StrLen(code) + 1)
				pos += StrLen(decoded) + 1
			}
			return uri
		}
	}
}