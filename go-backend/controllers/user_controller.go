package controllers

import (
	"net/http"
	"time"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"closeai-backend/models"
	"closeai-backend/utils"
)

func Register(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Username string `json:"username"`
			Email    string `json:"email"`
			Password string `json:"password"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
			return
		}
		if len(req.Password) < 6 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "密码太短"})
			return
		}
		var count int64
		db.Model(&models.User{}).Where("username = ? OR email = ?", req.Username, req.Email).Count(&count)
		if count > 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "用户名或邮箱已存在"})
			return
		}
		hash, err := utils.HashPassword(req.Password)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "密码加密失败"})
			return
		}
		user := models.User{
			Username: req.Username,
			Email: req.Email,
			Password: hash,
			CreatedAt: time.Now().Unix(),
		}
		if err := db.Create(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "注册失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "注册成功"})
	}
}

func Login(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Username string `json:"username"`
			Password string `json:"password"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
			return
		}
		var user models.User
		db.Where("username = ? OR email = ?", req.Username, req.Username).First(&user)
		if user.ID == 0 {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "用户不存在"})
			return
		}
		if !utils.CheckPassword(user.Password, req.Password) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "密码错误"})
			return
		}
		token, err := utils.GenerateToken(user.ID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Token生成失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"token": token})
	}
}

func GetUserInfo(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		user, _ := c.Get("user")
		if u, ok := user.(models.User); ok {
			c.JSON(http.StatusOK, gin.H{"user": gin.H{
				"id": u.ID,
				"username": u.Username,
				"email": u.Email,
				"created_at": u.CreatedAt,
			}})
			return
		}
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
	}
}

func ChangePassword(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		userVal, _ := c.Get("user")
		user, ok := userVal.(models.User)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
			return
		}
		var req struct {
			OldPassword string `json:"old_password"`
			NewPassword string `json:"new_password"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
			return
		}
		if !utils.CheckPassword(user.Password, req.OldPassword) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "旧密码错误"})
			return
		}
		if len(req.NewPassword) < 6 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "新密码太短"})
			return
		}
		hash, err := utils.HashPassword(req.NewPassword)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "密码加密失败"})
			return
		}
		db.Model(&user).Update("password", hash)
		c.JSON(http.StatusOK, gin.H{"message": "修改成功"})
	}
}
