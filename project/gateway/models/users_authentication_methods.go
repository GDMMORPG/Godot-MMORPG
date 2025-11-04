package models

import (
	"time"
)

type AuthenticationMethodDiscord struct {
	ID            uint   `gorm:"primaryKey"`
	UserID        uint   `gorm:"uniqueIndex;not null"`
	DiscordID     string `gorm:"uniqueIndex;size:50;not null"`
	Username      string `gorm:"size:100;not null"`
	Discriminator string `gorm:"size:10;not null"`
	Email         string `gorm:"size:100;not null"`
	AvatarURL     string `gorm:"size:255"`
	CreatedAt     time.Time
}
