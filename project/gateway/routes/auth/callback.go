package routes_auth

import (
	"context"
	"encoding/json"
	"fmt"
	"gateway/models"
	"gateway/storage"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/oauth2"
	"gorm.io/gorm"
)

func AuthCallbackHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	// check state (omitted here — validate in production)
	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, "missing code", http.StatusBadRequest)
		return
	}

	// exchange code for token
	token, err := storage.OAuthConfig.Exchange(ctx, code)
	if err != nil {
		http.Error(w, "token exchange failed: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// fetch user info from Discord
	userData, err := fetchDiscordUser(ctx, token.AccessToken)
	if err != nil {
		http.Error(w, "failed fetching user: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// upsert user into DB
	user, err := upsertUser(userData, token)
	if err != nil {
		http.Error(w, "db error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// create JWT session (short-lived)
	jwtToken, err := createJWT(user.ID)
	if err != nil {
		http.Error(w, "jwt error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// set cookie (HttpOnly, Secure in prod)
	http.SetCookie(w, &http.Cookie{
		Name:     "session",
		Value:    jwtToken,
		Path:     "/",
		HttpOnly: true,
		Secure:   false, // <-- set to true in production with HTTPS
		SameSite: http.SameSiteLaxMode,
		MaxAge:   3600, // 1 hour
	})

	// redirect to localhost for in-game callbacks
	redirectURL := fmt.Sprintf("http://localhost:54320?jwt=%s&code=%s", jwtToken, code)
	http.Redirect(w, r, redirectURL, http.StatusSeeOther)
}

// ---------- Discord API fetch ----------
type discordUserResponse struct {
	ID            string `json:"id"`
	Username      string `json:"username"`
	Discriminator string `json:"discriminator"`
	Email         string `json:"email"`
	Avatar        string `json:"avatar"`
	Verified      bool   `json:"verified"`
}

func fetchDiscordUser(ctx context.Context, accessToken string) (*discordUserResponse, error) {
	req, _ := http.NewRequestWithContext(ctx, "GET", "https://discord.com/api/users/@me", nil)
	req.Header.Set("Authorization", "Bearer "+accessToken)

	client := http.DefaultClient
	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("discord returned status %d", res.StatusCode)
	}
	var u discordUserResponse
	if err := json.NewDecoder(res.Body).Decode(&u); err != nil {
		return nil, err
	}
	return &u, nil
}

// ---------- DB upsert ----------
func upsertUser(u *discordUserResponse, token *oauth2.Token) (*models.User, error) {
	var discordAuth models.AuthenticationMethodDiscord
	err := storage.DB.Where("discord_id = ?", u.ID).First(&discordAuth).Error
	if err != nil && err == gorm.ErrRecordNotFound {
		// Create new user and authentication method
		user := models.User{
			Displayname: u.Username,
		}
		if err := storage.DB.Create(&user).Error; err != nil {
			return nil, err
		}

		discordAuth = models.AuthenticationMethodDiscord{
			UserID:        user.ID,
			DiscordID:     u.ID,
			Username:      u.Username,
			Discriminator: u.Discriminator,
			Email:         u.Email,
			AvatarURL:     u.Avatar,
		}
		if err := storage.DB.Create(&discordAuth).Error; err != nil {
			return nil, err
		}

		return &user, nil
	} else {
		// Discord user exists in DB, handle updating info.
		discordAuth.Username = u.Username
		discordAuth.Discriminator = u.Discriminator
		discordAuth.Email = u.Email
		discordAuth.AvatarURL = u.Avatar
		if err := storage.DB.Save(&discordAuth).Error; err != nil {
			return nil, err
		}

		var user models.User
		if err := storage.DB.First(&user, discordAuth.UserID).Error; err != nil {
			// No Linked User found? Create a new one to unstuck this user.
			user = models.User{
				Displayname: u.Username,
			}
			if err := storage.DB.Create(&user).Error; err != nil {
				return nil, err
			}
			return &user, nil
		}
		return &user, nil
	}
}

// ---------- JWT helpers ----------
func createJWT(userID uint) (string, error) {
	const method = "discord"
	const methodID = 0

	// Check for existing session
	var session models.UserAuthenticatedSession
	err := storage.DB.Where("user_id = ? AND authentication_method = ?", userID, method).First(&session).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			session = models.UserAuthenticatedSession{
				ID:                     uuid.New(),
				UserID:                 userID,
				AuthenticationMethod:   method,
				AuthenticationMethodID: methodID,
				LastActiveAt:           time.Now(),
			}
			if err := storage.DB.Create(&session).Error; err != nil {
				return "", err
			}
		} else {
			return "", err
		}
	}

	// Update last active timestamp
	session.LastActiveAt = time.Now()
	if err := storage.DB.Save(&session).Error; err != nil {
		return "", err
	}

	// create JWT token
	claims := jwt.MapClaims{
		"sub": userID,
		"sid": session.ID.String(),
		"exp": time.Now().Add(1 * time.Hour).Unix(),
		"iat": time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(storage.JwtSecret)
}
