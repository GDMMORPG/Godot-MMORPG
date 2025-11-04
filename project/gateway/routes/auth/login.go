package routes_auth

import (
	"crypto/rand"
	"fmt"
	"gateway/storage"
	"net/http"

	"golang.org/x/oauth2"
)

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	// state should be a random string in production and tied to a cookie or DB entry to prevent CSRF.
	state := generateSecureState()
	url := storage.OAuthConfig.AuthCodeURL(state, oauth2.AccessTypeOffline)
	http.Redirect(w, r, url, http.StatusFound)
}

func generateSecureState() string {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "fallback-state"
	}
	return fmt.Sprintf("%x", b)
}
