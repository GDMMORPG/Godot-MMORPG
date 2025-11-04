package models

import (
	"time"
)

type User struct {
	ID          uint   `gorm:"primaryKey"`
	Displayname string `gorm:"uniqueIndex;size:100;not null"`
	CreatedAt   time.Time
}
