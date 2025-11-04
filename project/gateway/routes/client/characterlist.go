package routes_client

import (
	"encoding/json"
	"net/http"
)

func CharacterListHandler(w http.ResponseWriter, r *http.Request) {
	// For demonstration, return a static character list
	characters := []map[string]interface{}{
		{
			"name":       "HeroOne",
			"level":      60,
			"class":      "Warrior",
			"race":       "Human",
			"realm":      "Example Realm 1",
			"last_login": "2024-01-01T12:00:00Z",
		},
		{
			"name":       "MageTwo",
			"level":      58,
			"class":      "Mage",
			"race":       "Elf",
			"realm":      "Example Realm 2",
			"last_login": "2024-01-02T15:30:00Z",
		},
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(characters)
}
