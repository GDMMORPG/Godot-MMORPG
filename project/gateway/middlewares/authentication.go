package middlewares

import (
	"context"
	"fmt"
	"gateway/storage"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Define a custom type for context keys to avoid collisions
type ContextKey string

const SessionIDKey ContextKey = "sessionID"

// ---------- JWT Handling ----------
func parseJWT(tokenString string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) {
		// verify signing method
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return storage.JwtSecret, nil
	})
	if err != nil || !token.Valid {
		return nil, fmt.Errorf("invalid token: %w", err)
	}
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, fmt.Errorf("invalid claims")
	}

	// Verify expiration
	if exp, ok := claims["exp"].(float64); ok {
		if time.Now().Unix() > int64(exp) {
			return nil, fmt.Errorf("token expired")
		}
	} else {
		return nil, fmt.Errorf("invalid exp claim")
	}

	return claims, nil
}

// ---------- Middleware & protected handler ----------
func AuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Extract token from cookie or Authorization header
		var tokenString string

		// Try cookie first
		if c, err := r.Cookie("session"); err == nil {
			tokenString = c.Value
		} else {
			// Try Authorization header
			auth := r.Header.Get("Authorization")
			if auth != "" && len(auth) > 7 && auth[:7] == "Bearer " {
				tokenString = auth[7:]
			}
		}

		if tokenString == "" {
			http.Error(w, "unauthenticated", http.StatusUnauthorized)
			return
		}

		// parse and validate JWT
		claims, err := parseJWT(tokenString)
		if err != nil {
			http.Error(w, "invalid session: "+err.Error(), http.StatusUnauthorized)
			return
		}

		// get session ID from claims
		sessionID, ok := claims["sid"].(string)
		if !ok {
			http.Error(w, "invalid sid claim", http.StatusUnauthorized)
			return
		}

		// Attach user id to context
		ctx := context.WithValue(r.Context(), SessionIDKey, sessionID)
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}
