package routes_client

import (
	"encoding/json"
	"fmt"
	"gateway/middlewares"
	"gateway/models"
	"gateway/storage"
	"net/http"
)

func MeHandler(w http.ResponseWriter, r *http.Request) {
	sessionIDVal := r.Context().Value(middlewares.SessionIDKey)
	if sessionIDVal == nil {
		http.Error(w, "no user id", http.StatusUnauthorized)
		return
	}
	sessionID := sessionIDVal.(string)
	var session models.UserAuthenticatedSession
	if err := storage.DB.First(&session, sessionID).Error; err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	var user models.User
	if err := storage.DB.First(&user, session.UserID).Error; err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	authenticationMethods := []string{
		"discord",
	}

	var linkedMethods []map[string]string

	for _, method := range authenticationMethods {
		switch method {
		case "discord":
			var dbMethod models.AuthenticationMethodDiscord
			if err := storage.DB.Where("user_id = ?", user.ID).First(&dbMethod).Error; err == nil {
				linkedMethods = append(linkedMethods, map[string]string{
					"method":          "discord",
					"discord_id":      dbMethod.DiscordID,
					"username":        dbMethod.Username,
					"discriminator":   dbMethod.Discriminator,
					"email":           dbMethod.Email,
					"avatar_url_hash": dbMethod.AvatarURL,
					"avatar_url_png":  fmt.Sprintf("https://cdn.discordapp.com/avatars/%s/%s.png", dbMethod.DiscordID, dbMethod.AvatarURL),
				})
			}
		}
	}
	// return some JSON about the user
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"id":             user.ID,
		"displayname":    user.Displayname,
		"created_at":     user.CreatedAt,
		"linked_methods": linkedMethods,
	})
}
