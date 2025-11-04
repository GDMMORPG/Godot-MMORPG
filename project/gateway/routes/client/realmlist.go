package routes_client

import (
	"encoding/json"
	"net/http"
)

func RealmListHandler(w http.ResponseWriter, r *http.Request) {
	// For demonstration, return a static realmlist
	realmlist := []map[string]interface{}{
		{
			"name":          "Example Realm 1",
			"location":      "North America / Los Angeles",
			"location-flag": "US",
			"type":          "PvP",
			"population":    "High",
			"address":       "127.0.0.1:4242",
		},
		{
			"name":          "Example Realm 2",
			"location":      "United Kingdom / London",
			"location-flag": "UK",
			"type":          "PvE",
			"population":    "Medium",
			"address":       "1.1.1.1:4242",
		},
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(realmlist)
}
