package storage

import (
	"log"
	"os"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/endpoints"
)

// ---------- Config (from env) ----------
var (
	JwtSecret   []byte
	OAuthConfig *oauth2.Config
	DSN         string
	CacheDSN    string
)

func InitializeConfiguration() {

	// read config from env
	var (
		clientID        = os.Getenv("DISCORD_CLIENT_ID")
		clientSecret    = os.Getenv("DISCORD_CLIENT_SECRET")
		redirectURL     = os.Getenv("DISCORD_REDIRECT_URL") // e.g. https://yourdomain.com/auth/discord/callback
		jwtSecretString = os.Getenv("JWT_SECRET")           // must be set
		dsn             = os.Getenv("DATABASE_DSN")         // e.g. a Postgres DSN
		cacheDSN        = os.Getenv("CACHE_DSN")            // e.g. a Redis DSN
	)

	// basic env check
	if clientID == "" || clientSecret == "" || redirectURL == "" || jwtSecretString == "" {
		log.Fatal("DISCORD_CLIENT_ID, DISCORD_CLIENT_SECRET, DISCORD_REDIRECT_URL, and JWT_SECRET must be set")
	}

	DSN = dsn
	CacheDSN = cacheDSN

	JwtSecret = []byte(jwtSecretString)

	// OAuth2 config for Discord
	OAuthConfig = &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		Endpoint:     endpoints.Discord,
		RedirectURL:  redirectURL,
		Scopes:       []string{"identify", "email"},
	}
}
