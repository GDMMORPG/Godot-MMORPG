package storage

import (
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var (
	DB *gorm.DB
)

func InitDB(dsn string) {
	var driver gorm.Dialector
	if dsn[:11] == "postgres://" {
		driver = postgres.Open(dsn)
	} else {
		// Error and exit if no supported database is found
		log.Fatalf("unsupported or missing DATABASE_DSN: %s", dsn)
	}

	// Open the database connection with the selected driver
	var err error
	DB, err = gorm.Open(driver, &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to open db: %v", err)
	}
	//! Auto-migration is terrible for production use cases.
	// if err := db.AutoMigrate(&User{}); err != nil {
	// 	log.Fatalf("migrate: %v", err)
	// }
}
