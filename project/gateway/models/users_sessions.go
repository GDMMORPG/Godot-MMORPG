package models

import (
	"time"

	"github.com/google/uuid"
)

type UserAuthenticatedSession struct {
	ID                     uuid.UUID `gorm:"primaryKey"`
	UserID                 uint      `gorm:"not null"`
	AuthenticationMethod   string    `gorm:"size:50;not null"`
	AuthenticationMethodID uint      `gorm:"not null"`
	LastActiveAt           time.Time `gorm:"not null"`
	CreatedAt              time.Time `gorm:"not null"`
	ExpiresAt              time.Time `gorm:"not null"`
}
