package routes_index

import "net/http"

func IndexHandler(w http.ResponseWriter, _ *http.Request) {
	w.Write([]byte(`<a href="/login">Login with Discord</a>`))
}
