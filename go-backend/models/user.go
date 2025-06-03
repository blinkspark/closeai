package models

import (
	"gorm.io/gorm"
)

type User struct {
	ID       uint   `gorm:"primaryKey" json:"id"`
	Username string `gorm:"uniqueIndex;size:32" json:"username"`
	Email    string `gorm:"uniqueIndex;size:64" json:"email"`
	Password string `json:"-"`
	CreatedAt int64 `json:"created_at"`
}

func MigrateUser(db *gorm.DB) error {
	return db.AutoMigrate(&User{})
}
