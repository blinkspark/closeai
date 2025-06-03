package config

import (
	"os"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func InitDB() (*gorm.DB, error) {
	pgURL := os.Getenv("POSTGRE_URL")
	if pgURL != "" {
		return gorm.Open(postgres.Open(pgURL), &gorm.Config{})
	}
	// 默认使用 SQLite
	return gorm.Open(sqlite.Open("data.db"), &gorm.Config{})
}
