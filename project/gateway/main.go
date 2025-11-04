// main.go
package main

import (
	"gateway/middlewares"
	routes_index "gateway/routes"
	routes_auth "gateway/routes/auth"
	routes_client "gateway/routes/client"
	"gateway/storage"
	"log"
	"net/http"

	"github.com/joho/godotenv"
)

func main() {
	// Load .env file first
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️  No .env file found, falling back to system environment variables")
	}

	// Initialize configuration
	storage.InitializeConfiguration()

	// Initialize DB
	storage.InitDB(storage.DSN)

	// Initialize Cache
	storage.InitCache(storage.CacheDSN)

	http.HandleFunc("/", routes_index.IndexHandler)
	http.HandleFunc("/login", routes_auth.LoginHandler)
	http.HandleFunc("/auth/discord/callback", routes_auth.AuthCallbackHandler)
	http.HandleFunc("/me", middlewares.AuthMiddleware(routes_client.MeHandler))
	http.HandleFunc("/client/realmlist", middlewares.AuthMiddleware(routes_client.RealmListHandler))
	http.HandleFunc("/client/characterslist", middlewares.AuthMiddleware(routes_client.CharacterListHandler))

	addr := ":8080"
	log.Printf("listening on http://localhost%s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
